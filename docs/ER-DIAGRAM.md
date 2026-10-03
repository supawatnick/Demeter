# Demeter Retirement Planner — ER Diagram

## 1. Purpose
This document defines the recommended v1 logical data model before translating it into PostgreSQL DDL and Prisma schema.

The model prioritizes:
- one primary retirement plan per user in v1,
- immutable historical calculation snapshots,
- explicit calculation versioning,
- clean separation of auth, planning, scenarios, goals, and audit data,
- future extensibility without prematurely implementing full multi-tenancy.

---

# 2. Core ER Diagram

```mermaid
erDiagram
    USER ||--o{ SESSION : has
    USER ||--o| RETIREMENT_PLAN : owns
    USER ||--o{ AUDIT_LOG : acts_in
    USER ||--o{ RETIREMENT_SNAPSHOT : owns
    USER ||--o{ SCENARIO : owns
    USER ||--o| RETIREMENT_GOAL : owns

    RETIREMENT_PLAN ||--o{ CALCULATION_RESULT : produces
    RETIREMENT_PLAN ||--o{ RETIREMENT_SNAPSHOT : snapshots
    RETIREMENT_PLAN ||--o{ SCENARIO : baseline_for
    RETIREMENT_PLAN ||--o| RETIREMENT_GOAL : drives

    RETIREMENT_GOAL ||--o{ GOAL_MILESTONE : contains

    SCENARIO ||--o{ SCENARIO_RESULT : produces

    USER {
      uuid id PK
      citext email UK
      string password_hash
      enum role
      enum status
      timestamptz created_at
      timestamptz updated_at
      timestamptz last_login_at
    }

    SESSION {
      uuid id PK
      uuid user_id FK
      string token_hash
      timestamptz expires_at
      timestamptz revoked_at
      timestamptz created_at
      string user_agent
      string ip_address
    }

    RETIREMENT_PLAN {
      uuid id PK
      uuid user_id FK UK
      int current_age
      int retirement_age
      int life_expectancy
      decimal current_savings
      decimal monthly_contribution
      decimal annual_contribution_increase_rate
      decimal pre_retirement_return_rate
      decimal post_retirement_return_rate
      decimal inflation_rate
      decimal monthly_retirement_expense_today
      string currency_code
      jsonb expense_breakdown
      timestamptz created_at
      timestamptz updated_at
    }

    CALCULATION_RESULT {
      uuid id PK
      uuid retirement_plan_id FK
      string calculation_version
      decimal retirement_fund_required
      decimal projected_portfolio_at_retirement
      decimal funding_gap
      decimal funding_surplus
      decimal required_monthly_contribution
      decimal incremental_monthly_contribution
      decimal readiness_score
      decimal financial_health_score
      jsonb readiness_breakdown
      jsonb financial_health_breakdown
      jsonb projection_series
      int depletion_month_index
      timestamptz created_at
    }

    RETIREMENT_SNAPSHOT {
      uuid id PK
      uuid user_id FK
      uuid retirement_plan_id FK
      string calculation_version
      decimal current_savings
      decimal monthly_contribution
      decimal retirement_fund_required
      decimal projected_portfolio_at_retirement
      decimal funding_gap
      decimal readiness_score
      decimal financial_health_score
      jsonb assumptions
      timestamptz created_at
    }

    SCENARIO {
      uuid id PK
      uuid user_id FK
      uuid retirement_plan_id FK
      string name
      jsonb overrides
      int sort_order
      timestamptz created_at
      timestamptz updated_at
    }

    SCENARIO_RESULT {
      uuid id PK
      uuid scenario_id FK
      string calculation_version
      jsonb result_summary
      jsonb projection_series
      timestamptz created_at
    }

    RETIREMENT_GOAL {
      uuid id PK
      uuid user_id FK UK
      uuid retirement_plan_id FK UK
      string status
      timestamptz created_at
      timestamptz updated_at
    }

    GOAL_MILESTONE {
      uuid id PK
      uuid retirement_goal_id FK
      enum type
      decimal target_value
      string currency_code
      boolean achieved
      timestamptz achieved_at
      int sort_order
      timestamptz created_at
      timestamptz updated_at
    }

    AUDIT_LOG {
      uuid id PK
      uuid actor_user_id FK
      string action
      string target_type
      string target_id
      string request_id
      inet ip_address
      jsonb metadata
      timestamptz created_at
    }
```

---

# 3. Entity Notes

## USER
Represents both normal users and administrators.

Recommended enums:

```text
Role:
- USER
- ADMIN

UserStatus:
- ACTIVE
- DISABLED
```

Do not hard-delete users for routine beta administration.

Future B2B note:
A tenant/organization relationship can later be introduced without changing the user's core identity.

---

# 4. SESSION
Represents authenticated sessions or refresh-token records.

Recommended principles:
- store token hash, never raw refresh token,
- allow revocation,
- retain creation/expiry timestamps,
- IP/user agent are operational/security metadata and should be retention-conscious.

If a different secure session library owns session persistence, adapt this entity rather than duplicating it.

---

# 5. RETIREMENT_PLAN
One primary plan per user in v1.

Database constraint:
- unique `user_id`.

Important fields:
- money values use NUMERIC/Decimal,
- rates are stored as decimal ratios or clearly documented percentages,
- currency code defaults to THB,
- expense breakdown is optional JSONB for v1 simplicity.

Potential future normalization:
`PLAN_ASSET_ACCOUNT` and `RETIREMENT_EXPENSE_ITEM` can later replace aggregate/JSON representations without changing the plan identity.

---

# 6. CALCULATION_RESULT
Represents a calculated result from a saved plan.

Why keep results separate from plan:
- calculation version traceability,
- ability to compare results across formula versions,
- audit/debug capability,
- avoid filling the plan row with derived data.

