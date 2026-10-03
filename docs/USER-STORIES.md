# Demeter Retirement Planner — User Stories

## 1. Purpose
This document translates the PRD and functional requirements into implementable user stories for the Demeter v1 internal beta.

Stories are grouped by epic and include concise acceptance criteria. Priorities use:
- P0 — required for internal beta
- P1 — important for v1 completeness
- P2 — valuable but may follow initial beta

---

# Epic A — Authentication and Account Access

## US-AUTH-001 — Register an account
**Priority:** P0

As a new user, I want to create an account with email and password so that I can save and revisit my retirement plan.

### Acceptance Criteria
- User can submit email and password.
- Email is validated and normalized.
- Duplicate active email is rejected.
- Password is never stored in plaintext.
- Successful registration creates a USER account.
- User receives an authenticated session or is directed to login according to the chosen auth flow.
- Audit event is recorded without storing password data.

## US-AUTH-002 — Log in
**Priority:** P0

As a registered user, I want to log in securely so that I can access my retirement planning data.

### Acceptance Criteria
- Valid credentials authenticate successfully.
- Invalid credentials return a generic error.
- Disabled accounts cannot authenticate.
- Successful login establishes an authenticated session.
- Login success/failure is logged safely.

## US-AUTH-003 — Log out
**Priority:** P0

As an authenticated user, I want to log out so that my session is no longer usable.

### Acceptance Criteria
- Active session/refresh token is invalidated as applicable.
- User is returned to an unauthenticated state.
- Logout event is audit logged.

---

# Epic B — Retirement Plan Setup

## US-PLAN-001 — Create my retirement plan
**Priority:** P0

As a user, I want to enter my retirement assumptions so that Demeter can calculate my retirement outlook.

### Required Inputs
- Current Age
- Retirement Age
- Life Expectancy
- Current Savings
- Monthly Contribution
- Annual Contribution Increase
- Pre-retirement Expected Return
- Post-retirement Expected Return
- Expected Inflation
- Monthly Expense After Retirement
- Currency code, default THB

### Acceptance Criteria
- Required inputs are validated client-side and server-side.
- Invalid age ordering is rejected.
- Unsupported rates are rejected.
- Saved plan becomes the user's primary retirement plan.
- Saving the plan triggers deterministic calculations.
- Calculation version is stored with derived results/snapshot.

## US-PLAN-002 — Edit my assumptions
**Priority:** P0

As a user, I want to edit my retirement assumptions so that I can keep my plan current.

### Acceptance Criteria
- User can modify all editable plan inputs.
- Saving changes recalculates outputs.
- Significant saved changes create a historical snapshot.
- Previous snapshots remain unchanged.

## US-PLAN-003 — Enter retirement expense in today's money
**Priority:** P0

As a user, I want to enter expected retirement spending in today's money so that I do not need to manually calculate future inflation.

### Acceptance Criteria
- UI clearly states that expense is entered in today's value.
- System inflates the value to retirement age.
- Calculated future expense is explainable in the results.

## US-PLAN-004 — Add optional expense categories
**Priority:** P1

As a user, I want to break my retirement expense into categories so that I can understand my assumptions in more detail.

### Acceptance Criteria
- Total expense remains the primary calculation input.
- Optional categories can be entered and summed.
- Categories include housing, food, healthcare, travel, insurance, other.
- Category detail does not change the calculation unless the total changes.

---

# Epic C — Retirement Calculations

## US-CALC-001 — See required retirement fund
**Priority:** P0

As a user, I want to know how much money I need at retirement so that I understand my target.

### Acceptance Criteria
- Uses post-retirement drawdown model.
- Accounts for post-retirement investment return.
- Accounts for inflation-adjusted monthly withdrawals.
- Runs through life expectancy.
- Uses the documented calculation version.

## US-CALC-002 — See projected portfolio at retirement
**Priority:** P0

As a user, I want to know how large my portfolio may be at retirement based on my current plan.

