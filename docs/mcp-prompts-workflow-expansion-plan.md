# MCP prompts expansion: self-service portal workflow + grounding fixes

## Context

[docs/mcp-prompts-workflow-plan.md](mcp-prompts-workflow-plan.md) shipped 10 MCP prompts (`topdesk-menu` + 9 domain playbooks) in `v0.5.0`. That plan's domain-scoping decisions leaned on `docs/topdesk-api-specs.md`'s "Counts" table (e.g. "Incident API: 18", "Access Roles API: 16"). Re-deriving those counts directly from the **real embedded catalogs** (`sqlite3` against each `mcp_store_v*.db`, extracted via `resolve_store_path`/`cached_store_connection`) shows that table is unreliable — it undercounts every domain checked, in some cases by 5-10x:

| Catalog | Docs table said | Real embedded catalog has |
|---|---:|---:|
| `incident-4.2.6` | 18 | **94** |
| `change-1.4.0` | 56 | **64** |
| `reservations-2.0.0` | 26 | **58** |
| `access-roles-saas` | 16 | **5** |
| `access-roles-va-release-1-2026` | 16 | **5** |
| `knowledge-base-after-explorer-migration` | 2 | **42** |
| `knowledge-base-before-explorer-migration` | 2 | **27** |
| `knowledgebase-graphql-1.0.0` | 1 | 1 (matches) |
| `operations-management-1.10.0` | 18 | **30** |

This matters for two reasons: first, it means the *existing* prompt content, designed against the wrong counts, is missing real capabilities and in one case (`access-roles-assignment`) actively describes operations that don't exist. Second, it changes this task's actual job: rather than scanning for entirely new domains, the highest-value work is (a) one genuinely new **cross-cutting** workflow the real data surfaces, and (b) grounding fixes to existing prompts so they match what's actually callable.

### Finding 1 — a real, previously-uncovered cross-cutting workflow: the Self-Service Portal (SSP) requester surface

Three of the nine already-covered domains each expose a **second, parallel API surface** for the end-user/requester perspective, distinct from the operator-facing one the existing prompts already cover:

- `incident-4.2.6`: `/requester/incidents/*` (≈20 operations) — a person creating/tracking/replying to their *own* incidents, as opposed to an operator working the queue.
- `change-1.4.0`: `/requesterChanges/*` — a requester's read-mostly view of changes they raised.
- `reservations-2.0.0`: `POST /requester/reservations` — a person booking their own reservation.

This is a genuinely distinct **actor lens** applied consistently across three already-modeled domains, not just more depth in one of them — exactly the kind of "extra workflow" worth its own guided prompt rather than folding into each domain prompt piecemeal. It's also the clearest illustration yet of why every prompt must stay agnostic to which catalog is active: this one prompt is meaningfully useful with **any one of the three** catalogs loaded (`incident-4.2.6`, `change-1.4.0`, or `reservations-2.0.0`) — unlike every other domain prompt, which needs exactly one specific catalog, `catalog_check_block`'s existing "any of these" list semantics fit this multi-catalog case directly with no code changes.

