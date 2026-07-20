# Asset Management basics

This sub-workflow is designed to be run as an isolated sub-task where
possible — if you were delegated here from `topdesk-menu`'s routing, or
your environment otherwise supports running this as its own sub-task,
everything you need is in this prompt's own text plus the context
already listed above; report back only a short summary when done rather
than the full step-by-step trace.

This catalog is broad (128 operations) but mostly CRUD-per-asset-type
rather than one linear lifecycle — treat this as a reference for the
operation *shapes* that exist, not a fixed numbered sequence. Every
operation below is a capability to `search` for, not a fixed
`operationId` — confirm each one with `search`/`get` before calling it.

## Asset templates and types

Assets are typed (e.g. "Laptop", "Server", "Monitor"), each with its own
template/spec fields. `search` for "asset template" / "asset type"
before creating an asset of a new type, since required fields genuinely
vary per template — don't assume the fields from one asset type apply
to another.

## Register an asset

`search` for "create asset", `get` its schema (varies per
`template_id`), then `call` it with the fields that template actually
requires.

## Link an asset

Assets can be linked to a location/branch, to a person/operator (an
assigned user), or to another asset (a parent/child relationship, e.g. a
monitor linked to a desktop). `search` for "asset link" / "asset
relation" for the specific relationship you need — resolving a
person/branch by name rather than ID is a cross-catalog concern, see
`topdesk-reference-data-lookup`.

## Bulk registration

If the user wants to register many assets, `search` for a genuine
batch/import operation before looping single creates. If none exists,
independent single creates with no ordering dependency between them are
a legitimate candidate for parallelization or delegation — see the
delegation guidance at the end of this prompt — rather than doing them
strictly one-by-one in this conversation.

## Query and list assets

Filtering by type, status, or location is common. Large result sets are
a good candidate for step-level delegation (see below) rather than
pulling every row into the main conversation just to find one asset.

## Decommission or delete

Check whether this instance models retirement as a status change (e.g.
"in stock" → "removed") or an actual delete operation before acting — a
real delete is often irreversible. Confirm intent with the user before
calling anything delete-shaped; prefer a status-change operation if one
exists and achieves the same outcome.

## Composing with other workflows

Linking an asset to an incident record is a cross-catalog concern
needing `incident-4.2.6`, not `assets-1.91.1` — see `topdesk-incident-lifecycle`.
Resolving a person/branch/operator by name routes through
`topdesk-reference-data-lookup`.
