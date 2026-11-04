// Gestor del token de Factus:
// - lo guarda en memoria y lo reutiliza mientras esté vigente,
// - lo renueva 1 minuto antes de que venza (primero con refresh token; si falla, con login),
// - evita pedir dos tokens al mismo tiempo.

import { env } from '../../config/env';
import { FactusError, fetchFactus, readBody } from './factusError';

type TokenResponse = {
    access_token: string;
    refresh_token: string;
    expires_in: number; // segundos
};

const TOKEN_URL = `${env.FACTUS_BASE_URL}/oauth/token`;
const MARGEN_MS = 60_000; // renovar 1 minuto antes de que venza

let cache: {
    token: string | null;
    refreshToken: string | null;
    expiresAt: number;
} = { token: null, refreshToken: null, expiresAt: 0 };

let inFlight: Promise<string> | null = null;

// Única función pública: el resto de la app solo llama a getToken().
export async function getToken(): Promise<string> {
    if (cache.token && cache.expiresAt - Date.now() > MARGEN_MS) {
        return cache.token; // token vigente
    }
    if (!inFlight) inFlight = renewToken().finally(() => (inFlight = null));
    return inFlight;
}

// Decide CÓMO renovar.
async function renewToken(): Promise<string> {
    const rt = cache.refreshToken; // copia local

    if (rt) {
        try {
            return await refreshToken(rt); // renovar sin contraseña
        } catch (error) {
            console.warn('Refresh token de Factus falló; se hará login de nuevo.', error);
        }
    }
    return requestToken(); // no hay refresh token o falló -> login
}

// Login con usuario y contraseña.
function requestToken(): Promise<string> {
    return postToken({
        grant_type: 'password',
        client_id: env.FACTUS_CLIENT_ID,
        client_secret: env.FACTUS_CLIENT_SECRET,
        username: env.FACTUS_USERNAME,
        password: env.FACTUS_PASSWORD,
    });
}

// Renovación con refresh token.
function refreshToken(rt: string): Promise<string> {
    return postToken({
        grant_type: 'refresh_token',
        client_id: env.FACTUS_CLIENT_ID,
        client_secret: env.FACTUS_CLIENT_SECRET,
        refresh_token: rt,
    });
}

// Lo que ambas comparten: enviar el formulario, validar la respuesta y guardar en cache.
async function postToken(fields: Record<string, string>): Promise<string> {
    const res = await fetchFactus(TOKEN_URL, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            Accept: 'application/json',
        },
        body: new URLSearchParams(fields),
        signal: AbortSignal.timeout(15_000), // no quedarse colgado si Factus no responde
    });

    // Si Factus responde con error, lanzamos un 502 (falla del proveedor externo)
    // con lo que dijo Factus (p. ej. "invalid_client"), para depurar rápido.
    if (!res.ok) {
        throw new FactusError(`Auth Factus falló: ${res.status}`, res.status, await readBody(res));
    }

    const data = (await res.json()) as TokenResponse;
    cache = {
        token: data.access_token,
        refreshToken: data.refresh_token,
        expiresAt: Date.now() + data.expires_in * 1000, // segundos -> milisegundos
    };
    return data.access_token;
}

export function invalidateToken(): void {
    cache = { ...cache, token: null, expiresAt: 0 };
}

// Para diagnóstico: cuántos segundos le quedan al token (nunca exponemos el token).
export function tokenSecondsLeft(): number {
    return Math.max(0, Math.round((cache.expiresAt - Date.now()) / 1000));
}