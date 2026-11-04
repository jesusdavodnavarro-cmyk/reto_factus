import { z } from 'zod';

// Carga el archivo .env (sin librerías extra).
// Si no existe, por ejemplo en producción, se usan las variables del sistema.
try {
  process.loadEnvFile();
} catch {
  // Sin .env: no pasa nada
}

// Describimos qué variables esperamos y de qué tipo son
const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.coerce.number().int().positive().default(3000),

  FACTUS_BASE_URL: z.url(),
  FACTUS_CLIENT_ID: z.string().min(1),
  FACTUS_CLIENT_SECRET: z.string().min(1),
  FACTUS_USERNAME: z.email(),
  FACTUS_PASSWORD: z.string().min(1),

  // Tarifa de energía de Afinia en COP por kWh. Se configura sin tocar código.
  AFINIA_TARIFA_KWH: z.coerce.number().positive().default(1033),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('Variables de entorno inválidas:', parsed.error.issues);
  process.exit(1); // Mejor fallar al arrancar que fallar a mitad de una petición
}

export const env = parsed.data;