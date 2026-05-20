# Setup Guide

One-time setup for the APEX CI/CD demo. Estimated effort: 20–30 minutes.

> **Audience:** the person preparing the demo. The audience never sees this guide.

---

## Prerequisites

- Oracle Cloud account ([sign up free](https://www.oracle.com/cloud/free/))
- `gh` CLI installed and authenticated (`gh auth login`)
- `git` installed
- Admin permission on the repository
- A modern terminal (`base64`, `unzip`, `curl`)

---

## Step 1 — Provision Oracle Autonomous Database (Always Free)

1. Sign in to the [OCI Console](https://cloud.oracle.com).
2. **Menu** → **Oracle Database** → **Autonomous Database** → **Create Autonomous Database**.
3. Settings:
   - Display name: `apex-demo`
   - Database name: `apexdemo`
   - Workload type: **Transaction Processing** (ATP — includes APEX)
   - ✅ **Always Free**
   - Region: pick one close to you
   - Set **ADMIN password** — save it; you'll need it.
4. Click **Create**. Provisioning takes ~3 minutes.

---

## Step 2 — Create the APEX workspace

1. Once the ADB is provisioned, open it → **Tools** tab → **Oracle APEX** → click **Open APEX**.
2. Log in to the **APEX Administration Services** as `ADMIN` (uses the password you just set).
3. **Create Workspace**:
   - Database User: **New schema** → `DEMO_SCHEMA` (set a password)
   - Workspace name: `DEMO`
   - Workspace admin username: `DEMO_ADMIN` (set a password)
4. Click **Create Workspace**.

> The demo workflow expects: workspace **`DEMO`**, application ID **`100`**, parsing schema **`DEMO_SCHEMA`**. If you change any of these, update `apex/f100.sql`, `scripts/deploy.sql`, and `.github/workflows/deploy.yml` to match.

### (Optional) Build a real APEX app to replace the synthetic export

```bash
# Once the schema/migrations have been applied (you can run deploy.yml first
# from main once you complete steps 4–6 below):
#   1. Log in to APEX as DEMO_ADMIN at workspace DEMO.
#   2. App Builder → Create → From a Table → CF_FEEDBACK.
#   3. Force application id 100 (Settings → Application ID).
#   4. Run apex export and commit the file:
sql DEMO_ADMIN/yourpass@apexdemo_high
SQL> cd /path/to/this/repo/apex
SQL> apex export -applicationid 100
SQL> EXIT
git add apex/f100.sql
git commit -m "chore(apex): replace synthetic export with real export"
git push origin main
```

The deploy pipeline picks up the change automatically. No code changes needed.

---

## Step 3 — Download and encode the ADB wallet

1. OCI Console → your ADB → **DB Connection** → **Download Wallet**.
2. Wallet type: **Instance Wallet**. Set a **wallet password** (saved for use; used by sqlnet, not by our scripts).
3. Save the downloaded zip locally as `Wallet_apexdemo.zip`.
4. Base64-encode it (line-wrapping must be disabled):
   ```bash
   # Linux / macOS
   base64 -w 0 Wallet_apexdemo.zip > wallet.b64        # GNU base64
   # macOS without -w 0 support:
   base64 -b 0 -i Wallet_apexdemo.zip -o wallet.b64    # BSD base64
   # If neither flag works, run:  base64 Wallet_apexdemo.zip | tr -d '\n' > wallet.b64
   ```
5. The contents of `wallet.b64` is the value of the `OCI_WALLET_B64` secret. Keep this file out of Git.

---

## Step 4 — Create GitHub Environments

We need two environments: `development` and `production`. The PROD environment requires a human reviewer.

Run from the repo root:

```bash
REPO=AlahmadiQ8/apex                      # adjust if forked
OWNER_LOGIN=AlahmadiQ8                    # the user who will approve PROD deploys

# Get the reviewer's numeric user ID
REVIEWER_ID=$(gh api users/$OWNER_LOGIN --jq .id)

# 1. Create development environment (no protection rules; deploy from main only)
gh api -X PUT "repos/$REPO/environments/development" \
  -F "deployment_branch_policy[protected_branches]=false" \
  -F "deployment_branch_policy[custom_branch_policies]=true"

gh api -X POST "repos/$REPO/environments/development/deployment-branch-policies" \
  -f name='main'

# 2. Create production environment with required reviewer
gh api -X PUT "repos/$REPO/environments/production" \
  -F "reviewers[][type]=User" -F "reviewers[][id]=$REVIEWER_ID" \
  -F "deployment_branch_policy[protected_branches]=false" \
  -F "deployment_branch_policy[custom_branch_policies]=true"

# Allow only refs/tags/v* for production (release-driven)
gh api -X POST "repos/$REPO/environments/production/deployment-branch-policies" \
  -f name='v*' -f type=tag
```

If the API call for branch policies fails, you can set them via the UI:
**Settings → Environments → production → Deployment branches and tags → Selected branches and tags → `v*` (tag)**.

---

## Step 5 — Configure Secrets (per environment)

Each environment needs its own set of four secrets. Use the `gh` CLI:

```bash
REPO=AlahmadiQ8/apex

# Helper: read the base64 wallet file
WALLET_B64=$(cat wallet.b64)

# --- development ---
gh secret set OCI_DB_USERNAME --env development --repo "$REPO" --body "ADMIN"
gh secret set OCI_DB_PASSWORD --env development --repo "$REPO" --body "<dev-password>"
gh secret set OCI_DB_SERVICE  --env development --repo "$REPO" --body "apexdemo_high"
gh secret set OCI_WALLET_B64  --env development --repo "$REPO" --body "$WALLET_B64"

# --- production ---
# Best practice: use a SEPARATE ADB or at minimum a separate workspace/schema
# for production. For a single-instance demo, you can reuse the same values,
# but the environment-gate story is weaker.
gh secret set OCI_DB_USERNAME --env production --repo "$REPO" --body "ADMIN"
gh secret set OCI_DB_PASSWORD --env production --repo "$REPO" --body "<prod-password>"
gh secret set OCI_DB_SERVICE  --env production --repo "$REPO" --body "apexdemo_high"
gh secret set OCI_WALLET_B64  --env production --repo "$REPO" --body "$WALLET_B64"
```

> **Production tip:** Use a least-privilege schema user (not `ADMIN`) for deployment. Grant it `CREATE SESSION`, `CREATE TABLE`, `CREATE PROCEDURE`, plus `apex_administrator_role` for app import.

---

## Step 6 — Configure branch protection on `main`

```bash
REPO=AlahmadiQ8/apex

gh api -X PUT "repos/$REPO/branches/main/protection" \
  -F "required_status_checks[strict]=true" \
  -F "required_status_checks[contexts][]=Static validation" \
  -F "enforce_admins=false" \
  -F "required_pull_request_reviews[required_approving_review_count]=1" \
  -F "required_pull_request_reviews[dismiss_stale_reviews]=true" \
  -F "required_linear_history=true" \
  -F "allow_force_pushes=false" \
  -F "allow_deletions=false" \
  -F "restrictions=null"
```

> **Note:** required status checks can only reference contexts that have run at least once on the branch. Open one throwaway PR first to let `validate.yml` register, then run the command above.

---

## Step 7 — Create the Project board and demo issues

```bash
REPO=AlahmadiQ8/apex
OWNER=AlahmadiQ8

# 1. Create a Project (v2)
PROJECT_NUMBER=$(gh project create --owner "$OWNER" --title "APEX CI/CD Demo" --format json --jq .number)
echo "Project number: $PROJECT_NUMBER"

# 2. Create the "category field" issue (the demo moment)
ISSUE1=$(gh issue create --repo "$REPO" \
  --title "Add 'category' field to feedback form" \
  --label "enhancement" \
  --body "$(cat <<'EOF'
## Summary
We want to categorize incoming feedback so the support team can route it.

## Motivation
Right now all feedback lands in one bucket. Sales wants to filter by topic.

## Proposed change
- **Database:** add a `category` column to `cf_feedback` with values: General, Product, Support, Billing, Other.
- **APEX app:** add the new column to the form and the interactive report.

## Acceptance criteria
- [ ] New rows can specify a category
- [ ] Default is "General"
- [ ] Existing rows are migrated to "General"
EOF
)")

# 3. Create the "investigate failed deploy" issue (rollback narrative)
ISSUE2=$(gh issue create --repo "$REPO" \
  --title "Investigate failed deploy on bad migration" \
  --label "bug" \
  --body "$(cat <<'EOF'
## What happened
A migration with a SQL syntax error was merged to main; `deploy-dev` failed during the schema step.

## What you expected
PR validation or deploy to catch syntax errors before applying.

## Resolution
Reverted via PR #X. Pipeline returned to green on the revert merge.
EOF
)")

# 4. Add both issues to the project
gh project item-add "$PROJECT_NUMBER" --owner "$OWNER" --url "$ISSUE1"
gh project item-add "$PROJECT_NUMBER" --owner "$OWNER" --url "$ISSUE2"
```

---

## Step 8 — Tag the baseline release

```bash
git tag -a v1.0.0 -m "Baseline: schema, seed data, synthetic APEX app"
git push origin v1.0.0

gh release create v1.0.0 \
  --title "v1.0.0 — Baseline" \
  --notes "$(cat <<'EOF'
Baseline release.

- `cf_feedback` table created
- 10 sample rows seeded
- APEX app 100 imported to workspace DEMO
EOF
)"
```

> ⚠️ Publishing this Release will trigger `deploy-prod` and request your reviewer approval. Approve it (or cancel) once and the baseline is set.

---

## Step 9 — First end-to-end run

```bash
# Trigger the DEV deploy manually to confirm everything is wired up:
gh workflow run deploy.yml -f environment=development

# Watch it:
gh run watch
```

Expected outcome:

- ✅ `actions/setup-java` installs JDK 17
- ✅ SQLcl downloads and caches
- ✅ Wallet decodes successfully
- ✅ `scripts/deploy.sql` runs all three migrations
- ✅ `apex import` registers app 100 (may emit warnings about empty page set — expected for the synthetic export)
- ✅ `verify.sql` reports the expected objects

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `Wallet decode fails / TLS handshake error` | Wallet was base64-encoded with line wrapping | Re-encode with `base64 -w 0` (GNU) or `base64 -b 0` (BSD), or pipe through `tr -d '\n'` |
| `Permission denied` on wallet files | Wallet files are world-readable | Workflow already does `chmod 600 wallet/*`; verify it ran |
| `apex import` fails with `ORA-20000: Workspace DEMO not found` | Workspace not created yet | Complete Step 2 |
| `Required status check 'Static validation' is not registered` | `validate.yml` hasn't run on `main` yet | Open a throwaway PR, let it run, then re-apply branch protection |
| Deploy-dev job is skipped on workflow_dispatch | The job's `if:` requires `inputs.environment == 'development'` | Use `gh workflow run deploy.yml -f environment=development` (or 'production') |
| `Job was not approved` on PROD | Reviewer didn't approve | Approve via Actions → run → Review deployments |

---

## Verifying the setup

```bash
# Environments exist
gh api repos/AlahmadiQ8/apex/environments --jq '.environments[].name'
# Expected: development, production

# Secrets exist per environment
gh secret list --env development --repo AlahmadiQ8/apex
gh secret list --env production --repo AlahmadiQ8/apex

# Branch protection is on
gh api repos/AlahmadiQ8/apex/branches/main/protection --jq .required_status_checks.contexts
# Expected: ["Static validation"]
```

You're ready. See [`docs/DEMO_SCRIPT.md`](DEMO_SCRIPT.md) for the 15-minute walkthrough.
