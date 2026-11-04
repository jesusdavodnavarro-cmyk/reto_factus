// Atrapa cualquier error lanzado en la app

import type { ErrorRequestHandler } from "express";
import { env } from '../config/env';

export const errorHandler: ErrorRequestHandler = (err, _req, res, _next) => {
    const status = typeof err?.status === 'number' ? err.status : 500;
    const isDev = env.NODE_ENV === 'development';

    console.error(err);

    res.status(status).json({
        error: status === 500 ? 'Error interno del servidor' : err.message,
        // Detalles técnicos solo en desarrollo
        ...(isDev && status === 500 && { detail: err?.message }),
        // Lo que respondió Factus (p. ej. errores de validación DIAN), solo en desarrollo
        ...(isDev && err?.details !== undefined && { factus: err.details }),
    });
};
