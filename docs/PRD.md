# Demeter Retirement Planner — Product Requirements Document

## 1. Product Summary
Demeter Retirement Planner is a modern retirement planning application that helps individuals understand whether they are on track for retirement, how much capital they may need, how their portfolio may evolve, and what changes can improve their retirement outcome.

The first release is a production-grade private/internal beta intended to mature into a commercial B2C product, while keeping the architecture extensible for future B2B and white-label use.

## 2. Product Goals
Demeter should enable a user to:
- create a retirement plan in minutes,
- understand the amount required at retirement,
- see projected portfolio value through retirement,
- identify funding surplus or shortfall,
- understand the monthly saving level required,
- compare alternative retirement scenarios,
- track progress over time,
- understand why readiness scores are high or low,
- use a responsive, premium fintech interface on desktop and mobile.

## 3. Target Users

### Primary
Individuals planning their own retirement who can provide basic financial assumptions manually.

### Secondary, future
- financial advisors,
- employers,
- benefit providers,
- white-label financial platforms.

B2B/white-label capabilities are not required in v1, but major architectural decisions should not prevent them later.

## 4. Core User Inputs
A retirement plan captures:
- Current Age
- Retirement Age
- Life Expectancy
- Current Savings
- Monthly Contribution
- Annual Contribution Increase
- Pre-retirement Expected Return
- Post-retirement Expected Return
- Expected Inflation
- Monthly Expense After Retirement, expressed in today's money
- Currency code, default THB

Optional expense categories may break the monthly retirement expense into:
- housing,
- food,
- healthcare,
- travel,
- insurance,
- other.

## 5. Core Outputs
The product must calculate and display:
- Retirement Fund Required
- Projected Portfolio at Retirement
- Funding Gap / Surplus
- Monthly Savings Required
- Incremental Monthly Contribution Required
- Retirement Readiness Score
- Financial Health Score
- Lifetime Retirement Projection

## 6. Dashboard
The dashboard must prominently display five retirement KPIs:
1. Retirement Readiness Score
2. Retirement Fund Required
3. Projected Portfolio at Retirement
4. Funding Gap / Surplus
5. Required Monthly Contribution

It should also show:
- progress toward retirement goal,
- recent plan changes,
- historical trend snapshots,
- primary retirement projection chart,
- milestone status,
- scenario comparison entry point.

## 7. Retirement Readiness Score
The score is 0-100 and must be explainable.

The UI must show:
- overall score,
- status label,
- factor breakdown,
- plain-language explanation of what is helping or hurting the score,
- actionable suggestions where possible.

The score must not imply certainty or guarantee investment outcomes.

## 8. Financial Health Score
Financial Health Score is distinct from Retirement Readiness Score.

It represents broader financial planning quality and behavior. v1 may use only inputs that Demeter actually collects; the score must not pretend to measure factors for which no data exists.

If a sufficiently defensible v1 formula cannot be produced from available data, the feature may launch as a limited-scope score with explicit dimensions rather than a broad claim of total financial health.

## 9. Retirement Projection
The projection should cover the full timeline:
- current age to retirement,
- retirement to life expectancy.

The chart should visually distinguish:
- accumulation phase,
- retirement/drawdown phase,
- retirement age marker.

The deterministic model is the source of truth for v1.

## 10. Scenario Comparison
Users can compare 2-3 scenarios side-by-side.

v1 scenario variables:
- Retirement Age
- Monthly Contribution
- Expected Return
- Monthly Expense After Retirement

Each scenario should show:
- core KPIs,
- readiness impact,
- projected balance at retirement,
- funding gap/surplus,
- projection chart.

## 11. Goal Tracking
v1 supports one Primary Retirement Goal.

The goal may contain milestones such as:
- target savings amount,
- readiness score threshold,
- funding gap threshold.

Demeter stores historical snapshots when users save significant plan changes so the user can see changes over time.

## 12. Authentication and Roles
v1 uses local authentication:
- email/password registration,
- login,
- logout,
- secure password hashing,
- session/refresh-token support.

Roles:
- USER
- ADMIN

ADMIN can:
- view user administration,
- create users,
- disable users,
- change roles where authorized,
- access operational administration features.

Backend authorization is mandatory for privileged operations.

## 13. Auditability
Audit logging should record important actions such as:
- login/logout,
- user creation/disable,
- role changes,
- important plan/data changes,
- deployment-sensitive configuration changes.

Audit records should include:
- actor,
- action,
- target,
- timestamp,
- request ID,
- non-secret metadata.

Sensitive credentials and financial values should not be unnecessarily duplicated into audit logs.

## 14. Non-Goals for v1
The following are out of scope:
- live bank/broker aggregation,
- transaction ingestion,
- payment-card storage,
- full asset/account aggregation,
- multiple independent retirement goals,
- live Monte Carlo simulations in UI,
- full multi-currency workflows,
- Kubernetes,
- high availability / zero-downtime deployment,
- full enterprise observability stack.

## 15. Monte Carlo Readiness
v1 does not expose Monte Carlo simulation, but the architecture must:
- isolate calculation logic from UI and persistence,
- version calculation assumptions,
- support deterministic and future stochastic engines through clear interfaces,
- support storing simulation metadata/results later.

## 16. Currency
v1 uses THB as the default active currency.

All relevant monetary data models should store currency code so multi-currency support can be introduced without redesigning the schema.

## 17. UX / Design Principles
The interface should be:
- modern,
- premium,
- minimal,
- fintech-oriented,
- responsive,
- accessible,
- dark/light mode capable.

Visual inspiration:
- Wealthfront
- Betterment
- Personal Capital
- Empower

Design priorities:
1. clarity over density,
2. explain calculations in plain language,
3. show actionable next steps,
4. avoid implying guaranteed outcomes,
5. keep onboarding friction low.

## 18. Success Criteria for Internal Beta
The internal beta is successful when a user can:
- register and sign in,
- create and edit a retirement plan,
- receive deterministic projections consistently,
- understand the five dashboard KPIs,
- compare scenarios,
- track historical plan progress,
- complete the critical journey without admin intervention,
- use the product reliably on desktop and mobile.

Operationally:
- staging auto-deploy works from main,
- production releases are reproducible from immutable images,
- backups, readiness checks, smoke tests, rollback, and alerting work as documented.

## 19. Product Risks
Key product risks:
- users may interpret deterministic projection as certainty,
- scoring systems may appear arbitrary if not explainable,
- unrealistic return/inflation assumptions can make outputs misleading,
- users may not know reasonable assumptions,
- oversimplified savings inputs may omit important retirement assets.

Mitigations:
- clear assumption summaries,
- editable defaults,
- factor explanations,
- disclaimers,
- scenario comparison,
- future Monte Carlo capability.

## 20. Open Product Decisions
These do not block initial architecture:
- exact score weights,
- default market assumptions,
- healthcare-specific inflation,
- subscription/pricing model,
- future B2B tenancy model,
- exact production domain,
- exact email verification/reset rollout.
