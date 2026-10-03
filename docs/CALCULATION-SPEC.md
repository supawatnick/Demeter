# Demeter Retirement Planner — Calculation Specification

Version: 0.1  
Status: implementation baseline for deterministic v1

## 1. Purpose
This document defines the deterministic calculation behavior used by Demeter v1 so frontend, backend, tests, and future simulation engines use consistent semantics.

## 2. Core Conventions
Unless a later version explicitly changes these rules:

- monetary inputs are expressed in the plan currency, default THB,
- retirement expense input is expressed in today's purchasing power,
- rates are entered as annual nominal percentages,
- calculation timeline uses monthly periods,
- contributions occur at the end of each month,
- investment growth is applied monthly,
- annual contribution step-up occurs after each completed 12-month block,
- retirement begins when the user reaches Retirement Age,
- retirement withdrawals occur monthly,
- life expectancy defines the final modeled age,
- calculations retain high internal precision and round only display values,
- persisted money uses decimal-safe storage,
- deterministic projection results are tagged with a calculation version.

## 3. Input Definitions

Let:
- A0 = current age
- Ar = retirement age
- Al = life expectancy
- S0 = current savings
- C0 = initial monthly contribution
- g = annual contribution increase rate
- r_pre = annual expected return before retirement
- r_post = annual expected return after retirement
- i = annual inflation rate
- E0 = desired monthly expense after retirement in today's money

Derived:
- months_to_retirement = (Ar - A0) * 12
- months_in_retirement = (Al - Ar) * 12

Validation baseline:
- Ar > A0
- Al > Ar
- S0 >= 0
- C0 >= 0
- E0 >= 0
- rates must be inside documented supported bounds.

v1 should reject impossible age orderings rather than silently repair them.

## 4. Monthly Rate Conversion

For annual effective rate r, use:

monthly_rate(r) = (1 + r)^(1/12) - 1

Therefore:
- m_pre = monthly_rate(r_pre)
- m_post = monthly_rate(r_post)
- m_inf = monthly_rate(i)

This avoids the approximation r / 12.

If product requirements later define annual rates as nominal APR-style rates, the calculation version must change.

## 5. Inflation-adjusted Retirement Expense

The user enters E0 in today's money.

Expense at retirement start:

E_ret = E0 * (1 + i)^(Ar - A0)

Equivalent monthly form:

E_ret = E0 * (1 + m_inf)^(months_to_retirement)

The first retirement withdrawal uses E_ret.

Subsequent retirement withdrawals increase monthly with inflation.

For retirement month k, starting at k = 0:

E_k = E_ret * (1 + m_inf)^k

## 6. Pre-retirement Portfolio Projection

Initialize:

B_0 = S0

For each pre-retirement month t = 1..N where N = months_to_retirement:

1. grow beginning balance:
   G_t = B_(t-1) * (1 + m_pre)

2. determine the contribution level for the month:

year_index = floor((t - 1) / 12)

C_t = C0 * (1 + g)^year_index

3. add end-of-month contribution:

B_t = G_t + C_t

Projected Portfolio at Retirement:

P_ret = B_N

This recurrence is the normative implementation because it handles contribution step-ups without closed-form ambiguity.

## 7. Retirement Drawdown Projection

Retirement starts with:

R_0 = P_ret

For each retirement month k = 0..M-1 where M = months_in_retirement:

1. grow portfolio:
   G_k = R_k * (1 + m_post)

2. withdraw inflation-adjusted expense:
   W_k = E_ret * (1 + m_inf)^k

3. end balance:
   R_(k+1) = G_k - W_k

If R_(k+1) falls below zero, the projection shall record portfolio depletion and may clamp chart balance to zero for presentation, while retaining depletion timing as a result.

## 8. Retirement Fund Required

Retirement Fund Required is the capital required at retirement such that the modeled retirement portfolio is approximately exhausted at life expectancy under the selected post-retirement return and inflation assumptions.

