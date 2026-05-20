# APEX CI/CD Demo on GitHub

> A working blueprint that shows how the **GitHub platform** delivers full CI/CD for an **Oracle APEX** application — from idea to production, with gates, traceability, and a recovery story.

[![validate](https://github.com/AlahmadiQ8/apex/actions/workflows/validate.yml/badge.svg)](https://github.com/AlahmadiQ8/apex/actions/workflows/validate.yml)
[![deploy](https://github.com/AlahmadiQ8/apex/actions/workflows/deploy.yml/badge.svg)](https://github.com/AlahmadiQ8/apex/actions/workflows/deploy.yml)

---

## What this repo demonstrates

A 15-minute customer demo that walks an APEX change from **issue → branch → pull request → merge → release → production**, with a recovery story when something breaks. The technical pipeline uses **SQLcl + GitHub Actions** to deploy schema changes and APEX application updates to **Oracle Autonomous Database**.

**GitHub platform surfaces shown:**

| Surface | What it does in this demo |
|---|---|
| **Issues** | Stakeholders open feature requests; engineers pick them up |
| **Pull Requests** | Code review, branch protection, status checks, deploy plan comment |
| **Actions** | `validate.yml` (PR static checks) + `deploy.yml` (DEV + PROD deploy) |
| **Environments** | `development` (auto-deploy) vs `production` (manual reviewer required) |
| **Secrets** | Encrypted, environment-scoped credentials for ADB wallet + DB user |
| **Releases** | Publishing a Release triggers production deployment |

---

## Repository layout

```
.github/
  workflows/
    validate.yml         # PR static checks + deploy plan comment
    deploy.yml           # main → DEV; release → PROD (gated)
  ISSUE_TEMPLATE/        # feature_request, bug_report
  pull_request_template.md
  CODEOWNERS
apex/
  f100.sql               # APEX app export (placeholder; replace with real export)
  README.md
db/
  install.sql            # master orchestrator
  schema/
    000_schema_migrations.sql
    001_create_feedback.sql
  migrations/
    002_seed_data.sql
    003_add_category.sql # THE DEMO MOMENT
  README.md
scripts/
  deploy.sql             # SQLcl entry point
  verify.sql             # post-deploy smoke
docs/
  RESEARCH.md            # full technical research blueprint
  SETUP.md               # one-time setup (ADB, wallet, secrets, environments)
  DEMO_SCRIPT.md         # 15-minute act-by-act speaker notes
```

---

## Quick start (30 seconds)

If you're here to **run the demo**:

1. Read [`docs/SETUP.md`](docs/SETUP.md) — provision Oracle Autonomous DB Always Free, encode your wallet, configure GitHub Secrets per environment.
2. Read [`docs/DEMO_SCRIPT.md`](docs/DEMO_SCRIPT.md) — 15-minute act-by-act walkthrough.

If you're here to **understand the pipeline**:

- Start at [`docs/RESEARCH.md`](docs/RESEARCH.md) — the full technical blueprint with citations.
- Then read [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml) — the actual deploy pipeline (~150 lines).

---

## The demo in 30 seconds

1. **Stakeholder** opens issue: *"Add 'category' field to feedback form"*.
2. **Developer** branches, adds `db/migrations/003_add_category.sql` and the matching APEX page change, opens a PR.
3. **`validate.yml`** runs on the PR: lints workflows, checks SQL hygiene (`WHENEVER SQLERROR EXIT`), enforces migration ordering, blocks any committed secrets, and posts a deploy-plan PR comment.
4. **Merge → DEV** : `deploy.yml` runs `deploy-dev`, applies migrations, imports the APEX app, verifies.
5. **Tag a Release** (`v1.1.0`) → `deploy-prod` waits for a human reviewer on the `production` environment → approved → applied to PROD.
6. **Rollback** : a bad commit gets caught by the pipeline; `git revert` PR restores green.

---

## Local development (optional)

Schema migrations are plain SQLcl. To smoke-test locally without GitHub:

```bash
# 1. Install SQLcl (https://www.oracle.com/database/sqldeveloper/technologies/sqlcl/download/)
# 2. Place your wallet zip at ./wallet/ (unzipped), chmod 600 ./wallet/*
# 3. export TNS_ADMIN=$PWD/wallet
# 4. sql USER/PASS@yourdb_high
SQL> @scripts/deploy.sql
SQL> @scripts/verify.sql
SQL> apex import -applicationid 100 -workspacename DEMO -file apex/f100.sql
```

---

## What is NOT in this demo

The following are intentionally out of scope to keep the demo at 15 minutes. See [`docs/RESEARCH.md`](docs/RESEARCH.md) for production-grade upgrade paths.

- Liquibase migrations
- Codespaces / devcontainer
- Multi-workspace / per-PR ADB clones
- utPLSQL / Cypress tests
- Static security scanning (APEX-SERT)
- Self-hosted runners

---

## License

This is a demo repository. No production support. Adapt freely.
