# Change Management lifecycle

This sub-workflow is designed to be run as an isolated sub-task where
possible — if you were delegated here from `topdesk-menu`'s routing, or
your environment otherwise supports running this as its own sub-task,
everything you need is in this prompt's own text plus the context
already listed above; report back only a short summary when done rather
than the full step-by-step trace.

Every operation below is described as a capability to `search` for, not
a fixed `operationId` — the embedded catalog is semantically searched,
so confirm each one with `search`/`get` before calling it rather than
assuming a name from this text.

## Step 1 — Classify the request for change (RFC)

Ask the user, or infer from what they've already told you, which shape
this change is:

- **Standard / pre-approved template change** (low-risk, repeatable,
  e.g. "add a printer") — skip straight to Step 2, and treat Step 5's
  approval gate as already satisfied by the template itself.
- **Simple change** (single approver, no CAB) — Steps 2–5, abbreviated.
- **Extensive change** (full risk/impact assessment plus CAB) — Steps
  2–5, in full, including Step 4.
- **Emergency change** — see the fork at Step 4a.

`search` for "change type" / "request for change types" to confirm this
TOPdesk instance actually exposes these as a field — customization
varies by instance, don't assume the four shapes above exist verbatim.

## Step 2 — Create the RFC

`search` for an operation like "create change" / "create request for
change", `get` its schema, then `call` it with: brief description,
category/subcategory, requester, and the change type from Step 1.
Capture the returned change number and surface it to the user
immediately — if this session gets interrupted, that number is how the
workflow resumes.

## Step 3 — Attach an implementation plan and a backout plan

`search` for "activities" / "planning" operations scoped to a change.
Required for extensive changes; recommended even for simple ones. A
backout plan with no owner or no rollback trigger is not a real one —
don't let the user skip it silently on an extensive change.

**Independent sub-step, parallelizable**: the implementation plan and
the backout plan don't depend on each other and can be drafted
concurrently — see the delegation/parallelization note at the end of
this prompt if your environment supports running them as separate
sub-tasks.

## Step 4 — Impact and risk assessment (extensive changes only)

Skip for simple/standard changes. `search` for fields/operations that
record impact, urgency, and risk classification on the change record —
this is TOPdesk's basis for whether CAB review is mandatory. Don't
assume; check what this record's schema actually asks for via `get`.

### Step 4a — Emergency fork

If this change is being made to stop active harm (a P1 incident, an
active security exposure), TOPdesk's real-world pattern is to implement
first and seek retrospective/expedited approval afterward. If the user
describes urgency like this, say so explicitly and ask them to confirm
they want the emergency path — do not silently reorder Step 4/Step 5
without that confirmation, since skipping pre-approval is the kind of
action with real audit consequences.

## Step 5 — Approval gate: stop here, do not self-approve

TOPdesk approvals are typically tracked as their own sub-records or
tasks on the change (not a single boolean flag), and for an extensive
change may need multiple approvers routed through a Change Advisory
Board (CAB), sequentially or in parallel. Concretely, this is usually a
**separate facade from the one you've been using to build the change**:
the create/edit steps above go through the operator-facing change
surface, but authorization itself typically goes through a
manager-scoped facade (`search` for terms like "manager authorizable
change" / "authorization activity") reachable only with a
manager-role credential — don't assume the same credential that created
the change can also authorize it. Before calling anything that looks
like an "approve"/"authorize" operation:

1. `search` to see what an authorization step actually looks like in
   this schema — a status transition, a linked authorization activity,
   or a decision recorded per approver on that manager-scoped facade.
2. Ask the user who the real approvers are and whether approval has
   already happened outside this tool (e.g. in a meeting, over email).
3. Only call an approval-shaped operation on the user's explicit
   instruction that a specific named approver actually approved it.
   This tool should record decisions humans made, not make them.

Standard/pre-approved changes usually skip this step by definition —
confirm that assumption against the schema rather than assuming it.

## Step 6 — Schedule the implementation window

`search` for planned-start/planned-end fields or scheduling operations
tied to the change — often modeled as an "activity"/"task" on the
change, not a field on the change record itself.

## Step 7 — Build, test, and execute

**Cross-catalog note**: a change's actual execution checklist may live
in the Operations Management catalog (`operations-management-1.10.0`),
which is a **separate catalog** from Change Management (`change-1.4.0`)
— see the catalog check above. If this server is running with
`change-1.4.0` active, operations-management operations will not be
found by `search`; that's expected, not a bug. Tell the user their
execution checklist may need to be run against a server configured with
`operations-management-1.10.0` instead, or tracked manually.

## Step 8 — Log actual start/end and outcome

Record success / partial / failed / backed out, plus actual start and
end times.

## Step 9 — Post-implementation review (PIR)

`search` for evaluation/closure fields: lessons learned, and whether the
change caused any linked incidents. That last check is **another
cross-catalog concern** — incident linkage typically needs the
`incident-4.2.6` catalog, not `change-1.4.0`. Say so rather than
guessing at an operationId that isn't in the active catalog.

## Step 10 — Close the change

Set status to closed/evaluated once Steps 8–9 are confirmed complete —
don't close on the assumption that a prior `call` succeeded; verify via
a follow-up `search`-and-`get`/`call` read of the change's current
status first.

## Composing with other workflows

Step 7 and Step 9's cross-catalog notes point at `operations-management-tasks`
and `incident-lifecycle` respectively — fetch those prompts by name for
more detail rather than duplicating their content here. If the requester
is asking about their own change through the Self-Service Portal rather
than through you as an operator, that's `self-service-portal-requests`'s
narrower `/requesterChanges/*` surface, not this one.