The normative calculation is the present value at retirement of the monthly inflation-growing withdrawal stream.

A recurrence/backward-induction implementation is preferred for consistency with edge cases:

Set Required_M = 0.

For k from M-1 down to 0:

Required_k = (Required_(k+1) + W_k) / (1 + m_post)

Retirement Fund Required:

F_req = Required_0

This approach remains valid when post-retirement return is equal to, lower than, or close to inflation and avoids unstable closed-form special cases.

## 9. Funding Gap / Surplus

Funding position at retirement:

Gap = P_ret - F_req

Interpretation:
- Gap >= 0: projected surplus
- Gap < 0: projected shortfall

For display:
- Funding Surplus = max(Gap, 0)
- Funding Gap = max(-Gap, 0)

## 10. Required Monthly Contribution

Goal:
Find the initial monthly contribution C_required such that projected portfolio at retirement equals Retirement Fund Required, while preserving the user's annual contribution increase assumption.

Because contribution growth is stepped annually, v1 should solve this numerically or from a unit-contribution factor.

### Preferred deterministic approach: contribution factor

Run the pre-retirement accumulation recurrence with:
- S0 = 0
- C0 = 1

using the user's r_pre and g.

Let resulting retirement balance be F_contrib.

Separately grow current savings with zero contributions:

S_ret = S0 * (1 + m_pre)^N

Then:

C_required = max((F_req - S_ret) / F_contrib, 0)

If F_contrib <= 0 due to unsupported/extreme assumptions, return a validation/calculation error.

Incremental monthly contribution required:

C_incremental = max(C_required - C0, 0)

If C_required <= C0, the user is already contributing at or above the required starting rate under current assumptions.

## 11. Retirement Readiness Score

### v1 objective
The score should summarize retirement preparedness without pretending to predict certainty.

The score must be explainable and decomposable.

### Recommended v1 components
Initial implementation may use four components totaling 100 points:

1. Funding Adequacy — 50 points
2. Contribution Adequacy — 20 points
3. Time/Horizon Resilience — 15 points
4. Assumption Risk / Sensitivity — 15 points

Exact weights are product-configurable and must be versioned.

### Funding Adequacy
A simple baseline ratio:

funding_ratio = P_ret / F_req

Map funding ratio into a bounded score.

Recommended initial mapping:
- 0.0 -> 0%
- 0.5 -> 40%
- 0.8 -> 70%
- 1.0 -> 100%
- >1.0 remains capped at 100%

Interpolation should be monotonic and documented.

### Contribution Adequacy
If C_required = 0, score 100%.

Otherwise:

contribution_ratio = C0 / C_required

cap to [0,1] for the base component.

### Time/Horizon Resilience
Reward plans with remaining adjustment time, but do not reward delay for its own sake.

This component should be conservative and relatively low-weight. It may consider:
- years to retirement,
- whether monthly contribution changes can still materially close the gap.

### Assumption Risk / Sensitivity
Penalize plans that only succeed under aggressive assumptions.

v1 can approximate this by recalculating a conservative sensitivity case, for example:
- lower pre-retirement return,
- lower post-retirement return,
- higher inflation.

The exact shock values must live in versioned configuration.

### Overall
ReadinessScore =
sum(component_weight * component_score)

Final result:
- clamp to 0..100,
- round for display,
- persist raw component details and calculation version.

Suggested labels:
- 0-39: Needs Attention
- 40-59: Behind Plan
- 60-79: Progressing
- 80-94: On Track
- 95-100: Strong Position

Labels are UX configuration, not mathematical truth.

## 12. Financial Health Score

The current Demeter input set does not include enough information to claim a comprehensive household financial-health assessment.

Therefore v1 must either:
1. explicitly label the score as a retirement-planning financial health score, or
2. expand input collection before making broader claims.

