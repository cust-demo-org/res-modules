---
name: terraform-resource-module-docs-generator
description: Generate and maintain terraform-docs documentation (_header.md, _footer.md, .terraform-docs.yml, README.md) for resource modules in this repo. Audits each module's main.tf for key-based cross-references and keeps the _header.md table in sync, then runs terraform-docs to regenerate README.md. Use when the user says "generate module README", "create module docs", "add _header/_footer", "audit key-based references", or "/terraform-resource-module-docs-generator <module|all>".
---

# Terraform Resource Module Docs Generator

Produce consistent per-module documentation for resource modules. Each module gets a `.terraform-docs.yml` config, a `_header.md` (description + key-based reference table), a `_footer.md` (cross-module references), and a generated `README.md`. The skill also re-audits existing `_header.md` files for missing key-based references before regenerating.

## When to Use

- "Generate the README for `<module>`" / "create docs for all modules"
- "Add `_header.md` / `_footer.md` to the new modules"
- "Audit `_header.md` key-based references and regenerate"
- Slash usage: `/terraform-resource-module-docs-generator <module_name>` or `/terraform-resource-module-docs-generator` (all modules)

## Scope

A target is a top-level module directory (e.g. `data_factory/`, `application_gateway/`). "all" = every directory containing a `main.tf`. Skip `.github/` and pattern/root environments.

## Step 1 — Identify Targets

- Single module: use the argument (e.g. `application_gateway`).
- All: list directories with a `main.tf`. Each needs `.terraform-docs.yml`, `_header.md`, `_footer.md`.

## Step 2 — Create `.terraform-docs.yml` (if missing)

Use the exact repo-standard config (`markdown document` formatter, `header-from: _header.md`, `footer-from: _footer.md`, output to `README.md` mode `replace`, sorted by required). Copy from an existing module like `virtual_machine/.terraform-docs.yml` so all modules stay identical.

## Step 3 — Author / Audit `_header.md`

Format:

```markdown
# <Title>

This module deploys ... using the [AVM <name> module](<registry-url>) (`vX.Y.Z`).
<!-- For azapi/native: note no AVM source and why. -->

## Key-Based References

| Field | Resolves Via | Description |
|---|---|---|
| `resource_group_key` | `var.resource_groups` | Resource group name |
| ... | ... | ... |
```

**Audit rule (critical):** grep `main.tf` for every `var.<supporting_var>[...]` lookup and ensure each appears in the table. Common patterns: `managed_identities.user_assigned_keys`, `*.vnet_key`/`subnet_key` → `virtual_networks`, `key_vault_key`/`key_key` → `key_vaults`, `workspace_key` → `log_analytics_workspaces`, `public_ip_key` → `public_ips`, `role_assignments.managed_identity_key`, `service_plan_key`, `application_insights.key`, private-endpoint subnet keys. Add any missing rows.

## Step 4 — Author `_footer.md`

```markdown
## Cross-Module References

This module's output (`<output_name>`) can be consumed by other modules in this repository.
<!-- Note inter-module producers/consumers, e.g. web_site ← app_service_plan, application_insights -->
```

## Step 5 — Generate

```pwsh
terraform-docs <module_dir>
```

For all modules, loop over each target. Verify it reports `README.md updated successfully`.

## Conventions

- Don't duplicate variable docs — the heredoc in `variables.tf` is the source of truth; `_header.md` just summarizes key-based references.
- Footers list which sibling modules consume the output.
- Don't overwrite a user-edited `_header.md` description; only sync the references table.
