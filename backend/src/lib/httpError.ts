// Error con código HTTP. errorHandler lee err.status y responde con ese código.
// Uso: throw new HttpError(404, 'Solicitud no encontrada');

export class HttpError extends Error {
    status: number;
    details?: unknown;

    constructor(status: number, message: string, details?: unknown) {
        super(message);
        this.name = 'HttpError';
        this.status = status;
        this.details = details;
    }
}
