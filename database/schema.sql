-- Demeter Retirement Planner
-- PostgreSQL schema baseline for v1
-- Generated from docs/ER-DIAGRAM.md and calculation/application requirements.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "citext";

DO $$ BEGIN
  CREATE TYPE user_role AS ENUM ('USER', 'ADMIN');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE user_status AS ENUM ('ACTIVE', 'DISABLED');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE milestone_type AS ENUM ('SAVINGS_AMOUNT', 'READINESS_SCORE', 'FUNDING_GAP_MAX');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email CITEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role user_role NOT NULL DEFAULT 'USER',
  status user_status NOT NULL DEFAULT 'ACTIVE',
  last_login_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS users_status_idx ON users(status);
CREATE INDEX IF NOT EXISTS users_role_idx ON users(role);

CREATE TABLE IF NOT EXISTS sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash TEXT NOT NULL UNIQUE,
  expires_at TIMESTAMPTZ NOT NULL,
  revoked_at TIMESTAMPTZ,
  user_agent TEXT,
  ip_address INET,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS sessions_user_id_idx ON sessions(user_id);
CREATE INDEX IF NOT EXISTS sessions_expires_at_idx ON sessions(expires_at);

CREATE TABLE IF NOT EXISTS retirement_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  current_age INTEGER NOT NULL CHECK (current_age >= 0),
  retirement_age INTEGER NOT NULL,
  life_expectancy INTEGER NOT NULL,
  current_savings NUMERIC(20,2) NOT NULL CHECK (current_savings >= 0),
  monthly_contribution NUMERIC(20,2) NOT NULL CHECK (monthly_contribution >= 0),
  annual_contribution_increase_rate NUMERIC(12,8) NOT NULL DEFAULT 0,
  pre_retirement_return_rate NUMERIC(12,8) NOT NULL,
  post_retirement_return_rate NUMERIC(12,8) NOT NULL,
  inflation_rate NUMERIC(12,8) NOT NULL,
  monthly_retirement_expense_today NUMERIC(20,2) NOT NULL CHECK (monthly_retirement_expense_today >= 0),
  currency_code VARCHAR(3) NOT NULL DEFAULT 'THB' CHECK (currency_code = upper(currency_code) AND char_length(currency_code) = 3),
  expense_breakdown JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT retirement_plan_age_order_chk CHECK (
    retirement_age > current_age AND life_expectancy > retirement_age
  ),
  CONSTRAINT retirement_plan_rate_bounds_chk CHECK (
    annual_contribution_increase_rate > -1
    AND pre_retirement_return_rate > -1
    AND post_retirement_return_rate > -1
    AND inflation_rate > -1
  )
);

