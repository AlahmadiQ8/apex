# `db/` — Database schema and migrations

This directory contains all SQL for the Customer Feedback demo app.

## Layout

```
db/
├── install.sql                   # Master orchestrator (called from scripts/deploy.sql)
├── schema/
│   ├── 000_schema_migrations.sql # Migration tracking table (idempotent)
│   └── 001_create_feedback.sql   # cf_feedback table + indexes (idempotent)
└── migrations/
    ├── 002_seed_data.sql         # Sample data (idempotent MERGE)
    └── 003_add_category.sql      # THE DEMO MOMENT: adds category column
```

## Conventions

1. **Numbered prefix** on every file (`NNN_description.sql`). Numbers are sequential, three digits, no gaps. `validate.yml` enforces this.
2. **Idempotent**. Every script can be run repeatedly without error:
   - DDL is wrapped in PL/SQL blocks that catch `ORA-00955` (object exists) or `ORA-01430` (column exists).
   - DML uses `MERGE` keyed on natural keys.
3. **No bare `COMMIT`** at file top — let the master script control transactions when possible. DDL auto-commits regardless.
4. **`WHENEVER SQLERROR EXIT`** is configured by the caller (`scripts/deploy.sql`), so any unhandled error aborts the pipeline.

## Adding a new migration

1. Create the next sequentially-numbered file in `db/migrations/`.
2. Wrap DDL in `BEGIN ... EXCEPTION WHEN OTHERS THEN ... END;` with the appropriate `SQLCODE` check.
3. Add an `@@migrations/NNN_xxx.sql` line plus its `schema_migrations` `MERGE` to `db/install.sql`.
4. Open a PR. `validate.yml` will check numbering and idempotency hygiene.
