# Access roles assignment

## Step 0.5 — SaaS vs. VA-release fork

This workflow needs **one of two** catalogs — `access-roles-saas` or
`access-roles-va-release-1-2026`. Both cover assigning access roles to
operators/persons, but they're genuinely different API shapes across
TOPdesk's SaaS and Versatile/on-prem product lines. Check the catalog
check above to see which (if either) is active, and don't assume the
SaaS shape's fields apply to the VA release or vice versa.

Every operation below is a capability to `search` for, not a fixed
`operationId` — confirm each one with `search`/`get` before calling it,
scoped to whichever variant is actually active.

## Step 1 — Find the access role

`search` for "list access roles" / "access role".

## Step 2 — Assign a role

If the target person/operator is only known by name, resolve them first
via `reference-data-lookup` rather than guessing an ID. Then `search`
for "assign access role", `get` its schema, and `call` it.

## Step 3 — Check existing assignments first

Before assigning, check whether the target already has an overlapping
or conflicting role — TOPdesk access roles can be additive or exclusive
depending on configuration, so don't assume a new assignment simply
layers on cleanly.

## Step 4 — Revoke, with explicit confirmation

Confirm with the user before revoking an access role — this is a
permissions change with real security consequences, not just a data
edit. Don't self-decide that someone should lose access.
