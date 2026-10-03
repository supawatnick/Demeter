# Aether Retirement Planner

Production-ready retirement planning platform built with Next.js, TypeScript, TailwindCSS, shadcn/ui, Recharts, NestJS, PostgreSQL, and Prisma.

## Monorepo

- `apps/web` — Next.js frontend
- `apps/api` — NestJS backend
- `packages/database` — Prisma schema and database layer
- `docs` — product, architecture, API, and deployment documentation
- `.github/workflows` — CI pipeline

## Core capabilities

Authentication, retirement goal planning, retirement fund and future-value calculations, financial health scoring, scenario comparison, projections, goal tracking, and a Monte Carlo-ready calculation architecture.

## Local development

```bash
cp .env.example .env
docker compose up -d postgres
pnpm install
pnpm db:generate
pnpm db:migrate
pnpm dev
```

Frontend: http://localhost:3000  
API: http://localhost:4000  
OpenAPI docs: http://localhost:4000/docs