Recommended v1 dimensions based only on available data:
- savings trajectory,
- contribution adequacy,
- retirement funding position,
- assumption conservatism,
- consistency of plan improvement from snapshots.

Do not score debt, emergency funds, insurance adequacy, liquidity, cash flow, or diversification until Demeter collects the required data.

Weights and thresholds must be versioned separately from the Retirement Readiness Score.

## 13. Historical Snapshot Metrics
On significant saved plan changes, store enough values to reconstruct trend charts without rerunning old calculations under newer formulas.

Recommended stored snapshot values:
- timestamp,
- calculation version,
- current savings,
- monthly contribution,
- retirement fund required,
- projected portfolio at retirement,
- funding gap/surplus,
- required monthly contribution,
- readiness score,
- financial health score,
- key assumptions.

## 14. Scenario Calculations
A scenario starts from the primary plan and applies a limited override set.

v1 override fields:
- retirement age,
- monthly contribution,
- expected return,
- monthly retirement expense.

Scenario calculation must:
- not mutate the primary plan,
- run through the same calculation engine,
- return the same KPI schema,
- include calculation version,
- produce projection series for chart comparison.

If only one expected-return override is exposed in scenario UX, v1 should document whether it modifies pre-retirement return only or both pre/post values. Recommended default: modify pre-retirement return only and leave post-retirement return explicit/unchanged.

## 15. Projection Series
The engine should return a normalized time series suitable for Recharts.

Recommended point fields:
- monthIndex,
- ageYears,
- phase: ACCUMULATION | RETIREMENT,
- portfolioBalance,
- contribution,
- withdrawal,
- inflationAdjustedExpense.

The API may downsample for long timelines, but canonical calculation should remain monthly.

## 16. Numerical Precision
Recommended implementation:
- use decimal-safe types for persisted money,
- use a deterministic high-precision decimal library in the calculation engine where practical,
- never use binary floating-point as the authoritative storage format for currency,
- round user-facing THB amounts to whole baht or configured display precision,
- do not repeatedly round intermediate monthly balances.

Tests must define acceptable epsilon/tolerance where non-integer exponentiation is involved.

## 17. Edge Cases

### Very short time to retirement
If months_to_retirement is small, projection still uses the same monthly recurrence.

### Zero investment return
The recurrence must work when return is 0%.

### Negative supported return
If negative returns are allowed by validation, monthly conversion and recurrence must remain mathematically valid as long as annual rate > -100%.

### Return equals inflation
Retirement Fund Required must use backward induction rather than a closed-form formula that divides by return-minus-inflation.

### Portfolio depletion before life expectancy
Return:
- depletion flag,
- estimated depletion month/age,
- zero-clamped chart balance after depletion if desired by UI.

### Funding surplus
Required additional contribution is zero.

### Invalid age relationships
Reject:
- retirement age <= current age,
- life expectancy <= retirement age.

A future product mode may support already-retired users, but it is not part of v1.

## 18. Disclaimer Requirement
Every projection result surface should make clear that:
- projections are estimates,
- investment returns and inflation are assumptions,
- results are not guaranteed,
- Demeter is a planning tool, not a guarantee of retirement outcomes.

Exact legal copy is outside this calculation document.

## 19. Versioning
The calculation engine shall expose a version identifier, e.g.:
- `deterministic-v1`

Any change that can materially alter results for the same saved inputs should create a new calculation version.

Examples:
- rate-conversion convention change,
- contribution timing change,
- score weighting change,
- withdrawal timing change,
- inflation timing change.

## 20. Required Automated Tests
At minimum:
- no-return accumulation,
- positive-return accumulation,
- annual contribution step-up,
- inflation adjustment to retirement,
- zero-return drawdown,
- return equal to inflation,
- funding surplus,
- funding shortfall,
- required contribution solver,
- zero required contribution,
- depletion before life expectancy,
- score clamping 0..100,
- deterministic repeatability,
- scenario isolation from base plan.
