// Arma el JSON de la factura electrónica (POST /v2/bills/validate) de UNA cuota.
// Une 3 módulos: cliente (solicitud), proyecto y cuota. No llama a Factus: solo construye.
// Reglas de Factus: números como texto con 2 decimales, price sin IVA,
// payment_details.amount = total, reference_code único.

import { env } from '../../config/env';
import { hoyColombia } from '../../lib/fechas';
import { CODIGO_DOCUMENTO_DIAN } from '../solicitudes/solicitud.schema';
import type { Solicitud } from '../solicitudes/solicitud.service';
import type { Cuota, Proyecto } from '../proyectos/proyecto.service';

const dinero = (n: number) => n.toFixed(2); // 648200 -> "648200.00"

export function construirFactura(proyecto: Proyecto, cuota: Cuota, solicitud: Solicitud) {
    const f = solicitud.facturacion;
    const monto = dinero(cuota.montoCop);
    const totalCuotas = proyecto.cuotas.length;

    // Factura a crédito: vence el día de la cuota (nunca antes de hoy)
    const hoy = hoyColombia();
    const dueDate = cuota.vence < hoy ? hoy : cuota.vence;

    return {
        reference_code: cuota.referencia, // MISMA referencia que el recaudo en Factus Pay
        document: '01',                   // factura electrónica de venta
        operation_type: '10',             // estándar
        ...(env.FACTUS_NUMBERING_RANGE_ID && { numbering_range_id: env.FACTUS_NUMBERING_RANGE_ID }),
        send_email: true,                 // Factus le envía la factura al cliente
        observation: `Cuota ${cuota.numero} de ${totalCuotas} - Proyecto solar ${proyecto.id}. Ref. ${cuota.referencia}`.slice(0, 250),
        payment_details: [
            {
                payment_form: '2',          // crédito: se emite antes de que pague
                payment_method_code: '47',  // transferencia (Bre-B por Factus Pay)
                reference_code: cuota.referencia,
                amount: monto,
                due_date: dueDate,
            },
        ],
        cash_rounding_amount: '0.00',     // sin IVA no hay diferencias de redondeo
        customer: {
            identification_document_code: CODIGO_DOCUMENTO_DIAN[f.tipoDocumento],
            identification: f.numeroDocumento,
            ...(f.tipoPersona === 'juridica' && f.dv ? { dv: f.dv } : {}),
            // "1" = persona jurídica (exige company), "2" = persona natural (exige names)
            legal_organization_code: f.tipoPersona === 'juridica' ? '1' : '2',
            ...(f.tipoPersona === 'juridica' ? { company: f.razonSocial } : { names: f.nombres }),
            tribute_code: 'ZZ',
            address: f.direccion,
            email: f.email,
            phone: f.telefono,
            country_code: 'CO',
            municipality_code: f.municipioCodigo,
        },
        items: [
            {
                code_reference: 'CUOTA-SOLAR',
                name: `Cuota ${cuota.numero}/${totalCuotas} sistema solar fotovoltaico ${proyecto.potenciaKwp} kWp`,
                quantity: '1.00',
                discount_rate: '0.00',
                price: monto,
                unit_measure_code: '94', // unidad
                standard_code: '999',    // estándar de adopción del contribuyente
                // Equipos de energía solar: excluidos de IVA (Ley 1715 de 2014)
                taxes: [{ is_excluded: true }],
            },
        ],
    };
}
