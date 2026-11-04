// Lógica de negocio de solicitudes. No sabe nada de HTTP (ni req ni res):
// así se puede reutilizar y probar sola.

import { env } from '../../config/env';
import { createJsonStore } from '../../lib/jsonStore';
import { HttpError } from '../../lib/httpError';
import type { CrearSolicitudInput } from './solicitud.schema';

export type Solicitud = Omit<CrearSolicitudInput, 'consumo'> & {
    id: string;              // SOL-001, SOL-002...
    estado: 'recibida';      // luego: cotizada, aprobada... (Hito 2)
    creadaEn: string;        // ISO 8601
    consumoKwhMes: number;   // SIEMPRE en kWh, ya normalizado
    consumoOriginal: CrearSolicitudInput['consumo']; // lo que escribió el cliente
    tarifaKwhUsada: number | null; // trazabilidad: con qué tarifa se convirtió (null si llegó en kWh)
};

const store = createJsonStore<Solicitud>('solicitudes');

export function crearSolicitud(input: CrearSolicitudInput): Solicitud {
    const { consumo, ...resto } = input;
    const enPesos = consumo.unidad === 'COP';

    const solicitud: Solicitud = {
        id: `SOL-${String(store.count() + 1).padStart(3, '0')}`,
        estado: 'recibida',
        creadaEn: new Date().toISOString(),
        consumoKwhMes: enPesos ? pesosAKwh(consumo.valor) : redondear(consumo.valor),
        consumoOriginal: consumo,
        tarifaKwhUsada: enPesos ? env.AFINIA_TARIFA_KWH : null,
        ...resto,
    };

    return store.insert(solicitud);
}

export function listarSolicitudes(): Solicitud[] {
    // Las más recientes primero
    return store.all().sort((a, b) => b.creadaEn.localeCompare(a.creadaEn));
}

export function obtenerSolicitud(id: string): Solicitud {
    const solicitud = store.get(id);
    if (!solicitud) throw new HttpError(404, `Solicitud ${id} no encontrada`);
    return solicitud;
}

// $ de la factura de luz / tarifa ($/kWh) = kWh consumidos
function pesosAKwh(pesos: number): number {
    return redondear(pesos / env.AFINIA_TARIFA_KWH);
}

function redondear(n: number): number {
    return Math.round(n * 100) / 100;
}
