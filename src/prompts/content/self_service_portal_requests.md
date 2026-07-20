# Self-Service Portal (SSP) requester workflows

This prompt is unusual among the guided workflows: it applies to
**three different catalogs** — `incident-4.2.6`, `change-1.4.0`, and
`reservations-2.0.0` — because each of those already-covered domains
exposes a *second*, parallel API surface for the end-user/requester
perspective, separate from the operator-facing one
`topdesk-incident-lifecycle` / `topdesk-change-management-lifecycle` /
`topdesk-reservations-booking` cover. Only one catalog is ever active at a
time, so only one of the three requester surfaces below is actually
reachable in any given session — the catalog check above tells you
which.

Every operation below is a capability to `search` for, not a fixed
`operationId` — confirm each one with `search`/`get` before calling it.

## Step 1 — Confirm this is genuinely a self-service request

This facade exists for a person acting on their **own** incident,
change, or reservation — not an operator working a queue on someone
else's behalf. If the user is actually an operator doing operator work,
stop and redirect them to `topdesk-incident-lifecycle`,
`topdesk-change-management-lifecycle`, or `topdesk-reservations-booking` instead; those
cover the fuller operator-facing surface and this narrower one isn't the
right tool for that job.

## Step 2 — Identify the active requester surface

Exactly one of these applies, matching whichever catalog is active:

- `incident-4.2.6` → `/requester/incidents/*` — a person creating,
  viewing, or replying to their own incidents.
- `change-1.4.0` → `/requesterChanges/*` — a person's view of changes
  they raised. Mostly read plus progress-trail replies; creating a new
  change as a requester may not be exposed at all depending on this
  instance's configuration — confirm via `search` rather than assuming
  a create operation exists.
- `reservations-2.0.0` → `POST /requester/reservations` — a person
  booking their own reservation.

`search` within that surface specifically (e.g. "requester incident",
not just "incident") — the requester and operator surfaces are modeled
as genuinely separate operations, not the same one with a different
auth token.

## Step 3 — The requester surface is narrower than the operator one

Don't assume an operator-only action (escalate, approve, assign,
archive) exists here — it typically doesn't. If the person needs one of
those, that's a handoff to a human operator, not something to force
through the requester-facing endpoints. Say so plainly rather than
searching repeatedly for an operation that isn't in this facade.

## Composing with other workflows

Once an operator needs to act on what a requester submitted here, hand
off to `topdesk-incident-lifecycle`, `topdesk-change-management-lifecycle`, or
`topdesk-reservations-booking` by name for the rest of that record's lifecycle
— they cover the same underlying incident/change/reservation from the
operator's side.
