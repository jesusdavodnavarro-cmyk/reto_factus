// Qué datos aceptamos en "Quiero mi proyecto solar" y con qué reglas.
// Los datos de facturación ya vienen con la forma que exige Factus (Hito 3),
// para no tener que volver a pedírselos al cliente.

import { z } from 'zod';

const soloDigitos = z.string().trim().regex(/^\d+$/, 'Solo números, sin puntos, espacios ni guiones');

// Tipos de documento -> código DIAN que pide Factus (customer.identification_document_code)
export const CODIGO_DOCUMENTO_DIAN = {
    CC: '13',        // cédula de ciudadanía
    CE: '22',        // cédula de extranjería
    PASAPORTE: '41',
    NIT: '31',
} as const;

// Campos comunes a persona natural y jurídica
const facturacionBase = {
    numeroDocumento: soloDigitos.min(5).max(15),
    direccion: z.string().trim().min(5).max(150),
    email: z.email(),          // a este correo llega la factura electrónica
    telefono: soloDigitos.min(7).max(10),
    // Código DANE del municipio (customer.municipality_code). Montería = 23001
    municipioCodigo: z.string().regex(/^\d{5}$/, 'Código DANE de 5 dígitos').default('23001'),
};

// Si tipoPersona es "natural" pide nombres; si es "juridica" pide razón social y NIT.
// (Factus: legal_organization_code "2" exige names y "1" exige company)
const facturacionSchema = z.discriminatedUnion('tipoPersona', [
    z.object({
        tipoPersona: z.literal('natural'),
        tipoDocumento: z.enum(['CC', 'CE', 'PASAPORTE']),
        nombres: z.string().trim().min(3).max(120),
        ...facturacionBase,
    }),
    z.object({
        tipoPersona: z.literal('juridica'),
        tipoDocumento: z.literal('NIT'),
        razonSocial: z.string().trim().min(3).max(150),
        dv: z.string().regex(/^\d$/, 'Un solo dígito').optional(), // si no llega, Factus lo calcula
        ...facturacionBase,
    }),
]);

export const crearSolicitudSchema = z.object({
    // El cliente puede decir su consumo en kWh o en pesos de su factura de luz
    consumo: z.object({
        valor: z.number().positive().max(10_000_000),
        unidad: z.enum(['kWh', 'COP']),
    }),
    presupuestoCop: z.number().int().nonnegative().max(10_000_000_000),
    areaDisponibleM2: z.number().positive().max(100_000),
    contacto: z.object({
        nombre: z.string().trim().min(3).max(120),
        email: z.email(),
        telefono: soloDigitos.min(7).max(10),
    }),
    facturacion: facturacionSchema,
});

// El tipo TypeScript sale del esquema: una sola fuente de verdad
export type CrearSolicitudInput = z.infer<typeof crearSolicitudSchema>;
