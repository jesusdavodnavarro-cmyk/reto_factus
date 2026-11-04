// Flujo B de cada cuota:  factura (Factus) -> recaudo (Factus Pay) -> pago -> conciliación.
// La REFERENCIA de la cuota es la misma en los dos sistemas: así el dinero que entra
// se asocia solo con su factura, sin conciliar a mano.

import { factusRequest } from '../../integrations/factus/factusClient';
import { consultarRecaudo, crearRecaudo, type Recaudo } from '../../integrations/factusPay/payClient';
import { HttpError } from '../../lib/httpError';
import { obtenerSolicitud } from '../solicitudes/solicitud.service';
import { actualizarCuota, buscarCuotaPorReferencia, obtenerCuota, type Cuota } from '../proyectos/proyecto.service';
import { construirFactura } from './factura.builder';

type FacturaFactus = {
    number: string;
    cufe: string;
    is_validated: boolean;
    validated_at?: string;
    errors?: unknown;
    links?: { qr?: string; public_url?: string };
};

// 1. FACTURAR: emite y valida la factura ante la DIAN (idempotente)
export async function facturarCuota(cuotaId: string): Promise<Cuota> {
    const { proyecto, cuota } = obtenerCuota(cuotaId);

    if (cuota.factura) return cuota; // ya facturada: no se emite otra
    if (cuota.estado === 'anulada') throw new HttpError(409, `La cuota ${cuota.id} está anulada`);

    const solicitud = obtenerSolicitud(proyecto.solicitudId);
    const body = construirFactura(proyecto, cuota, solicitud);

    const { data } = await factusRequest<FacturaFactus>('POST', '/v2/bills/validate', body);

    if (!data?.is_validated) {
        throw new HttpError(502, 'Factus recibió la factura pero la DIAN no la validó', data?.errors);
    }

    return actualizarCuota(
        cuota.id,
        {
            estado: 'facturada',
            factura: {
                number: data.number,
                cufe: data.cufe,
                publicUrl: data.links?.public_url,
                qrDian: data.links?.qr,
                validadaEn: data.validated_at,
            },
        },
        { evento: 'facturada', detalle: `Factura ${data.number} validada por la DIAN` },
    );
}

// 2. COBRAR: crea el recaudo en Factus Pay con la MISMA referencia (devuelve QR y llave Bre-B)
export async function cobrarCuota(cuotaId: string): Promise<Cuota> {
    const { cuota } = obtenerCuota(cuotaId);

    if (cuota.estado === 'pagada') return cuota;
    if (!cuota.factura) throw new HttpError(409, `Primero hay que facturar la cuota ${cuota.id}`);

    const recaudo = await crearRecaudo(cuota.referencia, cuota.montoCop);

    // Si Factus Pay dice que ya estaba pagado (referencia existente), conciliamos de una
    if (recaudo.status === 'paid') return conciliar(cuota, recaudo, 'consulta');

    return actualizarCuota(
        cuota.id,
        {
            estado: 'cobrando',
            recaudo: {
                reference: recaudo.reference_code,
                status: recaudo.status,
                qr: recaudo.qr,
                brebKey: recaudo.breb_key,
                qrExpiraEn: recaudo.qr_expires_at,
            },
        },
        // Solo anotamos el evento la primera vez (repetir "Pagar" devuelve el mismo recaudo)
        cuota.estado === 'cobrando'
            ? undefined
            : { evento: 'cobrando', detalle: `Recaudo ${recaudo.status} - llave ${recaudo.breb_key ?? 'N/D'}` },
    );
}

// 1 + 2 en un solo paso: lo que hace el botón "Pagar" de la app
export async function iniciarPago(cuotaId: string): Promise<Cuota> {
    await facturarCuota(cuotaId);
    return cobrarCuota(cuotaId);
}

// 3. VERIFICAR: consulta el estado en Factus Pay (respaldo si el webhook no llega)
export async function verificarPago(cuotaId: string, origen: 'webhook' | 'consulta' = 'consulta'): Promise<Cuota> {
    const { cuota } = obtenerCuota(cuotaId);
    if (cuota.estado === 'pagada') return cuota;
    if (!cuota.recaudo) throw new HttpError(409, `La cuota ${cuota.id} aún no tiene recaudo`);

    const recaudo = await consultarRecaudo(cuota.referencia);
    if (recaudo.status === 'paid') return conciliar(cuota, recaudo, origen);

    return actualizarCuota(cuota.id, { recaudo: { ...cuota.recaudo, status: recaudo.status } });
}

// 4. WEBHOOK: Factus Pay avisa que una referencia se pagó.
// Por recomendación de Factus Pay, NO confiamos solo en el aviso: confirmamos con la API.
export async function procesarAvisoDePago(referencia: string): Promise<{ conciliada: boolean; cuotaId?: string }> {
    const encontrada = buscarCuotaPorReferencia(referencia);
    if (!encontrada) return { conciliada: false }; // no es nuestra: se ignora

    const cuota = await verificarPago(encontrada.cuota.id, 'webhook');
    return { conciliada: cuota.estado === 'pagada', cuotaId: cuota.id };
}

// CONCILIACIÓN: asocia el dinero recaudado con su cuota y su factura.
// Idempotente: si llega dos veces el mismo pago, no pasa nada.
function conciliar(cuota: Cuota, recaudo: Recaudo, origen: 'webhook' | 'consulta'): Cuota {
    if (cuota.estado === 'pagada') return cuota;

    const montoRecaudado = Number(recaudo.amount);
    if (Math.abs(montoRecaudado - cuota.montoCop) >= 1) {
        // El dinero no cuadra con la factura: no se marca como pagada
        actualizarCuota(cuota.id, {}, {
            evento: 'alerta',
            detalle: `Monto recaudado ${montoRecaudado} no coincide con la cuota ${cuota.montoCop}`,
        });
        throw new HttpError(409, `El monto recaudado no coincide con la cuota ${cuota.id}`);
    }

    return actualizarCuota(
        cuota.id,
        {
            estado: 'pagada',
            recaudo: cuota.recaudo ? { ...cuota.recaudo, status: 'paid' } : null,
            pago: {
                pagadoEn: recaudo.collected_at ?? new Date().toISOString(),
                montoCop: montoRecaudado,
                origen,
            },
        },
        {
            evento: 'pagada',
            detalle: `Conciliada con factura ${cuota.factura?.number ?? 'N/D'} (${origen})`,
        },
    );
}
