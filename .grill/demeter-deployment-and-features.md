# Demeter Grill Decision Log

## Intent
Build and deploy **Demeter Retirement Planner** as a production-ready retirement planning platform. Start with a private/internal beta that is technically production-grade, then grow toward a sellable B2C product with future B2B/white-label capability.

The first release should prioritize:
- a clear retirement planning experience,
- explainable deterministic calculations,
- safe production operations,
- a deployment model that can evolve without re-architecting the entire system.

## Constraints
- Frontend: Next.js, TypeScript, TailwindCSS, shadcn/ui, Recharts.
- Backend: NestJS, PostgreSQL, Prisma.
- Development happens only on `nizki-demeter` (`10.10.110.75`).
- `inwjud` (`10.10.110.72`) is a relay/control/jump host only; never use it as the Demeter development host.
- Production runs on a separate VM from dev/staging.
- Initial production environment is on-prem/homelab.
- Single-VM Docker Compose deployment is acceptable for phase 1.
- Cloudflare Tunnel is the only public ingress. No direct Internet exposure of 80/443 and no public fallback.
- Production PostgreSQL must not be exposed publicly.
- Production runtime secrets stay on the production server and are not stored in GitHub.
- Expected general downtime tolerance: several hours.
- Target RPO: <= 24 hours.
- Target RTO: <= 4 hours.
- OS/package patching is manual in a monthly maintenance window.
- Initial financial data scope is intentionally limited: account profile and retirement-planning inputs only. No bank/broker aggregation, transaction history, card storage, or bank account numbers in v1.
- v1 default currency is THB.

## Key decisions

### Product and feature scope

#### Retirement Dashboard
The dashboard must surface these five core KPIs:
1. Retirement Readiness Score
2. Retirement Fund Required
3. Projected Portfolio at Retirement
4. Funding Gap / Surplus
5. Required Monthly Contribution

#### Retirement Readiness Score
- Score range: 0-100.
- Must include a breakdown and explanation of the factors driving the score.
- Factors should include concepts such as savings adequacy, contribution rate, retirement horizon, projected shortfall, and sensitivity to return/inflation assumptions.
- The score must be explainable rather than a black-box number.

#### Financial Health Score
- Separate from Retirement Readiness Score.
- Retirement Readiness measures retirement-specific preparedness.
- Financial Health represents broader financial condition/behavior.
- The two scores must not be collapsed into a single metric.

#### Retirement Fund Required
- Use a retirement drawdown model rather than simple expense x years.
- The retirement portfolio remains invested after retirement.
- Retirement-period projections account for post-retirement return, inflation, withdrawals, and life expectancy.
- Pre-retirement expected return and post-retirement expected return are separate assumptions.

#### Retirement expenses
- Monthly Expense After Retirement is entered in today's money.
- The application inflates that value automatically to retirement age.
- Default UX uses one total monthly expense value.
- Optional category breakdown may include housing, food, healthcare, travel, insurance, and other expenses.

#### Current savings
- v1 accepts Current Savings as one aggregate value.
- The data model should remain extensible to multiple accounts/assets later, such as cash, mutual funds, provident funds, RMF/SSF, and brokerage accounts.

#### Contributions
- User enters current Monthly Contribution.
- Annual Contribution Increase is a percentage step-up applied once per year until retirement.
- The projection engine must model this increasing contribution schedule.

#### Funding gap and required savings
When a funding gap exists, show:
- total monthly savings required to reach the retirement target, and
- incremental monthly contribution required above the user's current contribution.

Example UX concept:
- current: THB 15,000/month
- required: THB 22,400/month
- increase needed: THB 7,400/month

#### Scenario Comparison
v1 compares 2-3 scenarios side-by-side.
Primary scenario variables:
- Retirement Age
- Monthly Contribution
- Expected Return
- Monthly Expense After Retirement

Comparison must show KPI impact and projection chart differences.

#### Goal Tracking
- One Primary Retirement Goal in v1.
- Support milestones under the primary goal rather than multiple independent retirement goals.
- Example milestones: savings reaches a threshold, funding gap below a threshold, readiness score reaches a target.
- Store historical snapshots when the user saves significant plan changes.
- Historical snapshots should support trend views for savings, readiness score, funding gap, and projected portfolio.

#### Projection chart
Preferred design direction:
- one continuous projection from current age through life expectancy,
- visually distinguish accumulation and retirement/drawdown phases,
- clearly mark Retirement Age.

This was the active chart direction when feature grilling ended; detailed chart UX remains an implementation/design decision.

#### Monte Carlo
- v1 uses deterministic projections.
- Architecture must be Monte Carlo-ready.
- Calculation engine should be modular, assumptions should be versionable, and simulation interfaces/results should be addable later without rewriting the core planner.
- No Monte Carlo simulation UI is required in v1.

