# Sol a Cuotas: UNA imagen con la app Flutter web y el backend Node.
# El backend sirve la app en "/" y la API en "/api" (misma URL, sin CORS).
#   docker build -t sol-a-cuotas .
#   docker run -p 3000:3000 --env-file backend/.env sol-a-cuotas

# ---------- Etapa 1: compilar la app Flutter web ----------
FROM ghcr.io/cirruslabs/flutter:stable AS app
WORKDIR /app
COPY pubspec.yaml pubspec.lock analysis_options.yaml ./
RUN flutter pub get
COPY lib ./lib
COPY web ./web
# --csp: no genera código dinámico, así cumple la política de seguridad del backend
RUN flutter build web --release --csp

# ---------- Etapa 2: compilar el backend TypeScript ----------
FROM node:24-slim AS api
WORKDIR /app/backend
RUN npm install -g pnpm@10.33.2
COPY backend/package.json backend/pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
COPY backend/tsconfig.json ./
COPY backend/src ./src
RUN pnpm build && pnpm prune --prod

# ---------- Etapa 3: imagen final (solo lo necesario para correr) ----------
FROM node:24-slim
ENV NODE_ENV=production
WORKDIR /app/backend
COPY --from=api /app/backend/package.json ./
COPY --from=api /app/backend/node_modules ./node_modules
COPY --from=api /app/backend/dist ./dist
COPY --from=app /app/build/web ./public
# Carpeta de datos (JSON) escribible por el usuario sin privilegios
RUN mkdir -p data && chown node:node data
# Render inyecta PORT; en local es 3000
EXPOSE 3000
USER node
CMD ["node", "dist/server.js"]
