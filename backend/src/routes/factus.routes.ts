import { Router } from 'express';
import { getToken, tokenSecondsLeft } from '../integrations/factus/tokenManager';

export const factusRouter = Router();

// GET /api/factus/status -> ¿el backend logra autenticarse con Factus?
// Útil para la demo y para que la PWA muestre "Conectado a Factus".
// Nunca devolvemos el token: solo confirmamos que existe y cuánto le queda.
// En Express 5, si getToken() lanza, el error llega solo a errorHandler (502).
factusRouter.get('/status', async (_req, res) => {
    await getToken();
    res.json({
        factus: 'conectado',
        tokenExpiresInSeconds: tokenSecondsLeft(),
    });
});
