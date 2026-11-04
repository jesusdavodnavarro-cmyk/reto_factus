import { Router } from 'express';
import { getToken, tokenSecondsLeft } from '../integrations/factus/tokenManager';
import { factusRequest } from '../integrations/factus/factusClient';
import { verificarPay } from '../integrations/factusPay/payClient';

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

// GET /api/factus/pay/status -> ¿el backend se autentica con Factus Pay?
factusRouter.get('/pay/status', async (_req, res) => {
    await verificarPay();
    res.json({ factusPay: 'conectado' });
});

// GET /api/factus/rangos -> rangos de numeración ACTIVOS para factura de venta.
// Sin un rango activo no se puede emitir factura (Hito 3).
// Por ahora devolvemos lo que responde Factus tal cual: primero miramos
// la forma real de la respuesta y DESPUÉS la modelamos.
factusRouter.get('/rangos', async (_req, res) => {
    const query = new URLSearchParams({
        'filter[document]': '21', // 21 = Factura de venta
        'filter[is_active]': '1', // solo activos
    });

    const { data } = await factusRequest<unknown>('GET', `/v2/numbering-ranges?${query}`);
    res.json(data);
});