### Acceptance Criteria
- Starts from current savings.
- Applies monthly investment growth.
- Adds monthly contributions.
- Applies annual contribution step-up.
- Uses pre-retirement expected return.

## US-CALC-003 — See funding gap or surplus
**Priority:** P0

As a user, I want to know whether my projected retirement portfolio is above or below the required amount.

### Acceptance Criteria
- Shows surplus when projected portfolio >= required fund.
- Shows funding gap when projected portfolio < required fund.
- Values are shown in plan currency.

## US-CALC-004 — See required monthly savings
**Priority:** P0

As a user, I want to know the monthly contribution required to close my retirement funding target.

### Acceptance Criteria
- Required starting monthly contribution is calculated.
- Annual contribution increase assumption is respected.
- Additional amount above current contribution is displayed.
- If current contribution is sufficient, incremental required contribution is zero.

---

# Epic D — Retirement Dashboard

## US-DASH-001 — View retirement KPIs
**Priority:** P0

As a user, I want a concise dashboard showing my key retirement metrics so that I can immediately understand my status.

### Acceptance Criteria
Dashboard prominently displays:
- Retirement Readiness Score
- Retirement Fund Required
- Projected Portfolio at Retirement
- Funding Gap / Surplus
- Required Monthly Contribution

## US-DASH-002 — Understand KPI meaning
**Priority:** P0

As a user, I want explanations for important metrics so that I can interpret the results correctly.

### Acceptance Criteria
- Each major KPI has an accessible explanation.
- Assumptions are easy to review.
- Projection surfaces include non-guarantee language.

## US-DASH-003 — View lifetime projection
**Priority:** P0

As a user, I want to see portfolio value from today through life expectancy so that I understand both accumulation and drawdown.

### Acceptance Criteria
- Chart spans current age through life expectancy.
- Accumulation and retirement phases are visually distinct.
- Retirement age is marked.
- Depletion is visible if portfolio reaches zero before life expectancy.

---

# Epic E — Retirement Readiness Score

## US-RRS-001 — View readiness score
**Priority:** P0

As a user, I want a 0–100 readiness score so that I have a simple summary of my retirement preparedness.

### Acceptance Criteria
- Score is bounded 0–100.
- Score is deterministic for the same inputs and calculation version.
- Score does not claim guaranteed outcomes.

## US-RRS-002 — Understand score breakdown
**Priority:** P0

As a user, I want to know why my readiness score is high or low so that I can act on it.

### Acceptance Criteria
- Component scores are displayed.
- Plain-language explanation is provided.
- At least funding adequacy and contribution adequacy are visible.
- Calculation version is traceable.

---

# Epic F — Financial Health Score

## US-FHS-001 — View financial health score
**Priority:** P1

As a user, I want a separate financial health indicator so that I can understand broader planning quality beyond retirement readiness.

### Acceptance Criteria
- Score is separate from Retirement Readiness Score.
- Dimensions are explicitly shown.
- System only scores dimensions supported by data collected by Demeter.
- UI does not imply it evaluates debt, liquidity, insurance, diversification, or emergency reserves unless those inputs exist.

---

# Epic G — Scenario Comparison

## US-SCEN-001 — Create a comparison scenario
**Priority:** P0

As a user, I want to adjust key assumptions in a temporary scenario so that I can see how changes affect retirement outcomes.

### Acceptance Criteria
- User can override retirement age.
- User can override monthly contribution.
- User can override expected return.
- User can override monthly retirement expense.
- Scenario does not overwrite primary plan unless user explicitly applies a supported action.

## US-SCEN-002 — Compare scenarios side-by-side
**Priority:** P0

As a user, I want to compare 2–3 scenarios so that I can understand tradeoffs.

### Acceptance Criteria
- Each scenario shows the same KPI structure.
- Projection charts can be compared.
- Funding gap/surplus is visible.
- Readiness impact is visible.
- Scenario results use the same calculation engine/version.

---

# Epic H — Goal Tracking

## US-GOAL-001 — Track one primary retirement goal
**Priority:** P0

