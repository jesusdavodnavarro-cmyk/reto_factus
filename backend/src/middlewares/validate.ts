// Middleware reutilizable: valida req.body con un esquema zod ANTES de llegar a la ruta.
// - Si falla: 400 con la lista de campos inválidos (la PWA los muestra junto a cada input).
// - Si pasa: req.body queda reemplazado por los datos ya limpios (trim, defaults, etc.).

import type { RequestHandler } from 'express';
import { z } from 'zod';

// Mensajes de error de zod en español
z.config(z.locales.es());

export function validateBody(schema: z.ZodType): RequestHandler {
    return (req, res, next) => {
        const result = schema.safeParse(req.body);

        if (!result.success) {
            res.status(400).json({
                error: 'Datos inválidos',
                campos: result.error.issues.map((issue) => ({
                    campo: issue.path.join('.'), // ej. "facturacion.numeroDocumento"
                    mensaje: issue.message,
                })),
            });
            return;
        }

        req.body = result.data;
        next();
    };
}