Recommended lifecycle:
- append result after significant recalculation,
- latest result selected by timestamp or explicit relation later,
- retain calculation version.

Projection series may be JSONB in v1 because it is derived time-series output and is normally consumed as one object.

If analytical needs grow, projection points can later be normalized or moved to object storage.

---

# 7. RETIREMENT_SNAPSHOT
Immutable trend record designed for historical goal tracking.

It intentionally duplicates key result values because historical charts should not change when the latest calculation formula changes.

Snapshot includes:
- key input assumptions,
- key calculated KPIs,
- calculation version.

Snapshots should never be rewritten to a new calculation version.

---

# 8. SCENARIO
Represents a user's comparison scenario.

v1 may choose either:
1. persist scenarios, or
2. treat them as transient API requests.

This model supports persistence without forcing it in the first UI.

`overrides` JSONB should contain only differences from the primary plan, such as:
- retirementAge,
- monthlyContribution,
- expectedReturn,
- monthlyRetirementExpense.

This avoids copying the entire plan into every scenario.

---

# 9. SCENARIO_RESULT
Optional persisted calculation output for scenarios.

If scenarios are transient in v1, this table may be deferred.

If persisted:
- every result carries calculation version,
- result summary is immutable,
- projection series is derived data.

---

# 10. RETIREMENT_GOAL
One primary retirement goal per user in v1.

Recommended uniqueness:
- unique user_id,
- unique retirement_plan_id.

This explicit entity allows future:
- goal naming,
- goal status,
- advisor workflows,
- multiple goals after v1.

---

# 11. GOAL_MILESTONE
Tracks measurable sub-goals.

Recommended milestone enum:

```text
MilestoneType:
- SAVINGS_AMOUNT
- READINESS_SCORE
- FUNDING_GAP_MAX
```

Interpretation:
- SAVINGS_AMOUNT achieved when current savings >= target
- READINESS_SCORE achieved when score >= target
- FUNDING_GAP_MAX achieved when funding gap <= target

For score-based milestones, currency_code may be null in the concrete schema.

A future typed milestone schema may replace generic `target_value`.

---

# 12. AUDIT_LOG
Append-only operational/security audit record.

Fields:
- actor,
- action,
- target,
- request ID,
- client IP,
- safe metadata,
- timestamp.

Must not store:
- password,
- raw token,
- cookie,
- authorization header,
- entire financial request payload unless explicitly justified.

Examples of actions:
- AUTH_LOGIN
- AUTH_LOGOUT
- USER_CREATED
- USER_DISABLED
- USER_ROLE_CHANGED
- RETIREMENT_PLAN_UPDATED
- PRODUCTION_CONFIG_CHANGED

---

# 13. Recommended Indexes

## USER
- unique(email)
- index(status)
- index(role)

## SESSION
- index(user_id)
- index(expires_at)
- unique(token_hash)

## RETIREMENT_PLAN
- unique(user_id)

## CALCULATION_RESULT
- index(retirement_plan_id, created_at desc)
- index(calculation_version)

## RETIREMENT_SNAPSHOT
- index(user_id, created_at desc)
- index(retirement_plan_id, created_at desc)

## SCENARIO
- index(user_id)
- index(retirement_plan_id)
- optional unique(user_id, name)

## GOAL_MILESTONE
- index(retirement_goal_id, sort_order)

## AUDIT_LOG
- index(actor_user_id, created_at desc)
- index(target_type, target_id)
- index(request_id)
- index(created_at desc)

---

# 14. Data Types and Precision

Recommended PostgreSQL patterns:

### Monetary values
Use:
```sql
NUMERIC(20, 2)
```

For calculation snapshots requiring more precision before display, consider:
```sql
NUMERIC(24, 8)
```

Choose one documented convention in the final PostgreSQL schema.

### Rates
Use:
```sql
NUMERIC(12, 8)
```

Store rates as decimal fractions where possible:
- 5% => 0.05

### Scores
Use:
```sql
NUMERIC(6, 3)
```
or integer if final persisted score is intentionally whole-number only.

### Time
Use:
```sql
TIMESTAMPTZ
```

### Currency
Use:
```text
CHAR(3)
```
or VARCHAR(3), constrained to uppercase ISO-style currency code.

---

# 15. Deletion / Retention Rules

Recommended v1 behavior:
- USER: disable, do not routinely delete.
- SESSION: purge/revoke according to retention policy.
- RETIREMENT_PLAN: owned by user; deletion behavior should be explicit before public release.
- CALCULATION_RESULT: retain for traceability within reasonable policy.
- RETIREMENT_SNAPSHOT: immutable unless account deletion policy requires removal.
- AUDIT_LOG: append-only, with defined operational retention later.

A formal privacy/deletion policy is still an open product/legal requirement before broad public launch.

---

# 16. Future Entities Not Required in v1

Potential later entities:
- ORGANIZATION
- ORGANIZATION_MEMBER
- TENANT_BRANDING
- FINANCIAL_ACCOUNT
- ASSET_POSITION
- CONTRIBUTION_SCHEDULE
- EXPENSE_ITEM
- MONTE_CARLO_RUN
- MONTE_CARLO_RESULT
- ADVISOR_CLIENT_RELATIONSHIP
- SUBSCRIPTION
- BILLING_CUSTOMER

Do not add these prematurely unless the corresponding feature enters scope.

---

# 17. Next Translation Step
This logical ER model should next be converted into:
1. PostgreSQL schema/DDL,
2. Prisma schema,
3. OpenAPI request/response contracts.

During that translation, decide:
- whether scenarios/results are persisted in v1,
- exact session persistence approach,
- exact Decimal precision,
- enums vs check constraints,
- snapshot trigger policy,
- whether projection series remains JSONB.