As a user, I want one clear retirement goal so that the application remains focused.

### Acceptance Criteria
- Exactly one primary retirement goal is supported in v1.
- Goal references the primary retirement plan.
- Goal status is visible on dashboard.

## US-GOAL-002 — Track milestones
**Priority:** P1

As a user, I want milestones under my retirement goal so that I can recognize progress.

### Acceptance Criteria
Supported milestone concepts may include:
- savings target,
- readiness score threshold,
- funding gap threshold.

## US-GOAL-003 — View historical progress
**Priority:** P1

As a user, I want to see how my retirement position changes over time so that I can understand progress.

### Acceptance Criteria
- Significant saved plan changes create snapshots.
- Trend views can show current savings.
- Trend views can show readiness score.
- Trend views can show funding gap.
- Trend views can show projected portfolio at retirement.

---

# Epic I — Administration

## US-ADMIN-001 — View users
**Priority:** P0

As an ADMIN, I want to view user accounts so that I can manage the internal beta.

### Acceptance Criteria
- Only ADMIN can access the admin endpoint/page.
- User list does not expose sensitive credential material.

## US-ADMIN-002 — Create a user
**Priority:** P0

As an ADMIN, I want to create a user so that I can provision internal-beta access.

### Acceptance Criteria
- ADMIN can create USER accounts.
- Validation rules match normal registration where applicable.
- Audit event is recorded.

## US-ADMIN-003 — Disable a user
**Priority:** P0

As an ADMIN, I want to disable a user so that I can revoke access.

### Acceptance Criteria
- Disabled user cannot create new sessions.
- Existing session behavior follows the session revocation design.
- Audit event is recorded.

## US-ADMIN-004 — Change role
**Priority:** P1

As an authorized ADMIN, I want to change supported user roles so that administration remains manageable.

### Acceptance Criteria
- Backend authorization is enforced.
- Role changes are audit logged.
- Unsafe self-lockout behavior should be prevented where practical.

---

# Epic J — Operational Reliability

## US-OPS-001 — Verify service health
**Priority:** P0

As an operator, I want liveness and readiness checks so that deployments and monitors can distinguish running processes from healthy services.

### Acceptance Criteria
- API exposes `/health`.
- API exposes `/ready`.
- Readiness checks critical dependencies including PostgreSQL.

## US-OPS-002 — Promote a validated release
**Priority:** P0

As an operator, I want production to run the same immutable artifact validated in staging.

### Acceptance Criteria
- Release is identified by SemVer.
- Production pins immutable image digest.
- Digest matches staging-validated artifact.
- Source commit and build metadata are verified.

## US-OPS-003 — Protect production deploy with backup
**Priority:** P0

As an operator, I want a pre-deploy database backup so that migration/deploy failures have a recovery point.

### Acceptance Criteria
- Backup runs before migration.
- Failed backup blocks production deployment.
- Failure sends Telegram alert.

## US-OPS-004 — Roll back failed deployment
**Priority:** P0

As an operator, I want automatic application rollback when readiness or smoke tests fail so that service can return to a known-good release.

### Acceptance Criteria
- Last known good release is recorded.
- App rollback uses immutable prior artifact.
- Database is not automatically down-migrated.
- Readiness is rerun after rollback.
- Alert is sent.

---

# Epic K — Safety and Trust

## US-TRUST-001 — Review assumptions
**Priority:** P0

As a user, I want to review the assumptions behind my projection so that I know what drives the result.

### Acceptance Criteria
- Return, inflation, retirement age, life expectancy, expense, contribution assumptions are visible.
- Results clearly identify estimates rather than guarantees.

## US-TRUST-002 — Protect sensitive information
**Priority:** P0

As a user, I want my sensitive account and planning data handled safely.

### Acceptance Criteria
- Passwords/tokens/cookies are never written to application logs.
- Access logs redact sensitive headers and payloads.
- Production secrets are server-side only.
- PostgreSQL is not exposed publicly.
