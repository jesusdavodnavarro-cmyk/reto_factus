// Configura Express

import { existsSync } from 'node:fs';
import { join, resolve } from 'node:path';
import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import { router } from './routes/index';
import { notFound } from './middlewares/not-found';
import { errorHandler } from './middlewares/error-handler';

export const app = express();

// App Flutter ya compilada (flutter build web). En producción la copia el Dockerfile
// a backend/public; en desarrollo no existe y la app corre aparte con `flutter run`.
const PUBLIC_DIR = resolve('public');
const sirveApp = existsSync(join(PUBLIC_DIR, 'index.html'));

// Middlewares globales: se ejecutan en cada petición, en el orden
app.use(
    helmet({
        // Política de seguridad compatible con Flutter web:
        // wasm (CanvasKit), recursos de gstatic y Google Fonts.
        contentSecurityPolicy: {
            directives: {
                defaultSrc: ["'self'"],
                scriptSrc: ["'self'", "'wasm-unsafe-eval'", 'https://www.gstatic.com'],
                styleSrc: ["'self'", "'unsafe-inline'", 'https://fonts.googleapis.com'],
                fontSrc: ["'self'", 'data:', 'https://fonts.gstatic.com'],
                imgSrc: ["'self'", 'data:', 'blob:'],
                connectSrc: ["'self'", 'https://www.gstatic.com', 'https://fonts.gstatic.com', 'https://fonts.googleapis.com'],
                workerSrc: ["'self'", 'blob:'],
                // Render ya fuerza HTTPS; así también se puede probar con http://localhost
                upgradeInsecureRequests: null,
            },
        },
    }),
);
app.use(cors());
app.use(express.json());

// Rutas de la API
app.use('/api', router);

// La app Flutter en la MISMA URL: "/" = app, "/api" = backend (sin CORS ni IPs)
if (sirveApp) {
    app.use(express.static(PUBLIC_DIR));
    // Cualquier GET que no sea /api devuelve index.html (rutas internas de go_router)
    app.use((req, res, next) => {
        if (req.method !== 'GET' || req.path.startsWith('/api')) return next();
        res.sendFile(join(PUBLIC_DIR, 'index.html'));
    });
}

// finalmente, 404 y manejo de errores
app.use(notFound);
app.use(errorHandler);
