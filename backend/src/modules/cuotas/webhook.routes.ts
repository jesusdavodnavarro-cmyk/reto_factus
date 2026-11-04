// Webhook de Factus Pay: avisa cuando un recaudo se paga.
// Se registra en el panel de Factus Pay como:
//   https://<url-publica>/api/webhooks/factus-pay   con la llave FACTUS_PAY_WEBHOOK_KEY
// Factus Pay llama:  POST ...?key=<llave>   con { data: { reference_code, status: 'paid', ... } }

import { timingSafeEqual } from 'node:crypto';
import { Router } from 'express';
import { env } from '../../config/env';
import { procesarAvisoDePago } from './cuota.service';

export const webhooksRouter = Router();

// Compara en tiempo constante (evita adivinar la llave midiendo tiempos de respuesta)
function llaveValida(recibida: unknown): boolean {
    if (!env.FACTUS_PAY_WEBHOOK_KEY || typeof recibida !== 'string') return false;
    const a = Buffer.from(recibida);
    const b = Buffer.from(env.FACTUS_PAY_WEBHOOK_KEY);
    return a.length === b.length && timingSafeEqual(a, b);
}

webhooksRouter.post('/factus-pay', async (req, res) => {
    if (!llaveValida(req.query.key)) {
        res.status(401).json({ error: 'Llave inválida' });
        return;
    }

    const referencia = req.body?.data?.reference_code;
    const status = req.body?.data?.status;
    console.log(`[webhook factus-pay] ${referencia} -> ${status}`);

    if (typeof referencia !== 'string' || status !== 'paid') {
        res.json({ received: true, ignored: true }); // 2xx: que no reintente
        return;
    }

    // Confirma con la API y concilia. Si esto falla, respondemos 5xx y Factus Pay reintenta.
    const resultado = await procesarAvisoDePago(referencia);
    res.json({ received: true, ...resultado });
});
