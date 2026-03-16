# ── Estágio base: imagem mínima com Node LTS ──────────────────────────────────
FROM node:lts AS base
WORKDIR /app

# Copiar apenas manifests primeiro (otimiza cache do Docker)
COPY package.json package-lock.json ./

# ── Estágio: dependências de produção (sem devDependencies) ───────────────────
FROM base AS prod-deps
RUN npm install --omit=dev

# ── Estágio: dependências de build (inclui devDependencies) ───────────────────
FROM base AS build-deps
RUN npm install

# ── Estágio: build da aplicação ───────────────────────────────────────────────
FROM build-deps AS build
COPY . .
RUN npm run build

# ── Estágio final: runtime mínimo ─────────────────────────────────────────────
FROM node:lts-alpine AS runtime
WORKDIR /app

# Copiar apenas o necessário para rodar
COPY --from=prod-deps /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist

# Variáveis de ambiente padrão (podem ser sobrescritas no compose/k8s)
ENV HOST=0.0.0.0
ENV PORT=4321

EXPOSE 4321

# Astro SSR entry point gerado pelo adaptador Node
CMD ["node", "./dist/server/entry.mjs"]
