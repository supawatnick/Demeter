# Demeter Retirement Planner — Functional Requirements

## 1. Authentication

### FR-AUTH-001 Registration
The system shall allow a user to register with email and password.

### FR-AUTH-002 Password Security
Passwords shall be stored only as strong password hashes.

### FR-AUTH-003 Login
The system shall authenticate valid credentials and establish an authenticated session.

### FR-AUTH-004 Logout
The system shall invalidate or revoke the active session as appropriate.

### FR-AUTH-005 Authorization
The system shall enforce USER and ADMIN roles on the backend.

### FR-AUTH-006 User Disable
An ADMIN shall be able to disable a user. Disabled users shall not be permitted to authenticate or continue privileged authenticated use.

## 2. Retirement Plan

### FR-PLAN-001 Create Plan
An authenticated user shall be able to create one primary retirement plan.

### FR-PLAN-002 Edit Plan
The user shall be able to edit retirement assumptions and save changes.

### FR-PLAN-003 Input Validation
The backend shall validate plan inputs and reject impossible or unsupported values.

### FR-PLAN-004 Current Savings
v1 shall accept current savings as one aggregate monetary value.

### FR-PLAN-005 Contribution Growth
The plan shall support monthly contribution and annual contribution increase percentage.

### FR-PLAN-006 Return Assumptions
The plan shall separately support pre-retirement and post-retirement expected return.

### FR-PLAN-007 Expense Basis
Monthly retirement expense shall be entered in today's money.

### FR-PLAN-008 Currency
v1 shall default to THB while persisting a currency code.

## 3. Calculation Engine

### FR-CALC-001 Deterministic Projection
The system shall produce deterministic projections from the saved plan assumptions.

### FR-CALC-002 Retirement Fund Required
The system shall compute required retirement capital using a post-retirement drawdown model.

### FR-CALC-003 Portfolio at Retirement
The system shall project current savings and future contributions to retirement age.

### FR-CALC-004 Funding Gap
The system shall compute projected surplus or shortfall at retirement.

### FR-CALC-005 Monthly Savings Required
The system shall compute the monthly contribution needed to meet the target under current assumptions.

### FR-CALC-006 Incremental Contribution
The system shall show the additional monthly contribution required compared with the current contribution.

### FR-CALC-007 Calculation Version
Each stored result/snapshot shall be traceable to a calculation model/version.

### FR-CALC-008 Repeatability
Given identical inputs and calculation version, deterministic results shall be reproducible.

## 4. Dashboard

### FR-DASH-001 Core KPIs
The dashboard shall display:
- Retirement Readiness Score
- Retirement Fund Required
- Projected Portfolio at Retirement
- Funding Gap / Surplus
- Required Monthly Contribution

### FR-DASH-002 Projection Chart
The dashboard shall display a lifetime projection from current age through life expectancy.

### FR-DASH-003 Retirement Marker
The projection shall clearly indicate retirement age.

### FR-DASH-004 Accumulation vs Drawdown
The UI shall visually distinguish pre-retirement accumulation and post-retirement drawdown.

### FR-DASH-005 Explanations
Important KPIs and scores shall include understandable explanations.

## 5. Retirement Readiness Score

### FR-RRS-001 Score
The system shall compute a score from 0 to 100.

### FR-RRS-002 Breakdown
The system shall expose score components sufficient to explain the result.

### FR-RRS-003 Actionability
Where possible, the system shall explain which user-controlled assumptions most improve readiness.

### FR-RRS-004 No Guarantee
The UI shall not represent the readiness score or projection as a guaranteed outcome.

## 6. Financial Health Score

### FR-FHS-001 Separate Metric
Financial Health Score shall be independent of Retirement Readiness Score.

### FR-FHS-002 Explainable Dimensions
The system shall expose the dimensions used to calculate the score.

### FR-FHS-003 Data Honesty
The score shall only claim to measure dimensions supported by data collected by Demeter.

## 7. Scenario Comparison

### FR-SCEN-001 Scenario Count
A user shall be able to compare 2-3 scenarios.

