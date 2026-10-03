# Demeter Retirement Planner

A production-ready retirement planning platform that helps users understand retirement readiness, estimate required retirement funds, project future portfolio value, identify funding gaps, compare scenarios, and track long-term financial goals.

## Product Scope

Demeter Retirement Planner is designed around a modern, premium fintech experience inspired by Wealthfront, Betterment, Personal Capital, and Empower.

### Core Features

1. User Authentication
2. Retirement Goal Planning
3. Retirement Fund Calculator
4. Future Value Calculator
5. Monte Carlo Ready Architecture
6. Financial Health Score
7. Retirement Dashboard
8. Scenario Comparison
9. Retirement Projection Charts
10. Goal Tracking

## Retirement Inputs

The planning engine supports:

- Current Age
- Retirement Age
- Current Savings
- Monthly Contribution
- Annual Contribution Increase
- Expected Return
- Expected Inflation
- Monthly Expense After Retirement
- Life Expectancy

## Core Calculations

Demeter calculates:

- Retirement Fund Required
- Future Portfolio Value
- Funding Gap
- Monthly Savings Required
- Retirement Readiness Score

The calculation layer is designed to evolve into probabilistic and Monte Carlo simulations without requiring the application architecture to be rewritten.

## Technology Stack

### Frontend

- Next.js
- TypeScript
- TailwindCSS
- shadcn/ui
- Recharts

### Backend

- NestJS
- PostgreSQL
- Prisma ORM

## Architecture

The project uses a monorepo structure:

```text
apps/
  web/              # Next.js application
  api/              # NestJS API

packages/
  database/         # Prisma schema and database layer
  shared/           # Shared types, validation, and domain contracts

docs/
  product/          # PRD, requirements, user stories
  architecture/     # System, frontend, backend, and ER architecture
  api/              # OpenAPI specification
  deployment/       # Deployment and operational documentation

.github/
  workflows/        # CI/CD pipelines
```

## Planned Documentation

The repository will include:

- Product Requirement Document
- Functional Requirements
- User Stories
- User Flow Diagram
- System Architecture
- ER Diagram
- PostgreSQL Schema
- Prisma Schema
- OpenAPI Specification
- Frontend Architecture
- Backend Architecture
- Docker Compose
- CI/CD Pipeline
- Deployment Guide

## Design Principles

- Modern
- Premium
- Fintech-focused
- Minimal
- Responsive
- Accessible
- Dark / Light Mode
- Clear financial data visualization

## Local Development

The target local workflow is:

```bash
cp .env.example .env
docker compose up -d postgres
pnpm install
pnpm db:generate
pnpm db:migrate
pnpm dev
```

Default development endpoints:

- Frontend: http://localhost:3000
- API: http://localhost:4000
- OpenAPI Docs: http://localhost:4000/docs

## Status

Demeter Retirement Planner is currently being initialized. Application source code, database schemas, documentation, Docker configuration, and CI/CD workflows will be added incrementally to this repository.
