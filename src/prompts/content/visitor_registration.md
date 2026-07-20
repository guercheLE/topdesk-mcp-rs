# Visitor registration

Every operation below is a capability to `search` for, not a fixed
`operationId` — confirm each one with `search`/`get` before calling it.

## Step 1 — Register a visitor

Capture the visitor's name, their host (the person/operator being
visited), the purpose of the visit, and the expected arrival window.
`search` for "register visitor", `get` its schema, then `call` it.

## Step 2 — Check in

Mark the arrival time when the visitor actually arrives — don't set
this at registration time, since registration typically precedes actual
arrival by hours or days.

## Step 3 — Check out

Mark the departure time. Confirm with the user that the visitor is
actually leaving rather than assuming end-of-day.

## Step 4 — Look up the host

If the host is only known by name, resolving them to an ID is a
cross-catalog concern — see `topdesk-reference-data-lookup`'s person/operator
resolution rather than guessing an ID here.
