# Demo Script — APEX CI/CD on GitHub Platform

> **Total runtime:** ~15 minutes. **Live moments:** one (PROD approval). Everything else is **pre-staged** to keep the pace tight and avoid live-failure risk.

---

## Before you go on stage

- [ ] Run `validate.yml` and `deploy.yml` end-to-end at least twice on the demo repo
- [ ] Verify `v1.0.0` Release exists and PROD environment has been deployed at least once
- [ ] Pre-open these browser tabs in order:
  1. The repo home page
  2. Issue #1 (*"Add 'category' field"*) on the Project board
  3. Pre-opened PR (`feature/add-category`) showing the diff
  4. Actions tab (filtered to `deploy`)
  5. Settings → Environments → production
  6. Releases tab
  7. The previous failed run + revert PR (pre-recorded segment)
- [ ] Stage these terminal commands in a separate window:
  ```bash
  gh release create v1.1.0 --title "v1.1.0 — Add category field" --generate-notes
  gh run watch
  ```
- [ ] Confirm reviewer (yourself) is signed in and can approve PROD deployments
- [ ] Have the customer's APEX workspace URL bookmarked for the "show it live" moment

---

## Act-by-act walkthrough

### Act 0 · Opening (0:00 – 0:45) — 45 sec

**Show:** Repo home page (`README.md` rendered).

**Say:**
> "Today I'll show how the GitHub platform takes an Oracle APEX change from idea to production in under ten minutes — with full traceability, code review, security gates, and a recovery story. Everything you see is real: a real Oracle Autonomous Database, real GitHub Actions, real APEX import."

**Audience anchor for mixed audience:**
- *Business:* "Same flow your engineering teams already use for modern apps — now applied to Oracle APEX."
- *Technical:* "SQLcl + GitHub Actions. No proprietary tools, no agents on the database side."

---

### Act 1 · The Request (0:45 – 2:00) — 1 min 15 sec

**Show:** Issue #1 ("Add 'category' field to feedback form") on the Project board.

**Say:**
> "Our sales team wants to route customer feedback by topic. A product manager opens an issue, links it to our Project board, assigns it to a developer. **This is traceability act one** — every change starts as a tracked work item."

**Click through:**
- Issue body (acceptance criteria visible)
- Project board: card sitting in "In Progress"

---

### Act 2 · The Pull Request (2:00 – 4:30) — 2 min 30 sec

**Show:** Pre-opened PR `feature/add-category`.

**Say:**
> "Our developer has branched, added the schema migration and the matching APEX page change. They've opened a pull request. Here's what makes this APEX-friendly: **the schema change and the app change ride in the same PR** — they're coupled, and reviewing them together is exactly right."

**Click through:**
1. **Files changed** tab:
   - `db/migrations/003_add_category.sql` — *"plain SQL, idempotent, human-readable"*
   - `apex/f100.sql` — *"the APEX export, version-controlled like any other code"*
2. **Checks** tab → `validate` workflow → click into the run:
   - actionlint passed
   - SQL hygiene: `WHENEVER SQLERROR EXIT` present ✅
   - Migration numbering sequential ✅
   - No wallet files committed ✅
   - No hardcoded passwords ✅
3. Scroll to the **deploy plan PR comment** posted by the bot — read aloud the execution order.

**Say:**
> "This PR comment is auto-generated. The reviewer sees exactly what's going to happen, in order, before approving. **This is the deploy-plan-as-PR-comment pattern** — it's especially valuable when database changes are involved, because order matters."

**Audience anchor:**
- *Business:* "Mandatory review, automated checks, full audit trail of who approved what."
- *Technical:* "Validation is intentionally static — no DB connection in PR-time. Real deploys catch real errors. We frame it honestly."

---

### Act 3 · Merge → DEV (4:30 – 7:00) — 2 min 30 sec  ·  **LIVE MOMENT 1**

**Do:** Click **Merge pull request**.

**Show:** Actions tab → `deploy` workflow auto-triggered.

**Say:**
> "Merge to `main` automatically deploys to the `development` environment. No tickets, no handoffs, no waiting on a DBA. **This is GitHub Environments doing their job.**"

**Click through the running workflow:**
- Setup Java
- Cache restore of SQLcl (note: pinned version, not "latest")
- Wallet decoded from a Secret + `chmod 600`
- `deploy.sql` runs schema → migrations recorded in `schema_migrations` table
- `apex import` runs
- `verify.sql` confirms `cf_feedback.category` exists

**Fallback if slow:** "Let's switch to a pre-completed run while this one continues — it's the same flow."

**Show:** The deployed app on DEV (use bookmarked APEX URL).

**Say:**
> "There it is — the new column is live in DEV. Total elapsed: about 90 seconds from merge to live app."

---

### Act 4 · Promote to PROD via Release (7:00 – 10:30) — 3 min 30 sec  ·  **LIVE MOMENT 2 (suspense)**

**Show:** Releases tab.

**Say:**
> "DEV is automatic. PROD is not. Every production deploy goes through a GitHub Release — an explicit, named, business-grade event. Releases are how stakeholders see what's shipping and when."

**Do:** In your staged terminal:
```bash
gh release create v1.1.0 --title "v1.1.0 — Add category field" --generate-notes
```