### FR-SCEN-002 Editable Variables
v1 scenario overrides shall include:
- retirement age,
- monthly contribution,
- expected return,
- monthly retirement expense.

### FR-SCEN-003 Comparison Output
For each scenario, the system shall show:
- key retirement KPIs,
- funding gap/surplus,
- readiness score impact,
- projection series.

### FR-SCEN-004 Base Plan Integrity
Scenario changes shall not silently overwrite the primary plan.

## 8. Goal Tracking

### FR-GOAL-001 Primary Goal
v1 shall support one primary retirement goal per user.

### FR-GOAL-002 Milestones
The user shall be able to track milestones associated with the goal.

### FR-GOAL-003 Snapshots
The system shall store historical snapshots after significant saved plan changes.

### FR-GOAL-004 Trend View
The system shall be able to present trends for:
- current savings,
- readiness score,
- funding gap,
- projected portfolio.

## 9. Administration

### FR-ADMIN-001 Admin Area
ADMIN users shall have access to an admin area in the application.

### FR-ADMIN-002 User Creation
ADMIN shall be able to create user accounts.

### FR-ADMIN-003 Disable User
ADMIN shall be able to disable users.

### FR-ADMIN-004 Role Enforcement
All admin operations shall be protected by server-side authorization.

## 10. Audit Logging

### FR-AUDIT-001 Authentication Events
The system shall record meaningful login/logout events.

### FR-AUDIT-002 Administrative Events
The system shall record user creation, disablement, and role changes.

### FR-AUDIT-003 Important Data Changes
The system shall record selected significant retirement-plan changes.

### FR-AUDIT-004 Safe Metadata
Audit logs shall not store passwords, tokens, session secrets, or unnecessary sensitive payloads.

## 11. Non-Functional Requirements

### FR-NFR-001 Responsive UI
The product shall support modern desktop and mobile form factors.

### FR-NFR-002 Theme
The product shall support dark and light themes.

### FR-NFR-003 Accessibility
Core user journeys shall use semantic, keyboard-accessible UI components.

### FR-NFR-004 Structured Logging
Web/API services shall use structured logs with request correlation.

### FR-NFR-005 Health
The backend shall expose liveness and readiness endpoints.

### FR-NFR-006 Privacy
Sensitive input values shall not be unnecessarily logged.

### FR-NFR-007 Monetary Precision
Persisted monetary values shall use decimal-safe database representations rather than floating-point currency storage.

### FR-NFR-008 Calculation Precision
Calculation logic shall use a documented numerical precision and rounding policy.

### FR-NFR-009 API Validation
All write APIs shall perform server-side validation.

### FR-NFR-010 API Compatibility
Changes should remain backward-compatible during normal rollout and deprecation windows.

## 12. Operational Requirements

### FR-OPS-001 Staging Promotion
main shall automatically deploy to staging after CI succeeds.

### FR-OPS-002 Production Artifact
Production shall run the same immutable image digest validated in staging.

### FR-OPS-003 Release Version
Production releases shall use SemVer tags.

### FR-OPS-004 Pre-deploy Backup
Every production release shall require a successful PostgreSQL backup before migration/deploy.

### FR-OPS-005 Migration
Database migrations shall execute as an explicit pre-deploy step.

### FR-OPS-006 Destructive Change
Destructive schema changes shall require explicit review and expand/contract strategy.

### FR-OPS-007 Readiness
A production deploy shall not be considered healthy until readiness succeeds.

### FR-OPS-008 Smoke Test
A production deploy shall run automated smoke tests with a dedicated synthetic non-admin user.

### FR-OPS-009 Rollback
Failed readiness or smoke testing shall automatically roll the application back to the last known good application release.

### FR-OPS-010 Alerting
Operational failures shall alert the Demeter Ops Telegram group.

## 13. Deferred Requirements
Deferred from v1:
- email verification,
- password reset email flow,
- real multi-currency workflows,
- external financial account aggregation,
- live Monte Carlo simulations,
- multiple retirement goals,
- backend rate limiting beyond Cloudflare edge controls,
- subscription/billing.
