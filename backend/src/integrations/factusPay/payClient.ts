// Cliente de Factus Pay (recaudo). Es OTRA API, distinta a la de facturación:
// - Login: POST /auth { email, password } -> { token }   (sin /v1)
// - El token NO vence por tiempo, pero CADA login revoca el anterior.
//   Por eso lo pedimos una sola vez y lo reutilizamos (y solo un backend debe usar
//   estas credenciales a la vez, o se revocan el token entre sí).
// Docs: https://pay-developers.factus.com.co/

import { env } from '../../config/env';
import { FactusError, fetchFactus, readBody } from '../factus/factusError';

const TIMEOUT_MS = 20_000;

let token: string | null = null;
let inFlight: Promise<string> | null = null;

async function getPayToken(): Promise<string> {
    if (token) return token;
    if (!inFlight) inFlight = login().finally(() => (inFlight = null));
    return inFlight;
}

async function login(): Promise<string> {
    const res = await fetchFactus(`${env.FACTUS_PAY_BASE_URL}/auth`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
        body: JSON.stringify({ email: env.FACTUS_PAY_EMAIL, password: env.FACTUS_PAY_PASSWORD }),
        signal: AbortSignal.timeout(TIMEOUT_MS),
    });
    const body = await readBody(res);
    if (!res.ok) throw new FactusError(`Auth Factus Pay falló: ${res.status}`, res.status, body);

    const nuevo = (body as { token?: string })?.token;
    if (!nuevo) throw new FactusError('Factus Pay no devolvió token', res.status, body);
    token = nuevo;
    return nuevo;
}

type PayResponse<T> = { status: string; message: string; data: T };

// Igual que factusRequest: Bearer, timeout y un reintento si el token fue revocado (401)
async function payRequest<T>(method: 'GET' | 'POST', path: string, body?: unknown): Promise<{ httpStatus: number; payload: PayResponse<T> }> {
    const send = async () =>
        fetchFactus(`${env.FACTUS_PAY_BASE_URL}${path}`, {
            method,
            headers: {
                Authorization: `Bearer ${await getPayToken()}`,
                Accept: 'application/json',
                ...(body !== undefined && { 'Content-Type': 'application/json' }),
            },
            body: body === undefined ? undefined : JSON.stringify(body),
            signal: AbortSignal.timeout(TIMEOUT_MS),
        });

    let res = await send();
    if (res.status === 401) {
        token = null; // otro login lo revocó: pedimos uno nuevo
        res = await send();
    }

    const payload = await readBody(res);
    if (!res.ok) throw new FactusError(`Factus Pay respondió ${res.status} en ${method} ${path}`, res.status, payload);
    return { httpStatus: res.status, payload: payload as PayResponse<T> };
}

// Lo que devuelve Factus Pay de un recaudo
export type Recaudo = {
    reference_code: string;
    amount: number | string;
    status: string;           // 'ready' (listo para pagar) | 'paid' (pagado)
    breb_key?: string;        // llave Bre-B, ej. @FCWHUYLIV2MWUEUESTONH
    created_at?: string;
    qr_expires_at?: string;
    collected_at?: string | null;
    qr?: string;              // data:image/png;base64,...
};

// POST /v1/collections. Si la referencia ya existe, Factus Pay devuelve el MISMO
// recaudo (200) en vez de crear otro: es idempotente por reference_code.
export async function crearRecaudo(referencia: string, montoCop: number): Promise<Recaudo> {
    const { payload } = await payRequest<Recaudo>('POST', '/v1/collections', {
        reference_code: referencia,
        amount: montoCop,                        // pesos (mín. 1.000, máx. 12.100.000)
        expiration: env.RECAUDO_EXPIRACION_SEG,  // segundos
    });
    return payload.data;
}

// GET /v1/collections/:referenceCode -> estado actual (respaldo del webhook)
export async function consultarRecaudo(referencia: string): Promise<Recaudo> {
    const { payload } = await payRequest<Recaudo>('GET', `/v1/collections/${encodeURIComponent(referencia)}`);
    return payload.data;
}

// Para /api/factus/status: ¿las credenciales de Factus Pay funcionan?
export async function verificarPay(): Promise<void> {
    await getPayToken();
}
