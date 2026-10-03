# Demeter Retirement Planner — User Flows

## 1. Purpose
This document defines the primary v1 user and operator journeys. Mermaid diagrams are included so the flows can be rendered directly in GitHub-compatible documentation tools.

---

# 2. New User Onboarding Flow

```mermaid
flowchart TD
    A[Landing / Login] --> B{Has account?}
    B -- No --> C[Register email + password]
    C --> D[Account created]
    B -- Yes --> E[Login]
    D --> F[Retirement Plan Setup]
    E --> G{Primary plan exists?}
    G -- No --> F
    G -- Yes --> H[Dashboard]

    F --> I[Enter ages]
    I --> J[Enter savings + contribution]
    J --> K[Enter return + inflation assumptions]
    K --> L[Enter retirement expense in today's money]
    L --> M[Review assumptions]
    M --> N[Save plan]
    N --> O[Run deterministic calculation]
    O --> H
```

## Success outcome
User reaches the dashboard with a saved primary retirement plan and calculated KPIs.

---

# 3. Login Flow

```mermaid
flowchart TD
    A[Login page] --> B[Submit email + password]
    B --> C{Credentials valid?}
    C -- No --> D[Generic login error]
    D --> A
    C -- Yes --> E{Account disabled?}
    E -- Yes --> F[Reject access]
    E -- No --> G[Create authenticated session]
    G --> H[Audit login]
    H --> I[Dashboard]
```

---

# 4. Create / Edit Retirement Plan Flow

```mermaid
flowchart TD
    A[Plan page] --> B[Edit assumptions]
    B --> C[Client validation]
    C --> D{Valid?}
    D -- No --> E[Show field errors]
    E --> B
    D -- Yes --> F[Submit to API]
    F --> G[Server validation]
    G --> H{Valid?}
    H -- No --> I[Return validation errors]
    I --> B
    H -- Yes --> J[Persist plan]
    J --> K[Run deterministic engine]
    K --> L[Persist result + calculation version]
    L --> M[Create historical snapshot]
    M --> N[Return updated KPIs + projection]
    N --> O[Dashboard]
```

---

# 5. Dashboard Flow

```mermaid
flowchart TD
    A[Dashboard load] --> B[Fetch primary plan]
    B --> C[Fetch latest calculated result]
    C --> D[Display five core KPIs]
    D --> E[Display projection chart]
    D --> F[Display readiness breakdown]
    D --> G[Display financial health score]
    D --> H[Display goal + milestones]
    D --> I[Display historical trend summary]

    E --> J[User reviews assumptions]
    F --> K[User sees improvement drivers]
    D --> L[Open scenario comparison]
    D --> M[Edit primary plan]
```

---

# 6. Scenario Comparison Flow

```mermaid
flowchart TD
    A[Scenario Comparison] --> B[Load primary plan as baseline]
    B --> C[Create Scenario A]
    C --> D[Override selected variables]
    D --> E[Run calculation engine]
    E --> F[Create Scenario B / C]
    F --> G[Run each scenario]
    G --> H[Render side-by-side KPI comparison]
    H --> I[Render projection comparison]
    I --> J{User wants to change assumptions?}
    J -- Yes --> D
    J -- No --> K[Exit comparison]
```

## v1 scenario override fields
- Retirement Age
- Monthly Contribution
- Expected Return
- Monthly Expense After Retirement

Scenario calculations never silently overwrite the primary plan.

---

# 7. Goal Tracking Flow

```mermaid
flowchart TD
    A[Primary retirement goal] --> B[View current status]
    B --> C[View milestones]
    B --> D[View historical trends]
    C --> E{Milestone achieved?}
    E -- Yes --> F[Show achieved state]
    E -- No --> G[Show progress remaining]
    D --> H[Compare snapshots over time]
```

---

# 8. Retirement Projection Flow

```mermaid
flowchart LR
    A[Current Age] --> B[Accumulation Phase]
    B --> C[Retirement Age]
    C --> D[Drawdown Phase]
    D --> E[Life Expectancy]

    B -. monthly return + contribution .-> B
    D -. monthly return - inflation-adjusted withdrawal .-> D
```

The chart should render a continuous timeline while visually separating accumulation and drawdown phases.

---

# 9. Portfolio Depletion Flow

```mermaid
flowchart TD
    A[Run retirement drawdown] --> B{Balance remains above zero?}
    B -- Yes --> C[Continue monthly projection]
    C --> D{Reached life expectancy?}
    D -- No --> B
    D -- Yes --> E[Projection complete]

    B -- No --> F[Record depletion month + age]
    F --> G[Clamp displayed balance to zero]
    G --> H[Show depletion warning in results]
```

---

# 10. Admin User Management Flow

```mermaid
flowchart TD
    A[Admin login] --> B[Open /admin]
    B --> C{ADMIN role verified by backend?}
    C -- No --> D[403 Forbidden]
    C -- Yes --> E[User management]
    E --> F[Create user]
    E --> G[Disable user]
    E --> H[Change role]
    F --> I[Audit event]
    G --> I
    H --> I
```

---

# 11. Production Release Flow

```mermaid
flowchart TD
    A[Merge/push to main] --> B[CI build + test]
    B --> C{CI passed?}
    C -- No --> D[Stop]
    C -- Yes --> E[Publish immutable GHCR images]
    E --> F[Auto-deploy same digest to staging]
    F --> G[Staging readiness + validation]
    G --> H{Ready for release?}
    H -- No --> I[Fix on main]
    I --> A

    H -- Yes --> J[Create SemVer release tag]
    J --> K[Production preflight]
    K --> L[Verify digest + commit + build metadata]
    L --> M[Pre-deploy PostgreSQL backup]
    M --> N{Backup success?}
    N -- No --> O[Block deploy + Telegram alert]
    N -- Yes --> P[Run reviewed DB migration]
    P --> Q[Deploy immutable images]
    Q --> R[/ready check]
    R --> S{Ready?}
    S -- No --> T[Rollback to last known good]
    S -- Yes --> U[Automated production smoke test]
    U --> V{Smoke passes?}
    V -- No --> T
    V -- Yes --> W[Mark release last known good]
    W --> X[Record release metadata]
    X --> Y[Deployment complete]
    T --> Z[Recheck readiness + alert]
```

---

# 12. Backup Failure Flow

```mermaid
flowchart TD
    A[Nightly or pre-deploy backup] --> B[Run pg backup]
    B --> C{Backup success?}
    C -- Yes --> D[Store on NAS / separate host]
    D --> E[Apply 30-day retention]
    C -- No --> F[Record failure]
    F --> G[Send Telegram alert]
    G --> H{Pre-deploy backup?}
    H -- Yes --> I[Block production deploy]
    H -- No --> J[Await operator remediation]
```

---

# 13. Navigation Map

```mermaid
flowchart TD
    A[Public] --> B[Login]
    A --> C[Register]

    B --> D[Authenticated App]
    C --> D

    D --> E[Dashboard]
    D --> F[Retirement Plan]
    D --> G[Scenario Comparison]
    D --> H[Goal Tracking]
    D --> I[Account / Settings]

    D --> J{ADMIN?}
    J -- Yes --> K[Admin]
    J -- No --> E

    K --> L[User Management]
    K --> M[Operational / Audit Views]
```