CREATE TABLE IF NOT EXISTS calculation_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  retirement_plan_id UUID NOT NULL REFERENCES retirement_plans(id) ON DELETE CASCADE,
  calculation_version TEXT NOT NULL,
  retirement_fund_required NUMERIC(24,8) NOT NULL,
  projected_portfolio_at_retirement NUMERIC(24,8) NOT NULL,
  funding_gap NUMERIC(24,8) NOT NULL DEFAULT 0,
  funding_surplus NUMERIC(24,8) NOT NULL DEFAULT 0,
  required_monthly_contribution NUMERIC(24,8) NOT NULL,
  incremental_monthly_contribution NUMERIC(24,8) NOT NULL,
  readiness_score NUMERIC(6,3) NOT NULL CHECK (readiness_score >= 0 AND readiness_score <= 100),
  financial_health_score NUMERIC(6,3) CHECK (financial_health_score >= 0 AND financial_health_score <= 100),
  readiness_breakdown JSONB NOT NULL DEFAULT '{}'::jsonb,
  financial_health_breakdown JSONB,
  projection_series JSONB NOT NULL,
  depletion_month_index INTEGER CHECK (depletion_month_index IS NULL OR depletion_month_index >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS calculation_results_plan_created_idx
  ON calculation_results(retirement_plan_id, created_at DESC);
CREATE INDEX IF NOT EXISTS calculation_results_version_idx
  ON calculation_results(calculation_version);

CREATE TABLE IF NOT EXISTS retirement_snapshots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  retirement_plan_id UUID NOT NULL REFERENCES retirement_plans(id) ON DELETE CASCADE,
  calculation_version TEXT NOT NULL,
  current_savings NUMERIC(20,2) NOT NULL,
  monthly_contribution NUMERIC(20,2) NOT NULL,
  retirement_fund_required NUMERIC(24,8) NOT NULL,
  projected_portfolio_at_retirement NUMERIC(24,8) NOT NULL,
  funding_gap NUMERIC(24,8) NOT NULL,
  readiness_score NUMERIC(6,3) NOT NULL CHECK (readiness_score >= 0 AND readiness_score <= 100),
  financial_health_score NUMERIC(6,3) CHECK (financial_health_score >= 0 AND financial_health_score <= 100),
  assumptions JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS retirement_snapshots_user_created_idx
  ON retirement_snapshots(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS retirement_snapshots_plan_created_idx
  ON retirement_snapshots(retirement_plan_id, created_at DESC);

CREATE TABLE IF NOT EXISTS scenarios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  retirement_plan_id UUID NOT NULL REFERENCES retirement_plans(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  overrides JSONB NOT NULL DEFAULT '{}'::jsonb,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT scenarios_name_nonempty_chk CHECK (btrim(name) <> '')
);

CREATE INDEX IF NOT EXISTS scenarios_user_idx ON scenarios(user_id);
CREATE INDEX IF NOT EXISTS scenarios_plan_idx ON scenarios(retirement_plan_id);
CREATE UNIQUE INDEX IF NOT EXISTS scenarios_user_name_uq ON scenarios(user_id, lower(name));

CREATE TABLE IF NOT EXISTS scenario_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scenario_id UUID NOT NULL REFERENCES scenarios(id) ON DELETE CASCADE,
  calculation_version TEXT NOT NULL,
  result_summary JSONB NOT NULL,
  projection_series JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS scenario_results_scenario_created_idx
  ON scenario_results(scenario_id, created_at DESC);

CREATE TABLE IF NOT EXISTS retirement_goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  retirement_plan_id UUID NOT NULL UNIQUE REFERENCES retirement_plans(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'ACTIVE',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS goal_milestones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  retirement_goal_id UUID NOT NULL REFERENCES retirement_goals(id) ON DELETE CASCADE,
  type milestone_type NOT NULL,
  target_value NUMERIC(24,8) NOT NULL,
  currency_code VARCHAR(3),
  achieved BOOLEAN NOT NULL DEFAULT FALSE,
  achieved_at TIMESTAMPTZ,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT goal_milestone_currency_chk CHECK (
    currency_code IS NULL OR (currency_code = upper(currency_code) AND char_length(currency_code) = 3)
  ),
  CONSTRAINT goal_milestone_achieved_time_chk CHECK (
    (achieved = FALSE AND achieved_at IS NULL) OR achieved = TRUE
  )
);

CREATE INDEX IF NOT EXISTS goal_milestones_goal_order_idx
  ON goal_milestones(retirement_goal_id, sort_order);

CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  target_type TEXT,
  target_id TEXT,
  request_id TEXT,
  ip_address INET,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS audit_logs_actor_created_idx
  ON audit_logs(actor_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS audit_logs_target_idx
  ON audit_logs(target_type, target_id);
CREATE INDEX IF NOT EXISTS audit_logs_request_idx
  ON audit_logs(request_id);
CREATE INDEX IF NOT EXISTS audit_logs_created_idx
  ON audit_logs(created_at DESC);

-- Generic updated_at trigger for mutable tables.
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS users_set_updated_at ON users;
CREATE TRIGGER users_set_updated_at
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS retirement_plans_set_updated_at ON retirement_plans;
CREATE TRIGGER retirement_plans_set_updated_at
BEFORE UPDATE ON retirement_plans
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS scenarios_set_updated_at ON scenarios;
CREATE TRIGGER scenarios_set_updated_at
BEFORE UPDATE ON scenarios
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS retirement_goals_set_updated_at ON retirement_goals;
CREATE TRIGGER retirement_goals_set_updated_at
BEFORE UPDATE ON retirement_goals
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS goal_milestones_set_updated_at ON goal_milestones;
CREATE TRIGGER goal_milestones_set_updated_at
BEFORE UPDATE ON goal_milestones
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

COMMENT ON TABLE retirement_plans IS 'Primary v1 retirement plan; one per user.';
COMMENT ON TABLE calculation_results IS 'Immutable derived results tagged by calculation version.';
COMMENT ON TABLE retirement_snapshots IS 'Immutable trend snapshots preserving historical results and assumptions.';
COMMENT ON TABLE scenarios IS 'Persisted scenario overrides relative to the primary retirement plan.';
COMMENT ON TABLE audit_logs IS 'Append-only security/administrative audit events; exclude secrets and sensitive payload dumps.';
