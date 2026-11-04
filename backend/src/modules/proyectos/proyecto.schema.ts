// Lo que el contratista envía para convertir una solicitud en proyecto con plan de cuotas.
// (Puente temporal: en el Hito 2 el valor saldrá de la cotización calculada por el backend.)

import { z } from 'zod';

export const crearProyectoSchema = z.object({
    solicitudId: z.string().regex(/^SOL-\d{3,}$/, 'Formato SOL-001'),
    // Opcional: si no llega, el backend lo estima con el consumo (estimacion.ts)
    valorTotalCop: z.number().int().positive().max(10_000_000_000).optional(),
    // Colombia Solar (Res. 40159 de 2026) subsidia hasta el 60 % a pequeños negocios
    subsidioPct: z.number().min(0).max(60).default(60),
    numeroCuotas: z.number().int().min(1).max(36),
    primeraCuotaVence: z.iso.date().optional(), // YYYY-MM-DD; si no llega, hoy
});

export type CrearProyectoInput = z.infer<typeof crearProyectoSchema>;