**Show:** New release appears; **deploy-prod** job is now Waiting.

**Click:** Actions → run → **Review deployments**.

**Say:**
> "Look at this — it's waiting. The `production` environment requires a human reviewer. Even with admin access I can't just barrel through. This is **separation of duties**, configured per environment."

**Click:** **Approve and deploy**. (Add a one-line approval comment: "LGTM, sales aware.")

**Show:** Job resumes; same pipeline runs against PROD ADB.

**Pause for a beat:**
> "And — there's the new column in production."

**Audience anchor:**
- *Business:* "Auditable approval. Who approved what. When. For which release."
- *Technical:* "Different secrets per environment. Different ADB if you want it. The deploy script is the same — the boundary is enforced at the GitHub layer."

---

### Act 5 · Things Break, Pipelines Recover (10:30 – 13:00) — 2 min 30 sec  ·  **PRE-RECORDED**

**Show:** Previous failed run (open in tab; pre-staged from a SQL syntax error on a migration).

**Say:**
> "What happens when something goes wrong? Here's a previous attempt where a developer fat-fingered a migration."

**Click:**
1. Show the red workflow run → click into it → expand the `Deploy database schema` step → highlight `ORA-00904` (or similar) error.
2. Show that the failure happened **before** any DDL was committed — `WHENEVER SQLERROR EXIT` + the migration's exception handler caught it cleanly.
3. Show the revert PR that fixed it (in a few clicks of `git revert <sha>` + merge).
4. Show the green workflow run that followed.

**Say (be honest):**
> "Two things to call out. First: this isn't database 'rollback' in the classical sense — DDL auto-commits in Oracle, so if a migration partially applied, a revert PR alone wouldn't undo it. The pipeline is **built to fail fast, before changes commit**. Second: production-grade APEX shops upgrade to Liquibase rollback tags or down-migrations for full reversibility. We document that path in the research notes."

**Audience anchor:**
- *Business:* "Every failed deploy is itself a code artifact — traceable, discussable, recoverable."
- *Technical:* "Idempotent migrations + early-fail discipline. Rollback is recovery via revert, not magic undo."

---

### Act 6 · The Big Picture (13:00 – 14:30) — 1 min 30 sec

**Show:** README.md table of GitHub surfaces.

**Say:**
> "In 12 minutes you've seen six GitHub surfaces working together — Issues, Pull Requests, Actions, Environments, Secrets, Releases — to ship an Oracle APEX change with full traceability, mandatory review, environment isolation, and a clean recovery path."
>
> "None of this required a single proprietary tool beyond SQLcl, which is free and from Oracle. The pipeline is about 150 lines of YAML. The git repository **is** the source of truth for the database and the app — together, in the same commit."

**Optional close on value:**
> "The customer benefit: no more 'works on my schema' surprises, no more late-night DBA tickets to push hotfixes, full audit trail for compliance, and developers who can ship APEX apps with the same velocity as any modern web app."

---

### Act 7 · Q&A scaffolding (14:30 – 15:00) — 30 sec buffer

**Likely questions + prepared answers:**

| Question | One-line answer | Follow-up if pressed |
|---|---|---|
| "What about on-prem Oracle DB?" | Same workflow with a self-hosted runner inside the customer's network. | Show RESEARCH.md section on self-hosted runners. |
| "Liquibase or plain SQL?" | Plain SQL for this demo to keep it readable; Liquibase is the production upgrade path. | Both ride on SQLcl; migration to Liquibase is incremental. |
| "How do you test APEX pages in CI?" | Out of scope for today; production setups add utPLSQL for DB logic + Cypress for APEX UI. | Show RESEARCH.md MVD-vs-prod table. |
| "Is the APEX export human-reviewable?" | The single-file export is readable but large. Split exports give per-page diffs. | Show example structure in RESEARCH.md. |
| "What if PR-time validation needs a real DB?" | Pattern: an ephemeral schema or ADB clone per PR. Adds cost; not in this demo. | Cite the Oracle DevRel "ADB clone CI" pattern. |

---

## What's pre-staged vs live

| Beat | Pre-staged | Live on stage |
|---|---|---|
| Issue creation | ✅ Done before demo | — |
| Branch + PR | ✅ Pre-opened | — |
| PR validation green | ✅ Already passing | — |
| **Merge to main** | — | ✅ Click Merge live |
| DEV deploy | Optional: switch to pre-run if slow | Mostly live |
| **GitHub Release publish** | — | ✅ Run `gh release create` live |
| **PROD approval** | — | ✅ Click Approve live (suspense moment) |
| Rollback / failed run | ✅ From prior run | — |
| Revert PR | ✅ Already merged | Walk through only |

If you have time pressure, **the must-haves are: PR view → Merge live → DEV result → Release create → PROD approval live**. Cut Acts 5 and 7 if needed.

---

## Reset between demos

```bash
# 1. Drop the category column so Act 3 has somewhere to go:
gh workflow run deploy.yml -f environment=development   # establish v1.0 baseline

# Then revert PR #1 and the category migration manually, OR:
# 2. Re-run from scratch by recreating workspace/schema (slower but cleanest).
```

A reset script is left as an exercise — most demo runs use a fresh ADB. If you demo more than once a day, consider a per-demo schema with a random suffix.
