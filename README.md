# ☀️ Sol a Cuotas

Hackathon **API WARS** · I Congreso Internacional de Ingeniería de Sistemas (UCC Montería), 4 de noviembre de 2026.

Plataforma para la **pyme contratista de energía solar en Montería**. El cliente pide su proyecto, recibe un plan de cuotas con el subsidio de *Colombia Solar*, y **cada cuota se factura, se cobra y se concilia sola**:

```
factura electrónica (Factus)  →  recaudo QR / llave Bre-B (Factus Pay)  →  pago  →  conciliación automática
```

La **referencia de cada cuota** (ej. `PRY-001-C01-K7Q2X`) es la misma en Factus (`reference_code` de la factura) y en Factus Pay (`reference_code` del recaudo). Así el dinero recaudado se asocia con su factura sin conciliar a mano.

## Arquitectura

```
 Navegador (PWA Flutter)  ──►  Backend Node/Express  ──►  Factus (facturación DIAN)
        "/"                         "/api"           ──►  Factus Pay (recaudo Bre-B)
                                      ▲
                                      └──  Webhook de Factus Pay (pago recibido)
```

- **La PWA nunca llama a Factus.** Las credenciales y la lógica de negocio (precio, subsidio, cuotas) viven solo en el backend.
- En producción, **un solo servicio** sirve la app (`/`) y la API (`/api`): misma URL, sin CORS.

| Carpeta | Qué es |
|---|---|
| `lib/` | App Flutter (web): Riverpod, go_router, dio |
| `backend/` | API Node 24 + Express 5 + TypeScript (pnpm), validación con zod |
| `backend/requests/` | Peticiones de ejemplo (REST Client); sirven de **contrato** entre UI y API |
| `backend/scripts/smoke.sh` | Prueba de humo de todo el flujo |
| `Dockerfile`, `render.yaml` | Despliegue en Render (una imagen: Flutter + Node) |

## Correr en local

**Backend**

```bash
cd backend
cp .env.example .env      # llenar credenciales del sandbox de Factus y Factus Pay
pnpm install
pnpm dev                  # http://localhost:3000/api/health
bash scripts/smoke.sh     # FACTURAR=1 para probar también factura + recaudo
```

**App Flutter**

```bash
flutter pub get
flutter run -d chrome     # usa http://localhost:3000/api
# Backend en otro equipo:
flutter run -d chrome --dart-define=API_URL=http://192.168.1.76:3000/api
```

## API

| Método y ruta | Qué hace |
|---|---|
| `GET /api/health` | Servidor vivo |
| `GET /api/factus/status` · `GET /api/factus/pay/status` | ¿Autentica con Factus / Factus Pay? |
| `GET /api/factus/rangos` | Rangos de numeración activos |
| `POST /api/solicitudes` | "Quiero mi proyecto solar" (consumo en kWh o en pesos) |
| `POST /api/proyectos` | Plan de cuotas: potencia, valor, subsidio 60 %, cuotas |
| `GET /api/proyectos/:id` | Proyecto con cuotas y totales (facturado, recaudado, pendiente, mora) |
| `POST /api/cuotas/:id/pagar` | Factura (Factus) + recaudo (Factus Pay) en un paso |
| `POST /api/cuotas/:id/verificar-pago` | Consulta Factus Pay y concilia |
| `GET /api/cuotas/:id` | Cuota con factura, recaudo, pago e historial |
| `POST /api/webhooks/factus-pay?key=…` | Aviso de pago de Factus Pay |

## Variables de entorno

Ver `backend/.env.example`. El servidor **no arranca** si falta alguna obligatoria.

| Variable | Obligatoria | Uso |
|---|---|---|
| `FACTUS_BASE_URL`, `FACTUS_CLIENT_ID`, `FACTUS_CLIENT_SECRET`, `FACTUS_USERNAME`, `FACTUS_PASSWORD` | Sí | Facturación electrónica |
| `FACTUS_PAY_BASE_URL`, `FACTUS_PAY_EMAIL`, `FACTUS_PAY_PASSWORD` | Sí | Recaudo |
| `FACTUS_PAY_WEBHOOK_KEY` | No | Llave del webhook (mín. 16 caracteres) |
| `AFINIA_TARIFA_KWH`, `PRECIO_KWP_COP`, `RECAUDO_EXPIRACION_SEG` | No | Parámetros de negocio |

> Factus Pay revoca el token anterior con cada login: **solo un backend a la vez** debe usar las mismas credenciales.

## Despliegue (Render)

1. Render → **New → Blueprint** → este repositorio (lee `render.yaml`), o **New → Web Service → Docker**.
2. Llenar las variables marcadas como secretas (credenciales de Factus y Factus Pay).
3. Al terminar el build: `https://<servicio>.onrender.com` (app) y `/api/health` (API).
4. Webhook en el panel de Factus Pay: `https://<servicio>.onrender.com/api/webhooks/factus-pay` con la llave de `FACTUS_PAY_WEBHOOK_KEY`.

Plan gratuito: el servicio se duerme a los 15 min sin tráfico (≈1 min en despertar) y los datos JSON se borran al reiniciar. Para producción: base de datos (Postgres) y plan pago.
