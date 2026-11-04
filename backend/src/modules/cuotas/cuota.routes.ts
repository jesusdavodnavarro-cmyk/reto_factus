import { Router } from 'express';
import { obtenerCuota } from '../proyectos/proyecto.service';
import { cobrarCuota, facturarCuota, iniciarPago, verificarPago } from './cuota.service';

export const cuotasRouter = Router();

// GET /api/cuotas/:id -> detalle con factura, recaudo, pago e historial
cuotasRouter.get('/:id', (req, res) => {
    res.json(obtenerCuota(req.params.id).cuota);
});

// POST /api/cuotas/:id/facturar -> solo la factura electrónica (Factus)
cuotasRouter.post('/:id/facturar', async (req, res) => {
    res.json(await facturarCuota(req.params.id));
});

// POST /api/cuotas/:id/cobrar -> solo el recaudo (Factus Pay); requiere factura
cuotasRouter.post('/:id/cobrar', async (req, res) => {
    res.json(await cobrarCuota(req.params.id));
});

// POST /api/cuotas/:id/pagar -> factura + recaudo en un paso (botón "Pagar" de la app)
cuotasRouter.post('/:id/pagar', async (req, res) => {
    res.json(await iniciarPago(req.params.id));
});

// POST /api/cuotas/:id/verificar-pago -> consulta Factus Pay y concilia si ya pagó
cuotasRouter.post('/:id/verificar-pago', async (req, res) => {
    res.json(await verificarPago(req.params.id, 'consulta'));
});
