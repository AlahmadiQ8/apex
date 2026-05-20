# `apex/` — APEX application export

## What is `f100.sql`?

`f100.sql` is the **APEX application export** for the Customer Feedback demo app (application ID 100, workspace `DEMO`). The deploy workflow imports it via:

```text
sql> apex import -applicationid 100 -workspacename DEMO -file apex/f100.sql
```

## ⚠️ Synthetic placeholder

The `f100.sql` checked into this repo is a **minimal synthetic export** authored by hand. It is intentionally tiny (workspace + application skeleton only) so the rest of the pipeline can be demonstrated end-to-end.

**Before a customer demo against your real ADB, replace it with a real export from your APEX workspace:**

```bash
# 1. Build the app in your DEMO workspace via the APEX Builder
#    (App Builder -> Create from table CF_FEEDBACK -> Wizard).
#    Keep the application ID as 100 to match the pipeline.

# 2. Export the real app with SQLcl:
sql ADMIN/yourpass@yourdb_high
SQL> cd /path/to/apex/apex
SQL> apex export -applicationid 100

# 3. Commit the generated f100.sql:
git add apex/f100.sql
git commit -m "chore(apex): replace synthetic export with real APEX export"
git push
```

The rest of the pipeline (workflows, schema, secrets, environments) is **unchanged** when you swap in a real export.

## Why a synthetic export and not just an empty file?

The deploy workflow runs `apex import` unconditionally. An empty or invalid file would fail and break the deploy. The synthetic file passes import (or fails predictably and visibly) so the surrounding plumbing — secrets, environments, gates, releases — can be demonstrated even before a customer provisions their APEX workspace.

## How was the synthetic file generated?

It uses Oracle's documented `wwv_flow_imp.*` PL/SQL API. The internal structure matches what `apex export` produces, but only at the bare minimum needed to register an application of ID 100 in workspace `DEMO`. It does **not** include real pages, reports, or forms — those come from a real export.

## Workspace and application ID conventions

- **Workspace:** `DEMO`
- **Parsing schema:** `DEMO_SCHEMA` (or whatever schema you own `CF_FEEDBACK` in)
- **Application ID:** `100`
- **Application alias:** `feedback`

If you change any of these, update `apex/f100.sql`, `scripts/deploy.sql`, and the `apex import` call in `.github/workflows/deploy.yml`.

## Split exports (production-grade)

For real production work, prefer the **split-export** form for cleaner Git diffs:

```text
SQL> apex export -applicationid 100 -split -skipExportDate -expOriginalIds -dir ./apex
```

This produces a directory tree (`apex/f100/...`) where each page is a separate file. Then import via:

```text
sql> apex import -applicationid 100 -workspacename DEMO -file apex/f100/install.sql
```

For the 15-minute customer demo, the single-file form is easier to show in PR diffs.
