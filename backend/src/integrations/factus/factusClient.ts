import { env } from '../../config/env';
import { getToken, invalidateToken } from './tokenManager';
import { FactusError, fetchFactus, readBody } from './factusError';

type HttpMethod = 'GET' | 'POST' | 'PATCH' | 'DELETE';

// Factus responde; lo útil viene en data.
export type FactusResponse<T> = {
    status: string;
    message: string;
    data: T;
};

// Se re-exporta para que el resto de la app lo siga importando desde aquí.
export { FactusError };

const TIMEOUT_MS = 30_000; // validación ante la DIAN, puede tardar unos segundos

// ÚNICA función pública. Ejemplo de uso:
//   const { data } = await factusRequest<unknown>('GET', '/v2/numbering-ranges');
export async function factusRequest<T>(
    method: HttpMethod,
    path: string,
    body?: unknown,
): Promise<FactusResponse<T>> {
    let res = await send(method, path, body);

    if (res.status === 401) {
        invalidateToken();
        res = await send(method, path, body);
    }

    const payload = await readBody(res);

    if (!res.ok) {
        throw new FactusError(`Factus respondió ${res.status} en ${method} ${path}`, res.status, payload);
    }

    return payload as FactusResponse<T>;
}

// Arma y envía la petición. Siempre pide el token justo antes de enviar.
async function send(method: HttpMethod, path: string, body?: unknown): Promise<Response> {
    const token = await getToken();

    return fetchFactus(`${env.FACTUS_BASE_URL}${path}`, {
        method,
        headers: {
            Authorization: `Bearer ${token}`,
            Accept: 'application/json',
            // Solo agrega Content-Type si de verdad hay un body que enviar:
            ...(body !== undefined && { 'Content-Type': 'application/json' }),
        },
        body: body === undefined ? undefined : JSON.stringify(body),
        signal: AbortSignal.timeout(TIMEOUT_MS), // corta la espera si Factus no responde
    });
}
