// Proyectos y su plan de cuotas.
// Cada cuota tiene una REFERENCIA única (PRY-001-C01) que se usará IGUAL en
// Factus (reference_code) y en Factus Pay: esa es la asociación automática
// entre el dinero recaudado y su factura que pide el reto.

import { createJsonStore } from '../../lib/jsonStore';
import { HttpError } from '../../lib/httpError';
import { hoyColombia, sumarMeses } from '../../lib/fechas';
import { marcarEnProyecto, obtenerSolicitud } from '../solicitudes/solicitud.service';
import type { CrearProyectoInput } from './proyecto.schema';
import { estimarValorTotalCop, potenciaNecesariaKwp } from './estimacion';

// Flujo B: pendiente -> facturada -> cobrando -> pagada   (facturada -> anulada con nota crédito)
export type EstadoCuota = 'pendiente' | 'facturada' | 'cobrando' | 'pagada' | 'anulada';

export type Cuota = {
    id: string;            // PRY-001-C01 (para mostrar)
    // Referencia ÚNICA que va IGUAL a Factus (reference_code) y a Factus Pay.
    // Lleva un sufijo para no chocar con facturas del sandbox si se borra backend/data.
    referencia: string;    // ej. PRY-001-C01-K7Q2X
    proyectoId: string;
    numero: number;        // 1, 2, 3...
    montoCop: number;      // pesos enteros
    vence: string;         // YYYY-MM-DD
    estado: EstadoCuota;
    factura: { number: string; cufe: string; publicUrl?: string; qrDian?: string; validadaEn?: string } | null;
    recaudo: { reference: string; status: string; qr?: string; brebKey?: string; qrExpiraEn?: string } | null;
    pago: { pagadoEn: string; montoCop: number; origen: 'webhook' | 'consulta'; pagador?: unknown } | null;
    historial: { fecha: string; evento: string; detalle?: string }[]; // trazabilidad
};

export type Proyecto = {
    id: string;            // PRY-001
    solicitudId: string;
    cliente: string;       // nombre o razón social, para mostrar en el panel
    potenciaKwp: number;   // tamaño del sistema según el consumo
    valorTotalCop: number;
    subsidioPct: number;
    subsidioCop: number;
    financiadoCop: number; // lo que el cliente paga en cuotas
    creadoEn: string;
    cuotas: Cuota[];
};

const store = createJsonStore<Proyecto>('proyectos');

export function crearProyecto(input: CrearProyectoInput): Proyecto {
    const solicitud = obtenerSolicitud(input.solicitudId); // 404 si no existe

    // Idempotencia: una solicitud genera UN solo proyecto
    if (solicitud.estado !== 'recibida') {
        throw new HttpError(409, `La solicitud ${solicitud.id} ya tiene proyecto`);
    }

    const potenciaKwp = potenciaNecesariaKwp(solicitud.consumoKwhMes);
    const valorTotalCop = input.valorTotalCop ?? estimarValorTotalCop(potenciaKwp);

    const subsidioCop = Math.round((valorTotalCop * input.subsidioPct) / 100);
    const financiadoCop = valorTotalCop - subsidioCop;
    if (financiadoCop <= 0) throw new HttpError(400, 'No queda valor por financiar');

    const id = `PRY-${String(store.count() + 1).padStart(3, '0')}`;
    const sufijo = Date.now().toString(36).toUpperCase().slice(-5); // único por proyecto
    const primera = input.primeraCuotaVence ?? hoyColombia();
    const montos = repartir(financiadoCop, input.numeroCuotas);
    const creadoEn = new Date().toISOString();

    const proyecto: Proyecto = {
        id,
        solicitudId: solicitud.id,
        cliente: solicitud.facturacion.tipoPersona === 'natural'
            ? solicitud.facturacion.nombres
            : solicitud.facturacion.razonSocial,
        potenciaKwp,
        valorTotalCop,
        subsidioPct: input.subsidioPct,
        subsidioCop,
        financiadoCop,
        creadoEn,
        cuotas: montos.map((montoCop, i) => {
            const cuotaId = `${id}-C${String(i + 1).padStart(2, '0')}`;
            return {
                id: cuotaId,
                referencia: `${cuotaId}-${sufijo}`,
                proyectoId: id,
                numero: i + 1,
                montoCop,
                vence: sumarMeses(primera, i), // una cuota por mes
                estado: 'pendiente' as const,
                factura: null,
                recaudo: null,
                pago: null,
                historial: [{ fecha: creadoEn, evento: 'creada' }],
            };
        }),
    };

    store.insert(proyecto);
    marcarEnProyecto(solicitud.id);
    return proyecto;
}

