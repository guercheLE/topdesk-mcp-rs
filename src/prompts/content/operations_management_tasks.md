# Operations Management tasks

This catalog is the landing spot `change-management-lifecycle`'s Step 7
points to for a change's actual execution checklist. If you were sent
here from that prompt, the record you're operating on is a
task/activity tied to a change or a standalone operational checklist
item — not a change record itself (that lives in the `change-1.4.0`
catalog).

Every operation below is a capability to `search` for, not a fixed
`operationId` — confirm each one with `search`/`get` before calling it.

## Step 1 — Find or create the task/checklist

`search` for "operations task" / "activity", and confirm whether it's
linked to a parent record (a change, a project) or standalone before
creating a new one.

## Step 2 — Assign an owner

An operational task needs a single accountable owner, not just an
assignee. Ask the user who that is if it isn't already known — the
field's real meaning (accountability, not just "who's doing it") matters
for audit purposes later.

## Step 3 — Sequence dependent tasks

Some checklists have real ordering (task B can't start until task A
completes). `search` for a dependency/predecessor field before assuming
tasks in a checklist can run in parallel. Independent tasks with no such
dependency are a legitimate parallelization/delegation candidate — see
the delegation guidance at the end of this prompt.

## Step 4 — Log progress and completion

Mark each task's status as it's actually done, not in bulk at the end.
If this checklist's outcome feeds back into a parent change's own
outcome logging, keep the two in sync rather than closing the checklist
silently.

## Step 5 — Verify full completion before reporting back

A checklist with open items is not done just because most of it is —
confirm every item's status via a read before signaling completion back
to whatever workflow sent you here (e.g. `change-management-lifecycle`).

## Composing with other workflows

This catalog is a common cross-catalog target from
`change-management-lifecycle` (Step 7), and can also stand alone for
routine operational work with no change attached.
