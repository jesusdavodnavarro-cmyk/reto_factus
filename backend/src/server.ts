// Enciende servidor

import { env } from './config/env';
import { app } from './app';

app.listen(env.PORT, (error) => {
    if (error) {
        console.error("No se pudo iniciar el servidor.", error);
        process.exit(1);
    }
    console.log(`Servidor en http://localhost:${env.PORT} (${env.NODE_ENV})`);
});