export function listarProyectos(): Proyecto[] {
    return store.all().sort((a, b) => b.creadoEn.localeCompare(a.creadoEn));
}

export function obtenerProyecto(id: string): Proyecto {
    const proyecto = store.get(id);
    if (!proyecto) throw new HttpError(404, `Proyecto ${id} no encontrado`);
    return proyecto;
}

// Busca una cuota por su id (PRY-001-C01). La usará el Hito 3 para facturar.
export function obtenerCuota(cuotaId: string): { proyecto: Proyecto; cuota: Cuota } {
    const proyectoId = cuotaId.split('-C')[0];
    const proyecto = obtenerProyecto(proyectoId);
    const cuota = proyecto.cuotas.find((c) => c.id === cuotaId);
    if (!cuota) throw new HttpError(404, `Cuota ${cuotaId} no encontrada`);
    return { proyecto, cuota };
}

// Busca la cuota por la referencia que viaja en Factus / Factus Pay (conciliación)
export function buscarCuotaPorReferencia(referencia: string): { proyecto: Proyecto; cuota: Cuota } | null {
    for (const proyecto of store.all()) {
        const cuota = proyecto.cuotas.find((c) => c.referencia === referencia);
        if (cuota) return { proyecto, cuota };
    }
    return null;
}

// Guarda cambios de una cuota (estado, factura, recaudo) y anota el evento en su historial
export function actualizarCuota(
    cuotaId: string,
    cambios: Partial<Omit<Cuota, 'id' | 'proyectoId' | 'referencia' | 'historial'>>,
    evento?: { evento: string; detalle?: string },
): Cuota {
    const { proyecto, cuota } = obtenerCuota(cuotaId);
    const historial = evento
        ? [...(cuota.historial ?? []), { fecha: new Date().toISOString(), ...evento }]
        : cuota.historial ?? [];
    const actualizada = { ...cuota, ...cambios, historial };
    store.update({ ...proyecto, cuotas: proyecto.cuotas.map((c) => (c.id === cuotaId ? actualizada : c)) });
    return actualizada;
}

// Totales para el panel del contratista (Hito 5). Se CALCULAN, no se guardan:
// así nunca quedan desactualizados.
export function resumenProyecto(proyecto: Proyecto) {
    const hoy = hoyColombia();
    const vigentes = proyecto.cuotas.filter((c) => c.estado !== 'anulada');
    const suma = (cuotas: Cuota[]) => cuotas.reduce((t, c) => t + c.montoCop, 0);

    const pagadas = vigentes.filter((c) => c.estado === 'pagada');
    const sinPagar = vigentes.filter((c) => c.estado !== 'pagada');

    return {
        facturadoCop: suma(vigentes.filter((c) => c.factura)),
        recaudadoCop: suma(pagadas),
        pendienteCop: suma(sinPagar),
        enMoraCop: suma(sinPagar.filter((c) => c.vence < hoy)), // vencida y sin pagar
        cuotasPagadas: pagadas.length,
        cuotasTotales: vigentes.length,
    };
}

// Reparte en pesos enteros; la última cuota absorbe la diferencia del redondeo.
// Ej: 1.000.000 en 3 -> 333.333, 333.333, 333.334 (suma exacta)
function repartir(total: number, n: number): number[] {
    const base = Math.floor(total / n);
    return Array.from({ length: n }, (_, i) => (i === n - 1 ? total - base * (n - 1) : base));
}
