import { Router } from 'express';
import { validateBody } from '../../middlewares/validate';
import { crearProyectoSchema } from './proyecto.schema';
import { crearProyecto, listarProyectos, obtenerProyecto, resumenProyecto } from './proyecto.service';

export const proyectosRouter = Router();

// POST /api/proyectos -> convierte una solicitud en proyecto con plan de cuotas
proyectosRouter.post('/', validateBody(crearProyectoSchema), (req, res) => {
    const proyecto = crearProyecto(req.body);
    res.status(201)
        .location(`/api/proyectos/${proyecto.id}`)
        .json({ ...proyecto, resumen: resumenProyecto(proyecto) });
});

// GET /api/proyectos -> lista con totales (panel del contratista)
proyectosRouter.get('/', (_req, res) => {
    res.json(listarProyectos().map((p) => ({ ...p, resumen: resumenProyecto(p) })));
});

// GET /api/proyectos/:id -> detalle con cuotas y totales
proyectosRouter.get('/:id', (req, res) => {
    const proyecto = obtenerProyecto(req.params.id);
    res.json({ ...proyecto, resumen: resumenProyecto(proyecto) });
});
