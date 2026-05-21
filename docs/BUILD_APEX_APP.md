# Building a Real APEX App (replacing the synthetic `f100.sql`)

> **Audience:** the person setting up the demo. This walks you A→Z through replacing the synthetic placeholder `apex/f100.sql` with a real, working APEX application that lives on stage during the customer demo.
>
> **Your environment (from setup):**
> - Workspace: `DEMO`
> - Parsing schema: `DEMO_SCHEMA`
> - Workspace ID: `9165770663318761`
> - Target application ID: `100`
> - Application alias: `feedback`

---

## Is this step even required?

**No** — the demo works end-to-end with the synthetic `apex/f100.sql` placeholder. The pipeline will import it successfully, schema migrations will deploy, and you can demonstrate every GitHub surface (Actions, PRs, Environments, Secrets, Issues, Releases) without a real UI.

**Yes, do it if** you want a real APEX page to appear when you open the app URL on stage during Act 3 of the demo. A real app turns a 9/10 demo into a 10/10 demo because the audience sees an actual form react to their merged change.

If you're under time pressure, skip this and go straight to `docs/SETUP.md` Step 3 (download the wallet).

---

## Pre-flight checklist

Before you can create an app, the `CF_FEEDBACK` table must exist in `DEMO_SCHEMA`. There are two ways to make that happen:

> ⚠️ **First, confirm your ADB is the right workload type.** If you provisioned an **"APEX" workload type** ADB, you will not be able to download a wallet or run SQLcl externally — that means the CI/CD pipeline won't work at all. You need a **Transaction Processing** workload ADB. See [`docs/SETUP.md` Step 1](SETUP.md#step-1--provision-oracle-autonomous-database-always-free) for the fix. Continue this guide only after you have an ATP-workload instance.

### Option A — Let the pipeline create it (recommended if you're going through SETUP.md in order)

Skip ahead in `docs/SETUP.md` and complete Steps 3–6 (wallet, secrets, branch protection), then trigger:

```bash
gh workflow run deploy.yml -f environment=development
gh run watch
```

This applies `db/install.sql` against your ADB and creates `CF_FEEDBACK` + the migration tracking table. Then come back here.

### Option B — Create the table manually right now (fastest if you just want to do this step)

You don't need local SQLcl or the wallet for this. Use the APEX **SQL Scripts** tool (not "SQL Commands" — SQL Commands only runs one statement at a time and will error with `ORA-00922` on multi-statement input):

1. Sign in to APEX as `DEMO_ADMIN` (workspace `DEMO`) — see "Sign in" below.
2. Top nav → **SQL Workshop** → **SQL Scripts**.
3. Click **Create** (or **Upload**).
4. Script name: `bootstrap_cf_feedback`
5. Paste the entire block below into the script body, click **Save**, then click **Run** → **Run Now**:

```sql
CREATE TABLE cf_feedback (
    id         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name       VARCHAR2(100) NOT NULL,
    email      VARCHAR2(150),
    rating     NUMBER(1) NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comments   VARCHAR2(4000),
    created_at DATE DEFAULT SYSDATE NOT NULL
);

CREATE INDEX cf_feedback_rating_idx  ON cf_feedback (rating);
CREATE INDEX cf_feedback_created_idx ON cf_feedback (created_at);

INSERT INTO cf_feedback (name, email, rating, comments) VALUES ('Ada Lovelace',      'ada@example.com',      5, 'Excellent product!');
INSERT INTO cf_feedback (name, email, rating, comments) VALUES ('Alan Turing',       'alan@example.com',     4, 'Solid, room for polish.');
INSERT INTO cf_feedback (name, email, rating, comments) VALUES ('Grace Hopper',      'grace@example.com',    5, 'Saved us hours.');
INSERT INTO cf_feedback (name, email, rating, comments) VALUES ('Linus Torvalds',    'linus@example.com',    3, 'Docs could be clearer.');
INSERT INTO cf_feedback (name, email, rating, comments) VALUES ('Margaret Hamilton', 'margaret@example.com', 5, 'Beautifully reliable.');
COMMIT;
```

6. After Run completes, the Results page shows each statement and "Statement processed." for each one.
7. Verify: SQL Workshop → **SQL Commands** → paste `SELECT COUNT(*) FROM cf_feedback;` and click Run → should return `5`.

#### If you must use SQL Commands instead

SQL Commands runs **one statement at a time** and does not accept trailing `;`. If you prefer it, paste each of these one at a time (no trailing semicolon), clicking Run between each:

