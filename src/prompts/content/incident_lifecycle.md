# Incident lifecycle

This sub-workflow is designed to be run as an isolated sub-task where
possible — if you were delegated here from `topdesk-menu`'s routing, or
your environment otherwise supports running this as its own sub-task,
everything you need is in this prompt's own text plus the context
already listed above; report back only a short summary when done rather
than the full step-by-step trace.

Every operation below is described as a capability to `search` for, not
a fixed `operationId` — confirm each one with `search`/`get` before
calling it rather than assuming a name from this text.

## Step 1 — Create the incident

Capture the caller (person), a brief description/request, category and
subcategory, and an urgency/impact/priority classification. `search` for
"create incident", `get` its schema, then `call` it. If the caller is
only known by name or email rather than an ID, resolving that is a
**cross-catalog concern** — it needs `supporting-files-2.7.11`, not
`incident-4.2.6`; fetch the `reference-data-lookup` prompt for that step
rather than guessing an ID.

## Step 2 — Classify and prioritize

TOPdesk typically derives priority from impact × urgency, but confirm
via `get` what this instance's schema actually records — customization
varies, don't assume the fields exist verbatim.

## Step 3 — Assignment fork

Ask the user whether this incident should go to a specific operator or
to an operator group (queue) — TOPdesk models these differently.
`search` for "assign incident" / "processing status" once you know
which.

## Step 4 — Major-incident escalation fork

If many callers are affected or a whole service is down, ask the user
to explicitly confirm major-incident classification before flagging it
— this changes communication cadence and stakeholder visibility across
the organization. Do not self-declare a major incident. TOPdesk models
this as formal `escalate`/`deescalate` operations, each requiring a
reason drawn from a dedicated reason-code list (`search` for
"escalation reasons" / "deescalation reasons") — don't call escalate or
deescalate without picking a real reason from that list, and confirm
with the user before deescalating something they haven't agreed is
resolved enough to step down.

## Step 5 — Communicate with the caller

Ask whether the update is caller-visible (a reply/action) or an
internal-only note before calling anything — TOPdesk usually models
these as different fields, and sending an internal note to the caller
by mistake is a real information-disclosure risk worth being careful
about.

## Step 6 — Log time spent

Required for reporting in many organizations. `search` for time-spent
operations scoped to an incident and log actual time as work happens,
not retroactively in one batch.

## Step 7 — Link to a problem or change, if root cause requires one

**Cross-catalog note**: linking to a request for change needs the
`change-1.4.0` catalog, not `incident-4.2.6`. If that catalog isn't
active, tell the user rather than guessing at an operationId that isn't
loaded — see `change-management-lifecycle` for that workflow.

## Step 8 — Resolve

Set the solution/resolution field. Gate: confirm the caller has actually
been notified (Step 5) before marking resolved — a resolution the caller
doesn't know about isn't done from their perspective.

## Step 9 — Close

Don't close on the assumption that resolution succeeded — verify via a
follow-up `search`-and-`get`/`call` read of the incident's current
status first, then close.

## Step 10 — Archive, separately from closing

TOPdesk models archiving as its own `archive`/`unarchive` operation,
distinct from the closed-status set in Step 9 — a closed incident isn't
necessarily archived. Only archive on the user's explicit instruction;
don't treat "closed" as implying "should also be archived now".

## Composing with other workflows

Step 1's caller lookup and Step 3's operator lookup both route through
`reference-data-lookup`; Step 7's change linkage routes through
`change-management-lifecycle`. If the person who reported this incident
is asking about it through the Self-Service Portal rather than through
you as an operator, that's `self-service-portal-requests`'s
`/requester/incidents/*` surface, not this one — fetch that prompt by
name instead of trying to replicate its narrower, requester-facing
operations here.
