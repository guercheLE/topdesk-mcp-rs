# Knowledge Base article lifecycle

This sub-workflow is designed to be run as an isolated sub-task where
possible — if you were delegated here from `topdesk-menu`'s routing, or
your environment otherwise supports running this as its own sub-task,
everything you need is in this prompt's own text plus the context
already listed above; report back only a short summary when done rather
than the full step-by-step trace.

## Step 0.5 — Confirm which KB variant this instance uses

This workflow needs **one of three** catalogs, which is more specific
than the catalog check above already tells you — TOPdesk migrated its
Knowledge Base to a new "Explorer" experience with a differently-shaped
API, and also offers a separate GraphQL surface:

- `knowledge-base-before-explorer-migration` — older REST shape. A flat
  list of "Knowledge Items" with no folder hierarchy.
- `knowledge-base-after-explorer-migration` — REST, post-migration
  shape. This is a genuine **structural** difference, not just renamed
  fields: Knowledge Items can be organized into `/folders` (which can
  themselves be nested and moved), and items support per-language
  `/translations` and end-user `giveFeedback` that the before-migration
  variant doesn't have.
- `knowledgebase-graphql-1.0.0` — GraphQL. `call` still invokes a single
  operation, but expect its arguments to look like a GraphQL
  query/variables payload rather than a REST path + body — `search` for
  it as normal, then read its schema carefully before assuming a REST
  field name applies.

Whichever one is active, every operation below is a capability to
`search` for, not a fixed `operationId` — confirm each with `search`/
`get` before calling it, since the exact field names differ by variant.
TOPdesk calls the underlying resource a "Knowledge Item" in both REST
variants — search for that term, not "article", if a plain search
doesn't surface it.

## Step 1 — Draft a Knowledge Item

Capture a title, content/body, category, and target audience (internal
staff vs. external/self-service-portal visible). On the after-migration
variant, also decide which `/folders` entry it belongs under — `search`
for the folder list before creating a new one, since an existing folder
for this topic may already exist.

## Step 2 — Review gate

Many organizations require a reviewer before publishing. Ask the user
whether this article needs review-before-publish or is self-publishable
— don't call a publish-shaped operation until that's confirmed.

## Step 3 — Publish

Set status to published/live. Confirm audience visibility (internal-only
vs. external self-service portal) separately — this is often a distinct
field from "published", not implied by it.

## Step 4 — Maintain

Check via `get` whether editing an existing item's content is an
in-place update or creates a new versioned revision — TOPdesk KB items
are often versioned, and treating an edit as a fresh create when it
should be a revision (or vice versa) loses history either way. On the
after-migration variant, translations are a separate per-language
sub-resource (`/translations/{language}`) — updating the default
language doesn't touch other languages' translations, and vice versa;
don't assume editing one updates all of them.

## Step 5 — End-user feedback (after-migration variant only)

If this instance supports it, end users can leave feedback on a
published item (`giveFeedback`). Treat a pattern of negative feedback as
a signal the item may need Step 4's maintenance, not something to act on
automatically — surface it to the user rather than editing content on
your own initiative.

## Step 6 — Retire or archive

Prefer a status change (archive/unarchive) over a delete where one
exists, so the item's history isn't silently discarded.

## Composing with other workflows

`incident-lifecycle` often links a resolved incident to a KB article as
its resolution reference — that's a cross-catalog concern needing
`incident-4.2.6`, not whichever KB catalog is active here.
