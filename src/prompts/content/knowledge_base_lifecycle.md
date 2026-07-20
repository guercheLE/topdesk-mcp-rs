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

- `knowledge-base-before-explorer-migration` — older REST shape.
- `knowledge-base-after-explorer-migration` — REST, post-migration
  shape; fields and operation names differ from the pre-migration one
  even though the underlying concept (an article) is the same.
- `knowledgebase-graphql-1.0.0` — GraphQL. `call` still invokes a single
  operation, but expect its arguments to look like a GraphQL
  query/variables payload rather than a REST path + body — `search` for
  it as normal, then read its schema carefully before assuming a REST
  field name applies.

Whichever one is active, every operation below is a capability to
`search` for, not a fixed `operationId` — confirm each with `search`/
`get` before calling it, since the exact field names differ by variant.

## Step 1 — Draft an article

Capture a title, content/body, category, and target audience (internal
staff vs. external/self-service-portal visible).

## Step 2 — Review gate

Many organizations require a reviewer before publishing. Ask the user
whether this article needs review-before-publish or is self-publishable
— don't call a publish-shaped operation until that's confirmed.

## Step 3 — Publish

Set status to published/live. Confirm audience visibility (internal-only
vs. external self-service portal) separately — this is often a distinct
field from "published", not implied by it.

## Step 4 — Maintain

Check via `get` whether editing an existing article's content is an
in-place update or creates a new versioned revision — TOPdesk KB
articles are often versioned, and treating an edit as a fresh create
when it should be a revision (or vice versa) loses history either way.

## Step 5 — Retire or archive

Prefer a status change over a delete where one exists, so the article's
history isn't silently discarded.

## Composing with other workflows

`incident-lifecycle` often links a resolved incident to a KB article as
its resolution reference — that's a cross-catalog concern needing
`incident-4.2.6`, not whichever KB catalog is active here.
