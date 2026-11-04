import { z } from 'zod';

// URL sin "/" al final: así "https://x.co/" + "/auth" no queda "https://x.co//auth"
const urlBase = z.url().transform((u) => u.replace(/\/+$/, ''));

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

  FACTUS_BASE_URL: urlBase,
  FACTUS_CLIENT_ID: z.string().min(1),
  FACTUS_CLIENT_SECRET: z.string().min(1),
  FACTUS_USERNAME: z.email(),
  FACTUS_PASSWORD: z.string().min(1),

  // Rango de numeración de facturas. Opcional: si hay un solo rango activo, Factus lo usa solo.
  FACTUS_NUMBERING_RANGE_ID: z.preprocess((v) => (v === '' ? undefined : v), z.coerce.number().int().positive().optional()),

  // Factus Pay (recaudo): es OTRA API con credenciales propias
  FACTUS_PAY_BASE_URL: urlBase.default('https://pay-api-sandbox.factus.com.co'),
  FACTUS_PAY_EMAIL: z.email(),
  FACTUS_PAY_PASSWORD: z.string().min(1),
  // Llave que se registra en el panel de Factus Pay para validar el webhook (?key=...)
  // (vacío en el .env = no configurada)
  FACTUS_PAY_WEBHOOK_KEY: z.preprocess((v) => (v === '' ? undefined : v), z.string().min(16).optional()),
  // Cuánto dura vigente el QR de un recaudo, en segundos (24 h por defecto)
  RECAUDO_EXPIRACION_SEG: z.coerce.number().int().positive().default(86_400),

  // Tarifa de energía de Afinia en COP por kWh. Se configura sin tocar código.
  AFINIA_TARIFA_KWH: z.coerce.number().positive().default(1033),

  // Precio instalado por kWp (COP). Se usa para estimar el valor del proyecto.
  PRECIO_KWP_COP: z.coerce.number().int().positive().default(4_200_000),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('Variables de entorno inválidas:', parsed.error.issues);
  process.exit(1); // Mejor fallar al arrancar que fallar a mitad de una petición
}

export const env = parsed.data;