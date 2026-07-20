# Access roles reporting

## Step 0.5 — SaaS vs. VA-release fork

This workflow needs **one of two** catalogs — `access-roles-saas` or
`access-roles-va-release-1-2026`. Both cover the same read-only role
data across TOPdesk's SaaS and Versatile/on-prem product lines. Check
the catalog check above to see which (if either) is active.

## This catalog is read-only — there is no assign/revoke operation here

Both variants expose exactly the same shape: `GET /roles`,
`GET /roleConfigurations`, `GET /reporting/1.0.0/roles`, and their
`/{id}` single-item forms. There is **no create, assign, or revoke
operation in either catalog** — don't `search` repeatedly expecting to
find one, and don't tell the user you can assign or revoke a role from
here, because you can't.

Every operation below is a capability to `search` for, not a fixed
`operationId` — confirm each one with `search`/`get` before calling it.

## Step 1 — List roles and role configurations

`search` for "list access roles" / "role configurations" to see what
roles this instance defines and how each one is configured.

## Step 2 — Report who holds a role

`search` for the reporting operation ("reporting roles") that returns
which users have which permissions — this is the closest thing this
catalog offers to "who can do X", useful for audits or answering
"does this operator already have permission Y".

## Step 3 — Actually assigning or revoking a role

This is a **cross-catalog concern** — real permission assignment in
TOPdesk happens on the operator record itself, in the
`supporting-files-2.7.11` catalog (`/operators/id/{id}/permissiongroups`,
`/operatorgroups`), not here. See `topdesk-reference-data-lookup` for that. If
the active catalog isn't `supporting-files-2.7.11`, tell the user this
server needs to be restarted with that catalog active before an actual
assignment or revocation is possible through these tools — don't
attempt it through `access-roles-saas`/`-va-release-1-2026`, since no
operation there can perform it.
