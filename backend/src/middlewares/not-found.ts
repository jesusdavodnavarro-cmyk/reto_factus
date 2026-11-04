// No se atendió la ruta

import type { Request, Response } from "express";

export function notFound(req: Request, res: Response) {
    res.status(404).json({
        error: `Ruta no encontrada: ${req.method} ${req.originalUrl}`,
    });
}