#### Currency
- THB is the default and only required active currency for v1.
- Persist ISO-style currency code in the data model so true multi-currency support can be added later without a schema redesign.

### Authentication and administration
- Local email/password authentication from the internal beta.
- Support register, login, logout, password hashing, sessions/refresh tokens.
- Email verification and forgot-password may be deferred if no mail service exists yet.
- Roles: USER and ADMIN.
- Admin functionality lives in the same application under an admin area such as `/admin`.
- Backend authorization guards are mandatory on admin endpoints; UI hiding alone is insufficient.
- Admin can create and disable users.
- Basic audit logging starts in phase 1.

Audit-worthy actions include:
- login/logout,
- create/disable user,
- role changes,
- deployment-sensitive config changes,
- important data changes.

Audit records should include actor, action, target, timestamp, request ID, and non-secret metadata.

### Production topology
Initial production topology on one dedicated production VM:
- `web`
- `api`
- `postgres`
- `reverse-proxy`
- optional backup/monitoring sidecars

Rules:
- production is separate from dev/staging,
- PostgreSQL is not exposed outside the host,
- secrets, volumes, networks, and config should be structured so later migration to managed services/Kubernetes is possible,
- zero downtime is not required in phase 1,
- 1-3 minutes of deploy downtime is acceptable.

### Ingress and domains
- Cloudflare Tunnel is the only public ingress.
- No direct public 80/443 ingress.
- No public fallback when the tunnel fails; recovery is through LAN/VPN administration.
- An internal reverse proxy still sits in front of web/API.
- Production hostnames:
  - `app.<domain>`
  - `api.<domain>`
- Staging hostnames:
  - `staging-app.<domain>`
  - `staging-api.<domain>`
- Exact real domain remains to be supplied.
- Reverse-proxy product selection is not fully locked; Caddy was recommended.

### Staging
- `nizki-demeter` / `10.10.110.75` is dev/staging, never production.
- Staging should closely rehearse production topology and deployment behavior.
- Staging has its own PostgreSQL instance/volume, secrets, domain, seed data, and persistence.
- Never copy raw production data directly to staging; use fixtures or anonymized data.
- GitHub Actions may have a staging-only deploy SSH key.
- GitHub must not hold production deployment credentials.

### CI/CD and release model
- CI runs automatically on push/PR.
- `main` automatically deploys to staging.
- Production promotion is driven by SemVer release tags such as `v0.1.0`, `v0.1.1`, `v0.2.0`.
- Web and API share the same release version.
- CI builds/tests/publishes immutable container images to private GHCR.
- Build once, promote the exact same image digest from staging to production.
- Never rebuild a production release from the tag.
- Production deploy uses SemVer for human readability and pins the actual immutable digest.
- Verify image digest, source commit, and CI build metadata before production deploy.
- Image signing with Cosign/Sigstore is deferred but architecture/metadata should not prevent adding it later.
- Production VM holds read-only GHCR pull credentials.
- Production runtime secrets remain server-side.
- Production promotion should remain simple, ideally one admin command.

### Deployment scripts
Infrastructure/configuration is managed in Git, including:
- Docker Compose
- reverse-proxy configuration template
- deploy/rollback scripts
- backup scripts
- `.env.example`
- health-check configuration
- runbooks

Real production secrets and production data must never be committed.

Preferred deploy entrypoint:
`./ops/deploy.sh <release-tag>`

Internal phases should be modular:
1. preflight
2. backup
3. migrate
4. deploy
5. readiness check
6. smoke test
7. rollback when needed

### Configuration management
- Git controls configuration structure and non-secret tracked config.
- Production secrets live only on the production server.
- Runtime config changes must have revision/audit traceability.
- Enforce no-drift for Git-tracked production config.
- If tracked production config differs from the release, block deployment.
- Secrets are the explicit exception to tracked-config no-drift.

### Database migrations
- Production migration is a pre-deploy step, not something executed implicitly at API startup.
- Destructive migrations require explicit review.
- Use expand/contract for destructive schema evolution.
- Do not perform destructive rename/drop/type-change patterns in a single unsafe release.
- Application rollback is preferred over automatic database down-migrations.
- Database recovery strategy is forward-fix.
- API changes should remain backward compatible during rollout/deprecation.

### Health, smoke tests, and rollback
Health endpoints:
- `/health`: process/liveness.
- `/ready`: traffic readiness, including PostgreSQL and critical dependencies.

Deployment success is not determined by container state alone.

After `/ready` succeeds:
- run an automated smoke test covering critical user journeys,
- use a dedicated synthetic non-admin user,
- use only synthetic/test data,
- clean up smoke-test scenario data after the test.

If readiness or smoke testing fails:
- automatically rollback the application to the last known good release,
- do not automatically rollback the database,
- start the previous application image,
- rerun health verification,
- send an alert.

