// Error propio para cualquier falla al hablar con Factus (auth o API).
// status = 502 -> "el proveedor externo falló", lo lee errorHandler.
// Vive en su propio archivo para que tokenManager y factusClient lo usen
// sin importarse entre sí (evita dependencias circulares).

export class FactusError extends Error {
    status = 502;
    factusStatus: number;   // el código real que devolvió Factus (401, 422, ...)
    details: unknown;       // el cuerpo de la respuesta, para depurar

    constructor(message: string, factusStatus: number, details: unknown) {
        super(message);
        this.name = 'FactusError';
        this.factusStatus = factusStatus;
        this.details = details;
    }
}

// Lee la respuesta sin romperse si viene vacía o no es JSON (por ejemplo, una página de error HTML).
export async function readBody(res: Response): Promise<unknown> {
    const text = await res.text();
    if (!text) return null;
    try {
        return JSON.parse(text);
    } catch {
        return text;
    }
}