```sql
CREATE TABLE cf_feedback (
    id         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name       VARCHAR2(100) NOT NULL,
    email      VARCHAR2(150),
    rating     NUMBER(1) NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comments   VARCHAR2(4000),
    created_at DATE DEFAULT SYSDATE NOT NULL
)
```

```sql
CREATE INDEX cf_feedback_rating_idx ON cf_feedback (rating)
```

```sql
CREATE INDEX cf_feedback_created_idx ON cf_feedback (created_at)
```

Then for seed data, paste each INSERT separately, then finally `COMMIT`.

> ⚠️ If you take Option B, the pipeline's first deploy will detect the existing table and skip the `CREATE` (because of `ORA-00955` handling). The `schema_migrations` table will be empty, so re-runs may re-attempt; this is harmless because every script is idempotent. After your first successful pipeline run, the migration tracking will be back-filled.

---

## Sign in to APEX Builder

1. Go to your ADB in the [OCI Console](https://cloud.oracle.com) → **Tools** tab → **Oracle APEX** → click **Open APEX**.
2. The APEX Welcome page opens. Click **Workspace Login** (not Admin Services).
3. Sign in:
   - **Workspace:** `DEMO`
   - **Username:** `DEMO_ADMIN` (the workspace admin user you set up in SETUP.md Step 2)
   - **Password:** the workspace admin password
4. You land in the **APEX Workspace home** with tiles for App Builder, SQL Workshop, Team Development, Gallery.

---

## Create the application from the table

> **APEX UI variants:** newer APEX versions show a streamlined "Create an Application" page with a big green "Create Application" button and 6 wizard shortcuts below it (Use Create App Wizard, From a File, Quick SQL, Fusion Integration, Browse Gallery, Copy Existing). The **"From a Table"** option you may see in older docs is now reached **inside** the **Use Create App Wizard**. Use the wizard path below — it works on both layouts.

1. Click **App Builder** → **Create** (top right of the Workspace home).
2. On the "Create an Application" page:
   - **Name:** `Customer Feedback`
   - **ID:** overwrite the auto-assigned number with `100` (just click and retype). If `100` shows an error like *"Application 100 already exists"*, delete the conflicting app from App Builder first, then retry.
3. **Do NOT click the big green "Create Application" button** — that creates a blank shell. Instead, click the first option below it: **"Use Create App Wizard"** (icon: pencil + ruler).
4. The full wizard opens. Re-confirm:
   - Name: `Customer Feedback`
   - Application ID: `100`
5. Scroll to the **Pages** section → **Add Page**.
   - Page type: **Report with Form** (or "Interactive Report" + add a separate "Form" page)
   - **Source Type:** Table
   - **Schema:** `DEMO_SCHEMA`
   - **Table:** `CF_FEEDBACK`
   - Accept defaults for the rest → **Add Page**
6. Expand **Settings** (chevron). Set:
   - **Application Alias:** `feedback`
   - Leave other defaults alone.
7. Click **Create Application** at the bottom of the wizard.

The wizard generates Home, Report, and Form pages on `CF_FEEDBACK`.

> If the form silently uses a different App ID (some APEX versions ignore the override when 100 is already taken in your workspace), see "If App ID 100 is already used" below.

---

## Verify the app works

1. After creation you land on the **Application home**.
2. Click **Run Application** (the play icon top-right) → an APEX login appears → sign in as `DEMO_ADMIN`.
3. You should see the Home page with the rows you seeded above. Click **Create** to add a new feedback row — the form appears, you can save.

If this works, you have a real APEX app ready to export.

---

## Export the app

You have **two equally valid paths**. Path 1 is easier if you don't have SQLcl + wallet set up locally; Path 2 is what `docs/SETUP.md` currently describes.

### Path 1 — Export via APEX UI (no local SQLcl needed)

1. APEX → **App Builder** → click your **Customer Feedback** app card.
2. Top-right click **Export / Import** → **Export**.
3. On the Export form:
   - **Format:** `SQL`
   - **Export File Encoding:** keep default (`UTF-8`)
   - **Export with Original IDs:** `Yes` (keeps app ID 100 stable across imports)
   - **Export Build Status:** `Run and Build Application`
   - **As of:** leave blank
   - Leave the rest at defaults
4. Click **Export Application** → the file `f100.sql` downloads to your browser.
5. Drop it into the repo:
   ```bash
   cd /Users/mohammad/dev/apex
   mv ~/Downloads/f100.sql apex/f100.sql
   git add apex/f100.sql
   git commit -m "chore(apex): replace synthetic export with real APEX export

   Built in the DEMO workspace (workspace id 9165770663318761) from
   CF_FEEDBACK table. Application id 100, alias 'feedback'. Replaces
   the synthetic placeholder shell.

   Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
   git push origin main
   ```

Done. The deploy workflow picks it up automatically on the next push.

### Path 2 — Export via SQLcl locally (per SETUP.md)

Prereqs: SQLcl installed locally, wallet downloaded and configured.

```bash
# 1. Install SQLcl if you haven't:
#    https://www.oracle.com/database/sqldeveloper/technologies/sqlcl/download/
#    Extract; ensure 'sql' is on your PATH.

# 2. Make sure your wallet is set up. From the wallet zip you downloaded:
#    Unzip somewhere safe, e.g. ~/oracle-wallet/, then:
mkdir -p ~/oracle-wallet
cd ~/oracle-wallet
unzip ~/Downloads/Wallet_apexdemo.zip
chmod 600 *
export TNS_ADMIN=~/oracle-wallet

# 3. Connect to ADB. Use the DEMO_ADMIN workspace credentials if you set the
#    workspace owner role on it, OR use ADMIN. Connection service is the
#    'high' alias from your tnsnames.ora (e.g. apexdemo_high).
cd /Users/mohammad/dev/apex/apex
sql DEMO_ADMIN/<your-password>@apexdemo_high
# or:  sql ADMIN/<your-admin-password>@apexdemo_high

# 4. At the SQLcl prompt:
SQL> apex export -applicationid 100
# This writes f100.sql in the current directory (cwd=apex/).

SQL> EXIT

# 5. Commit:
cd /Users/mohammad/dev/apex
git diff --stat apex/f100.sql
git add apex/f100.sql
git commit -m "chore(apex): replace synthetic export with real APEX export

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
git push origin main
```

---

## Sanity check after replacing the file

1. Open `apex/f100.sql` in your editor. A real export has hundreds (often thousands) of lines and starts with header comments like `-- ORACLE` plus `prompt --application/set_environment` and `wwv_flow_imp.import_begin (...)` calls. The synthetic placeholder is ~95 lines.

2. The deploy workflow should still parse and import it. Trigger a DEV deploy to confirm:
   ```bash
   gh workflow run deploy.yml -f environment=development
   gh run watch
   ```

3. After a successful run, navigate to your APEX Builder again → your application → **Run Application** → the UI works in DEV as well.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| The "Create an Application" page shows a green "Create Application" button and 6 shortcuts, but no "From a Table" option | Newer APEX UI variant | "From a Table" is now inside **Use Create App Wizard** (the first shortcut below the green button). The green button creates a blank shell; click the wizard shortcut instead. See "Create the application from the table". |
| Wizard greys out the Application ID field | Some APEX versions prevent overrides at create time | Create the app with the default ID, then go to **Shared Components → Application Definition → Application ID** and change to `100` — APEX renumbers internal IDs |
| `ORA-20987: APEX - cannot find application 100` on `apex export` | Wrong workspace context in SQLcl | At the SQLcl prompt: `apex_util.set_security_group_id(9165770663318761);` then retry. Or sign in as the workspace owner. |
| Exported file is suspiciously small (~200 bytes) | Connected schema can't see the app | Confirm you are connected as a user with access to workspace `DEMO`. Try `ADMIN` instead of `DEMO_ADMIN`. |
| `Listener refused connection` on SQLcl | Wallet not set or wrong service alias | `echo $TNS_ADMIN` should print the wallet dir. Try the `_low` alias if `_high` is busy. |
| App ID 100 is already used in your workspace | You created a different app earlier | Delete that app from App Builder, or change the demo to use a different ID — update `apex/f100.sql`, `.github/workflows/deploy.yml` (the `-applicationid` arg), and `scripts/verify.sql` |

---

## If App ID 100 is already used

The pipeline is hardcoded to `applicationid 100`. If you can't free up that ID:

- **Easiest:** delete the conflicting app via App Builder → Application Properties → Delete.
- **Alternative:** change the pinned ID. Search-and-replace `100` in three places:
  - `apex/f100.sql` (filename and `set_application_id(100)` call)
  - `.github/workflows/deploy.yml` (`-applicationid 100` and `<file apex/fNNN.sql>`)
  - `scripts/verify.sql` (`application_id = 100`)

---

## Recap

After completing this guide you have:

1. ✅ A real APEX application in workspace `DEMO` with ID `100`, alias `feedback`
2. ✅ A working Home (interactive report) + Form on `CF_FEEDBACK`
3. ✅ A real `apex/f100.sql` export committed to `main`
4. ✅ The deploy pipeline still works unchanged — it will import the real export on every deploy

Continue with `docs/SETUP.md` from Step 3 (wallet download) if you took Option B above, or you're ready for `docs/DEMO_SCRIPT.md` if you took Option A and everything is already wired up.
