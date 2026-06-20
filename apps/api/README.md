# @ats-express/api

Backend NestJS (monolito modular) de ATS-Express.

## Requisitos

- Node >= 20
- pnpm 9

## Setup

Desde la **raíz del monorepo**:

```bash
pnpm install
cp .env.example .env   # completar credenciales (Supabase, etc.)
```

## Base de datos (Prisma + Supabase)

```bash
# Generar el cliente Prisma
pnpm --filter @ats-express/api db:generate

# Crear/aplicar migraciones (requiere DIRECT_URL en .env)
pnpm --filter @ats-express/api db:migrate

# Aplicar políticas RLS (después de migrar)
pnpm --filter @ats-express/api db:rls
```

## Desarrollo

```bash
# Levantar la API en modo watch
pnpm --filter @ats-express/api dev
```

- API bajo prefijo `/api` (ej. `GET /api/...`).
- `GET /health` queda **fuera** del prefijo (keep-alive de Render via cron-job.org;
  no toca la base de datos).

## Estructura

```
src/
├── main.ts            # bootstrap (prefijo /api, CORS, validación)
├── app.module.ts      # módulo raíz
├── prisma/            # PrismaModule + PrismaService (service role)
├── health/            # GET /health (keep-alive)
└── ...                # módulos de dominio (Etapa 1+)
prisma/
├── schema.prisma      # modelo de datos
└── rls/policies.sql   # políticas RLS (defensa en profundidad)
```
