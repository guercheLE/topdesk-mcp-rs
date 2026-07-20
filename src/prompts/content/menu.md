# TOPdesk MCP prompts

This server also exposes 3 generic tools (`search`/`get`/`call`) over an
embedded, per-`api_version` operation catalog. These prompts are
playbooks that sequence those 3 tools for specific TOPdesk workflows.

Available playbooks (name — needs catalog — what it's for):

- `incident-lifecycle` — `incident-4.2.6` — create/classify/assign/
  escalate/resolve/close an incident, including the major-incident fork.
- `change-management-lifecycle` — `change-1.4.0` — RFC classification,
  planning/backout, CAB approval routing, implementation, and closure.
- `asset-management-basics` — `assets-1.91.1` — register/link/query/
  decommission assets.
- `knowledge-base-lifecycle` — `knowledge-base-before-explorer-migration`
  / `knowledge-base-after-explorer-migration` / `knowledgebase-graphql-1.0.0`
  — draft → review → publish → maintain → retire a KB article.
- `reservations-booking` — `reservations-2.0.0` — book/check availability/
  modify/cancel a reservable resource.
- `reference-data-lookup` — `supporting-files-2.7.11` — resolve operator/
  person/branch/category IDs by name; referenced by the workflows above.
- `visitor-registration` — `visitors-2.0.0` — register/check-in/check-out
  a visitor.
- `operations-management-tasks` — `operations-management-1.10.0` —
  operational checklists/tasks, including a change's execution checklist.
- `access-roles-assignment` — `access-roles-saas` /
  `access-roles-va-release-1-2026` — assign/query/revoke access roles.

Small, non-workflow-shaped catalogs with no dedicated playbook — explore
these directly with `search`, no guided sequence needed:
`services-1.3.7`, `lookandfeel-1.0.0`, `task-notifications-1.0.0`,
`settings-1.1.0`, `custom-action-support-saas`,
`custom-action-support-va-release-1-2023-or-newer`.

None of the playbooks above apply if the active catalog shown here isn't
the one they list — switching requires editing `api_version` in config
(or the `TOPDESK_MCP_API_VERSION` env var) and restarting this server
process; it cannot be changed mid-session. See this repo's
`docs/SCHEMA_VERSIONS.md` for the full catalog list.