(`change-1.4.0` also has a *third* actor lens — `managerAuthorizableChanges`/`managerAuthorizableActivities`, a manager's approve/reject-only facade — but that one is change-specific, not cross-cutting across domains, so it's folded into `change-management-lifecycle`'s existing approval-gate step rather than given its own prompt or added to the new cross-cutting one.)

### Finding 2 — `access-roles-assignment` describes operations that don't exist

Both `access-roles-saas` and `access-roles-va-release-1-2026` are **read-only reporting catalogs** — `GET /roles`, `GET /roleConfigurations`, `GET /reporting/1.0.0/roles` and their `/{id}` variants. There is no assign/revoke/create operation in either catalog. The shipped `access-roles-assignment` prompt's Steps 2 and 4 ("assign a role", "revoke, with explicit confirmation") send the calling LLM to `search` for operations that will never be found. Real permission assignment in TOPdesk happens through `supporting-files-2.7.11`'s operator record (`/operators/id/{id}/permissiongroups`, `/operatorgroups`, `/permissiongroups`) — a cross-catalog concern from `access-roles-saas`/`-va-release-1-2026`'s own perspective. This prompt needs a factual rewrite, not just an addition.

### Finding 3 — real gaps in three other shipped prompts

- `reservations-booking.md` never mentions `POST /reservations/{identifier}/approve` or `/reject` — real operations that need the same "don't self-approve, confirm a human already decided" gate discipline `change-management-lifecycle` already applies to change approvals. Missing today.
- `knowledge_base_lifecycle.md` undersells the after-migration variant: it has a real folder hierarchy (`/folders`, `/folders/{id}/move`), per-item translations (`/knowledgeItems/{id}/translations/{language}`), and end-user feedback (`/knowledgeItems/{id}/giveFeedback`) that the before-migration variant genuinely lacks (flat, no folders) — a real structural difference between the two REST variants, not just a field-naming one, worth calling out explicitly.
- `incident_lifecycle.md`'s Step 4 talks about escalation generically; the real catalog has formal `PUT .../escalate` / `PUT .../deescalate` operations each backed by a dedicated reason-code list (`escalation-reasons`, `deescalation-reasons`), plus archive/unarchive — worth naming precisely rather than gesturing at "search for how this instance links related incidents."

## Approach

### New prompt: `self-service-portal-requests`

Same shape as every other domain prompt (`WorkflowArgs`, `catalog_check_block`, `render_context_header`, `delegation_guidance`, `include_str!` content file), added to `src/prompts/router.rs` and `src/prompts/content/self_service_portal_requests.md`. The one structural difference: `catalog_check_block` is called with **three** acceptable catalogs (`incident-4.2.6`, `change-1.4.0`, `reservations-2.0.0`) instead of one or two — `catalog_check_block`'s existing signature (`expected: &[&str]`) already supports this with no code change, so the "match" branch fires if *any* of the three is active. Content (~80-120 lines, medium band):

1. Confirm the request is genuinely on behalf of the requester/person, not an operator acting on their own queue — the whole point of this facade is person-initiated self-service; if the user is actually an operator doing operator work, redirect to `incident-lifecycle`/`change-management-lifecycle`/`reservations-booking` instead.
2. Identify which of the three requester surfaces applies to the current catalog (only one will match `catalog_check_block`'s expected list at a time, since only one catalog is ever active) and `search` within it — `/requester/incidents`, `/requesterChanges`, or `POST /requester/reservations`.
3. Note the requester surface is typically narrower than the operator one (fewer fields, read-mostly for changes) — don't assume an operator-facing field or action (e.g. escalate, approve) exists here; if the user needs one of those, that's a cross-catalog/cross-facade handoff back to the operator-facing prompt for the same domain, not something to force through the requester endpoints.
4. Composing with other workflows — point to `incident-lifecycle`, `change-management-lifecycle`, `reservations-booking` by name for the operator-side continuation of whatever the requester started.

### Corrections to existing content

- **`access_roles_assignment.md`** (rewrite): reframe as a read-only reporting/audit workflow — "who has what role", "what permissions does this role carry" — over `GET /roles`, `/roleConfigurations`, `/reporting/1.0.0/roles`. Explicitly state no write operation exists in this catalog family in either variant, and redirect actual permission changes to `reference-data-lookup`'s cross-catalog note on `supporting-files-2.7.11`'s `/operators/id/{id}/permissiongroups`/`/operatorgroups`. Update `router.rs`'s description string to match (currently says "Assign, query, and revoke").
- **`reservations_booking.md`**: insert an approval-gate step between "create" and "modify/cancel", mirroring `change-management-lifecycle`'s "stop here, do not self-approve" language, keyed to the real `approve`/`reject` operations.
- **`knowledge_base_lifecycle.md`**: fold in folders/translations/feedback as after-migration-only capabilities, explicit about the before-migration variant lacking a folder hierarchy (flat item list only).
- **`incident_lifecycle.md`**: name the real `escalate`/`deescalate` operations and their reason-code lists precisely in the major-incident step; mention archive/unarchive; add a pointer to the new `self-service-portal-requests` prompt for the `/requester/incidents/*` surface instead of the current generic caller-communication framing.
- **`change_management_lifecycle.md`**: strengthen the approval-gate step with the real `managerAuthorizableChanges`/`managerAuthorizableActivities` facade name (a manager-role credential approves/rejects there, distinct from the `operatorChanges` facade the rest of the workflow uses); add a pointer to `self-service-portal-requests` for `/requesterChanges/*`.
- **`operations_management_tasks.md`**: one short mention of `/operationalSeries` (recurring operational activities) alongside the existing single-activity checklist content.
- **`reference_data_lookup.md`**: one short cross-reference note that `operatorgroups`/`permissiongroups` here is where actual permission assignment happens, referenced from `access-roles-assignment`.
- **`menu.md`**: add `self-service-portal-requests` to the directory; correct `access-roles-assignment`'s one-line description.

### `router.rs` / tests

- Add `self_service_portal_requests` prompt method, `catalog_check_block` called with all three requester-surface catalogs.
- Update `access_roles_assignment`'s `#[prompt(description = ...)]` string.
- `tests/prompts_workflow.rs`: add `self-service-portal-requests` to `DOMAIN_PROMPT_NAMES` (now 10 domain prompts + menu = 11 total); extend `every_domain_prompt_renders_successfully_with_its_matching_catalog` with three cases for the new prompt (one per acceptable catalog) plus one mismatch case (e.g. `assets-1.91.1` active) asserting `MISMATCH`.

### README update

Add a "Guided workflow prompts" section to `README.md` (the repo's existing MCP-capability description currently covers only the 3-tool surface) — name `topdesk-menu` as the entry point, list all 10 domain prompts with catalogs needed, and state the single-active-catalog constraint plainly (same framing as `menu.md`, but for humans reading the README rather than an LLM reading prompt output).

## Critical files

- `src/prompts/content/self_service_portal_requests.md` (new)
- `src/prompts/content/{access_roles_assignment,reservations_booking,knowledge_base_lifecycle,incident_lifecycle,change_management_lifecycle,operations_management_tasks,reference_data_lookup,menu}.md` (edits)
- `src/prompts/router.rs` — new prompt method, `access-roles-assignment` description string update
- `tests/prompts_workflow.rs` — `DOMAIN_PROMPT_NAMES`, new catalog-match/mismatch cases
- `README.md` — new "Guided workflow prompts" section
- `docs/mcp-prompts-workflow-expansion-plan.md` (this file)

## Verification

Same gates as the original feature: `cargo build`, `cargo test` (full suite, including `tests/prompts_workflow.rs`), `cargo clippy --all-targets`, `cargo fmt --check`.

## Release

Matches this repo's established sequence, per the user's explicit instruction this round:

1. Once implementation is complete and `cargo test`/`clippy`/`fmt` all pass: `git commit` the implementation with a conventional message (`feat(rust): ...`).
2. `git commit` this plan doc separately (`docs: ...`).
3. Bump `version` in `Cargo.toml`: **minor** bump to `0.6.0` — this adds a new prompt (a new user-facing capability), matching the same minor-bump reasoning applied for `0.5.0`; commit as `chore(release): bump version to 0.6.0`.
4. `git tag v0.6.0`.
5. `git push origin main`, then `git push origin v0.6.0`.
