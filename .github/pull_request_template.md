## Summary
<!-- One-paragraph description of what this PR changes. -->

Closes #

## Type of change
- [ ] Database schema (new table or column)
- [ ] Database migration (data or constraint change)
- [ ] APEX application change
- [ ] CI/CD workflow change
- [ ] Documentation only

## Deployment notes
<!-- Order matters: schema migrations always run before APEX import.
     Call out anything that needs manual action (seed data, role grants, etc.). -->

- Migration order: <!-- e.g. db/migrations/003_add_category.sql -->
- APEX app changes: <!-- list pages, processes, items -->
- Requires PROD reviewer? Yes / No

## Verification
- [ ] `validate.yml` passes on this PR
- [ ] DEV deploy succeeds after merge
- [ ] `verify.sql` smoke check confirms expected DB state

## Rollback plan
<!-- How will we recover if PROD deploy fails after merge?
     Plain SQL migrations are not auto-rollback. Note the revert PR strategy. -->
