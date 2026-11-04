import { Router } from 'express';
import { factusRouter } from './factus.routes';

export const router = Router();

// Ruta prueba: ¿el servidor está vivo?
router.get('/health', (_req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Todo lo relacionado con Factus cuelga de /api/factus
router.use('/factus', factusRouter);
