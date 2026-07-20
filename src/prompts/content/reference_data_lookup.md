# Reference data lookup

This is a lookup-shaped catalog (over 100 operations, mostly "resolve an
ID by name"), not a step-by-step workflow — other prompts
(`incident-lifecycle`, `change-management-lifecycle`,
`asset-management-basics`, `reservations-booking`,
`access-roles-assignment`) point here by name whenever they need to
resolve a person, operator, branch, or category rather than duplicating
this content.

Every operation below is a capability to `search` for, not a fixed
`operationId` — confirm each one with `search`/`get` before calling it.

## What lives here

Operators, persons (callers), branches/locations, categories and
subcategories, and whatever other supporting-files entities this
TOPdesk instance defines.

## Person vs. operator

TOPdesk distinguishes **persons** (anyone in the organization, potential
incident callers or reservation requesters) from **operators** (people
who actually work TOPdesk tickets). Searching "person" and "operator"
returns genuinely different operations — don't conflate them when
another prompt asks you to "resolve the requester" without specifying
which one it means; ask if it's ambiguous.

## Pattern

Almost every other workflow eventually needs "find the ID for
operator/person/branch/category X". `search` for the specific entity
type (e.g. "find operator by name", "list branches") — don't assume a
single generic lookup operation covers every entity type, since TOPdesk
models each as its own resource with its own search/list operation.

## Permission and access assignments live here too

If you were sent here from `access-roles-assignment` looking for how to
actually grant or revoke a permission (that catalog is read-only
reporting only): `search` for "permission groups" / "operator groups"
scoped to an operator — real permission assignment happens on the
operator record itself, in this catalog, not in
`access-roles-saas`/`-va-release-1-2026`.

## Large listings

Enumerating an entire category tree or branch list is a good candidate
for step-level delegation — see the delegation guidance at the end of
this prompt — rather than pulling a full organization's reference data
into the main conversation just to resolve one ID.
