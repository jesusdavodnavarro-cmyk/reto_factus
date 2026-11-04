import { Router } from 'express';
import { factusRouter } from './factus.routes';
import { solicitudesRouter } from '../modules/solicitudes/solicitud.routes';
import { proyectosRouter } from '../modules/proyectos/proyecto.routes';
import { cuotasRouter } from '../modules/cuotas/cuota.routes';
import { webhooksRouter } from '../modules/cuotas/webhook.routes';

export const router = Router();

// Ruta prueba: ¿el servidor está vivo?
router.get('/health', (_req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Todo lo relacionado con Factus cuelga de /api/factus
router.use('/factus', factusRouter);

// Hito 1: "Quiero mi proyecto solar"
router.use('/solicitudes', solicitudesRouter);

// Hito 3: proyecto + plan de cuotas
router.use('/proyectos', proyectosRouter);

// Hito 3 y 4: factura (Factus) + recaudo (Factus Pay) de cada cuota
router.use('/cuotas', cuotasRouter);

// Hito 4: avisos de pago de Factus Pay
router.use('/webhooks', webhooksRouter);
