# Reservations booking

This sub-workflow is designed to be run as an isolated sub-task where
possible — if you were delegated here from `topdesk-menu`'s routing, or
your environment otherwise supports running this as its own sub-task,
everything you need is in this prompt's own text plus the context
already listed above; report back only a short summary when done rather
than the full step-by-step trace.

Every operation below is a capability to `search` for, not a fixed
`operationId` — confirm each one with `search`/`get` before calling it.

## Step 1 — Find a reservable resource

`search` for "list reservable resources" / "rooms" / "equipment" —
resource types vary per instance (rooms, equipment, parking spots, and
others this instance may define).

## Step 2 — Check availability before booking

`search` for an availability/free-busy operation scoped to a resource
and time window before creating a reservation. Don't blind-create and
rely on a conflict error — TOPdesk's double-booking behavior varies by
resource configuration, so an unchecked create can silently succeed
against an already-booked slot.

## Step 3 — Create the reservation

Capture the resource, start/end time, requester (person/operator), and
purpose. `get` the schema before calling — required fields vary by
resource type (e.g. equipment may need a return location, rooms may need
an attendee count).

## Step 4 — Recurring-booking fork

Ask the user whether this is a one-off or a recurring booking before
creating anything. Recurring series are typically their own
operation/parameter set, not a loop of single creates — `search`
specifically for "recurring reservation" rather than assuming a loop of
Step 3 calls is correct.

## Step 5 — Modify or cancel

Confirm the reservation's current status via a read before canceling —
a reservation that already started may need a different
shorten/end-now operation than a full cancel. `search` for the
update/cancel operation that matches the actual situation.

## Step 6 — List upcoming reservations

A listing step for a person or resource. Large result sets are a good
candidate for step-level delegation — see the delegation guidance at the
end of this prompt — rather than pulling every row into the main
conversation.

## Composing with other workflows

Resolving a requester by name rather than ID is a cross-catalog concern
— see `reference-data-lookup`.
