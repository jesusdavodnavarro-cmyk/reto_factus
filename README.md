# Sol a Cuotas — reto_factus

Hackathon **API WARS** · I Congreso Internacional de Ingeniería de Sistemas (UCC Montería).

Financiación en cuotas de proyectos solares: cada cuota sigue el flujo
**factura electrónica (Factus) → recaudo (Factus Pay) → pago → conciliación automática**.

## Estructura (monorepo)

```
reto_factus/
├── lib/ web/ ...   # PWA en Flutter (frontend)
└── backend/        # API Node 24 + Express 5 + TypeScript
```

**Regla de oro:** la PWA **nunca** llama a Factus. Solo llama al backend.
Las credenciales de Factus (client_secret, contraseña) viven únicamente en `backend/.env`.

## Backend

```bash
cd backend
cp .env.example .env     # y llena las credenciales del sandbox
pnpm install
pnpm dev                 # http://localhost:3000
```

| Ruta | Para qué |
|---|---|
| `GET /api/health` | ¿El servidor está vivo? |
| `GET /api/factus/status` | ¿El backend se autentica con Factus? (no expone el token) |

Autenticación con Factus (`backend/src/integrations/factus/`):
- `tokenManager.ts`: OAuth2 password grant, caché en memoria, renovación 60 s antes de vencer, refresh token con respaldo de login, deduplicación de peticiones simultáneas.
- `factusClient.ts`: `factusRequest<T>(method, path, body)` agrega el Bearer, timeout de 30 s y reintenta una vez ante 401.
- `factusError.ts`: error 502 con el código y el cuerpo que devolvió Factus.

## Frontend (Flutter web)

```bash
flutter pub get
flutter run -d chrome
```
