// Configura Express

import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import { router } from './routes/index';
import { notFound } from './middlewares/not-found';
import { errorHandler } from './middlewares/error-handler';

export const app = express();

// Middlewares globales: se ejecutan en cada petición, en el orden
app.use(helmet());
app.use(cors());
app.use(express.json());


// Rutas
app.use('/api', router);

// finalmente, 404 y manejo de errores
app.use(notFound);
app.use(errorHandler);