// Rutas HTTP de solicitudes: solo traducen HTTP <-> servicio.
// La validación la hace validateBody; la lógica, solicitud.service.

import { Router } from 'express';
import { validateBody } from '../../middlewares/validate';
import { crearSolicitudSchema } from './solicitud.schema';
import { crearSolicitud, listarSolicitudes, obtenerSolicitud } from './solicitud.service';

export const solicitudesRouter = Router();

// POST /api/solicitudes -> el cliente envía "Quiero mi proyecto solar"
solicitudesRouter.post('/', validateBody(crearSolicitudSchema), (req, res) => {
    const solicitud = crearSolicitud(req.body);
    res.status(201).location(`/api/solicitudes/${solicitud.id}`).json(solicitud);
});

// GET /api/solicitudes -> lista para el panel del contratista
solicitudesRouter.get('/', (_req, res) => {
    res.json(listarSolicitudes());
});

// GET /api/solicitudes/:id -> detalle (404 si no existe)
solicitudesRouter.get('/:id', (req, res) => {
    res.json(obtenerSolicitud(req.params.id));
});