The last known good release is only updated after readiness and smoke tests pass.

### Release metadata
Store for each production deploy:
- release tag,
- Git commit SHA,
- image digest,
- deployment timestamp,
- migration version,
- deploying actor,
- readiness result,
- smoke-test result,
- rollback target/result when applicable.

### Production release checklist
A staging-to-production checklist is mandatory before each release.
At minimum verify:
- CI passed,
- staging readiness passed,
- migration was reviewed,
- destructive migration policy complied with,
- pre-deploy backup is ready/succeeds,
- release tag is correct,
- rollback target is known,
- artifact/digest is the same artifact validated in staging.

### Backup and disaster recovery
- Nightly PostgreSQL backup.
- Additional pre-deploy PostgreSQL backup before every production release.
- Migration/deploy must not continue when the pre-deploy backup fails.
- Backups are stored on NAS or another physical host, not on the production VM alone.
- Daily backup retention: 30 days.
- Phase 1 backups are not encrypted; this is an accepted known risk.
- Access to backup storage should therefore be tightly restricted.
- No automated restore testing in phase 1; this is an accepted known risk.
- Backup failures must generate alerts.
- Target RPO <= 24 hours.
- Target RTO <= 4 hours, but the RTO remains unproven until a restore has actually been rehearsed.

### Observability and alerts
Lean phase-1 observability:
- structured web/API logs,
- Docker log rotation,
- `/health` and `/ready`,
- external uptime monitoring,
- host CPU/RAM/disk monitoring,
- PostgreSQL health checks,
- alerts for outages and disk pressure.

Do not introduce a full Prometheus/Grafana/Loki stack unless later justified.

Alert channel:
- Telegram
- dedicated **Demeter Ops** group

At minimum alert on:
- service/readiness failure,
- nightly backup failure,
- pre-deploy backup failure,
- production deployment failure,
- automatic rollback,
- dangerous disk usage.

### Access logging and edge protection
- Keep client IP in access logs only as needed for security/operations.
- Trust client IP headers only from the Cloudflare path.
- Redact sensitive information.
- Never log password, token, cookie, authorization header, or unnecessary detailed financial data.
- Phase 1 rate limiting is handled at Cloudflare only.
- Backend-specific rate limiting is deferred.

### Server administration
- Production SSH reachable only through LAN/VPN administration path.
- Key-based SSH only.
- Password SSH disabled.
- No public SSH exposure.
- PostgreSQL should not be publicly exposed.

## Surfaced assumptions
- The beta user count and request volume will initially be low enough for one production VM and Docker Compose.
- Users can understand expected return and inflation assumptions when accompanied by sensible defaults/explanations.
- A deterministic model is sufficient for the initial product value proposition.
- Current Savings as a single number is sufficient for v1 onboarding even though future users may require asset/account-level modeling.
- Retirement planning is initially centered on one primary retirement objective rather than multiple competing retirement goals.
- Manual user-entered financial data is sufficient before financial-account integrations are added.
- Cloudflare provides adequate phase-1 edge protection/rate limiting.
- The team accepts operational risk from manual patching, unencrypted backups, and lack of restore rehearsal during the internal-beta phase.
- A dedicated synthetic user can safely exercise critical production flows without touching real-user data.

## Open questions
These are intentionally left for design/implementation rather than continued grilling unless they become blocking:
- Exact domain name.
- Internal reverse proxy choice (Caddy remains the leading recommendation).
- Exact formulas/weights and thresholds for Retirement Readiness Score.
- Exact dimensions/weights for Financial Health Score.
- Default pre-retirement/post-retirement return and inflation assumptions.
- Whether healthcare inflation should eventually be modeled separately.
- Exact projection chart presentation and interaction details.
- Exact session implementation and token lifetime policy.
- Telegram bot/token provisioning and operational ownership.
- Backup storage protocol/path and NAS credentials.
- Exact production VM sizing.
- Exact deployment actor mechanism for the initial production promotion command.
- When to introduce email verification, password reset mail delivery, backend rate limiting, encrypted backups, restore drills, image signing, and richer observability.

## Out of scope for v1
- Bank/broker account aggregation.
- Transaction ingestion/history.
- Card/payment credential storage.
- Full multi-account portfolio aggregation UI.
- Full multi-currency functionality.
- Live Monte Carlo simulations in the product UI.
- Multiple independent retirement goals.
- Kubernetes.
- Zero-downtime/high-availability deployment.
- Full centralized observability stack.
- Automatic OS/package patching.
- Automated database down-migrations.
- Automated restore testing.
- Backup encryption in phase 1.
- Direct public ingress or public fallback around Cloudflare Tunnel.
- Broad public signup until the internal beta is ready to expand.
