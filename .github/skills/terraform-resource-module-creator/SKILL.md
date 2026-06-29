---
name: terraform-resource-module-creator
description: Create a single Terraform resource module under modules/ for an Azure resource, following standard repo conventions (map(object) variable, for_each, standard location/tags/resource-group resolution, managed-identity dynamic block, raw resource outputs, heredoc-documented variables). Use when the user says "create a terraform module", "generate a resource module", "build a module for <Azure resource>", or provides an AVM (Azure Verified Module) registry source or an azapi / ARM template reference. This skill ONLY generates the module files (variables.tf, main.tf, outputs.tf, terraform.tf). It does NOT wire the module into a root environment — use the terraform_resource_module_wirer skill for that.
---

# Terraform Resource Module Creator

Generate one self-contained Terraform resource module in `modules/<module_name>/` that matches the existing repo conventions exactly. The user will name the Azure resource and provide the source of truth — either an **AVM module** (Terraform Registry), a **native azurerm resource**, or the **azapi / ARM template reference** (used when no AVM module exists, as with Communication Services).

> **Scope boundary:** This skill stops at the module files. Hooking the module into a root environment (wrapper variable, `module` block, `terraform.tfvars` example) is a separate concern handled by the **terraform_resource_module_wirer** skill.

## When to Use

- "Create a Terraform module for `<Azure resource>`"
- "Generate a resource module using this AVM module: `<registry source>`"
- "Build an azapi module for `<Microsoft.X/Y>`"
- "Make a module like `disk_encryption_set` for `<resource>`"

## Step 1 — Identify the Construction Path

Ask the user (or infer from the source they provide) which path applies:

| Path | When | Pattern reference |
|------|------|-------------------|
| **AVM module wrap** | An Azure Verified Module exists and the user provides/prefers it | [references/source-patterns.md](references/source-patterns.md#avm-module-wrap) |
| **Native azurerm resource** | No AVM module, but a first-class `azurerm_*` resource exists (e.g. `disk_encryption_set`) | [references/source-patterns.md](references/source-patterns.md#native-azurerm-resource) |
| **azapi resource** | No AVM module AND no/insufficient azurerm resource (e.g. Communication Services) | [references/source-patterns.md](references/source-patterns.md#azapi-resource) |

If unclear, **ask the user which source to use before generating anything.**

## Step 2 — Investigate the Resource (Source of Truth)

**Crawl the source of truth exhaustively.** The goal is to discover and expose **every** property and **nested sub-property** the resource supports — not just the common ones. A module that only surfaces a handful of fields is incomplete.

### 2a. Pull the full schema

- **AVM**: read the module's **complete** registry inputs/outputs list. Use the Terraform MCP tools (`search_modules`, `get_module_details`, `get_latest_module_version`) or fetch the registry page. Capture every input variable, including complex nested object types (`diagnostic_settings`, `role_assignments`, `private_endpoints`, `managed_identities`, etc.).
- **azapi / ARM**: read the **full** `Microsoft.<Provider>/<type>` template reference. Use the azapi schema tools (`get_azure_resource_type_schema`, `list_azure_resource_types`) to get the raw schema, and the Learn MCP tools below to confirm. Capture the latest stable API version.
- **azurerm**: read the provider resource docs and enumerate **every** argument and nested block.

### 2b. Recursively expand nested properties

For each property that is itself an object/block (and each object **inside** it), drill in and capture its sub-properties — repeat until you reach scalars. Do not stop at the first level. For example: `properties` → `userEngagementTracking`, `linkedDomains`; `identity` → `type`, `userAssignedIdentities`; `diagnosticSettings` → `workspaceResourceId`, `logCategories`, `metricCategories`. Build a complete tree before writing any HCL.

### 2c. For every discovered property, record:

- **Name** (and its camelCase ARM form for azapi bodies).
- **Required vs optional**, and the **default** value when optional.
- **Type** (string / number / bool / list / set / nested object).
- **Allowed values / enums**.
- **Whether it is a cross-reference** to another resource (an ID or key) — these get the `resource_ids` + `keys` dual-field treatment.

### 2d. Completeness check

Cross-check your property tree against the schema one more time. **Anything in the schema that is not deprecated or read-only must appear as a field in the module variable** (with `optional(...)` + a sensible default unless required). Read-only / computed properties belong in outputs, not inputs.

See [Learn MCP & schema lookups](#learn-mcp--schema-lookups). For the full crawling protocol and how to map nested objects to `optional(object({...}))`, see [references/conventions.md](references/conventions.md#exhaustive-property-coverage).

## Step 3 — Generate the Module Files

Create `modules/<module_name>/` with exactly these files (no README for resource modules):

```
modules/<module_name>/
├── terraform.tf     # required_version + required_providers
├── variables.tf     # the map(object) variable + supporting vars
├── main.tf          # for_each resource/module implementation
└── outputs.tf       # raw resource object output
```

Follow every convention in **[references/conventions.md](references/conventions.md)**. Key rules in brief:

- The primary variable is `map(object({...}))` named after the resource **(plural snake_case)**, defaulting to `{}`, with a heredoc (`<<-EOT`) markdown description documenting **every** field.
- Every object includes the standard fields: `name` (required), `resource_group_key` (optional), `resource_group_name` (optional), `location` (optional), `tags` (optional `map(string)`, default `{}`), plus `managed_identities` where the resource supports identity.
- Supporting variables: `location` (fallback), `resource_groups` (`any`, default `{}`), `tags` (`map(string)`, default `{}`), `managed_identities` (`any`) and any cross-reference inputs (e.g. `key_vaults`, `email_communication_services`) typed as `any`.
- Resolution helpers (identical across paths): `location = coalesce(each.value.location, var.location)`, `tags = merge(var.tags, each.value.tags)`, resource-group resolution, and the managed-identity `dynamic "identity"` block.
- **Expose every property and nested sub-property** discovered in Step 2 as a field in the `map(object)` variable. Nested objects become `optional(object({...}), {...})` with their full sub-property tree; lists of objects become `optional(list(object({...})), [])`. Do not silently drop fields to keep the schema small.
- **Map every variable field explicitly** into the resource/module/body — including every nested sub-property. Never hardcode values.
- `outputs.tf` exposes the **raw resource/module object** keyed by the map key (the repo default). **Child resources** created by a separate `for_each` get their **own** raw output keyed by the compound `"<parent_key>|<child_key>"` — never fold them into a curated parent object.

## Step 4 — Validate

From the module directory (or repo root) run:

```pwsh
terraform fmt -recursive modules/<module_name>
terraform -chdir=<env> validate   # the target root environment, once wired
```

`terraform fmt` must produce no diffs. Resolve `validate` errors before finishing. (Full `validate` requires the module to be referenced; if not yet wired, at minimum run `terraform fmt` and `terraform validate` in a scratch context or rely on the wirer skill's validation.)

## Step 5 — Offer Handover to the Wirer Skill

The module files are now complete but **not yet wired** into any environment. Ask the user whether they want to wire it in now:

> The `<module_name>` module is generated under `modules/<module_name>/`. Would you like me to wire it into a root environment now (wrapper variable + `module` block + `terraform.tfvars` example)?

- **If the user approves**, hand over to the **terraform_resource_module_wirer** skill. Pass along this context so it doesn't have to re-derive it:
  - the module folder name (`modules/<module_name>/`),
  - the primary variable name and its full `map(object({...}))` type,
  - the supporting/cross-reference variables the module expects (`resource_groups`, `managed_identities`, and any `any`-typed cross-refs such as `key_vaults`, `email_communication_services`),
  - whether `location` should be `var.location` or `"global"`,
  - the target root environment — ask if not already stated.
- **If the user declines**, stop here and remind them the module exists but is inert until wired, and that they can invoke **terraform_resource_module_wirer** later.

Do **not** wire the module yourself in this skill — always route that work through the wirer skill.

## Conventions Quick Reference

| Concern | Convention |
|---------|-----------|
| Provider versions | `required_version = ">= 1.13, < 2.0"`; azurerm `hashicorp/azurerm ~> 4.0`; azapi `azure/azapi ~> 2.0` |
| Iteration | `for_each = var.<resources>` over the `map(object)` |
| AVM module label | the module folder name / resource name in snake_case — **never `"this"`** (e.g. `module "application_insights"`, `module "app_service_plan"`) |
| azurerm resource name | `"this"` (the underlying `resource` inside a native module, not a `module` block) |
| azapi resource name | singular snake_case (e.g. `communication_service`) |
| azapi RG target | `parent_id` via `data.azurerm_client_config.current` + `var.resource_groups[...].resource_id` |
| azurerm RG target | `resource_group_name = coalesce(each.value.resource_group_name, var.resource_groups[...].name)` |
| Cross-references | resolve `<thing>_keys` to IDs via `any`-typed supporting vars; merge with direct `*_resource_ids` |
| Output | raw resource object, keyed by map key; child resources get their own raw output keyed `"<parent>|<child>"` |

Full details and copy-paste snippets: [references/conventions.md](references/conventions.md) and [references/source-patterns.md](references/source-patterns.md).

## Learn MCP & Schema Lookups

Use these to verify property names, enums, identity support, and API versions before writing the module.

| Tool | Purpose |
|------|---------|
| `microsoft_docs_search` | Find the resource's docs / template reference |
| `microsoft_docs_fetch` | Read the full ARM template or azurerm/AVM page |
| `microsoft_code_sample_search` | Find Terraform/azapi examples |
| azapi schema tools (`get_azure_resource_type_schema`, `list_azure_resource_types`) | Confirm azapi `type@apiVersion`, body property names, enums |
| Terraform MCP (`search_modules`, `get_module_details`, `get_latest_provider_version`) | Confirm AVM module inputs/outputs and provider versions |

### CLI Alternative

If the Learn MCP server is unavailable, use the `mslearn` CLI:

| MCP Tool | CLI Command |
|----------|-------------|
| `microsoft_docs_search(query: "...")` | `mslearn search "..."` |
| `microsoft_code_sample_search(query: "...", language: "...")` | `mslearn code-search "..." --language ...` |
| `microsoft_docs_fetch(url: "...")` | `mslearn fetch "..."` |

Run directly with `npx @microsoft/learn-cli <command>` or install globally with `npm install -g @microsoft/learn-cli`.

## Anti-Patterns to Avoid

- ❌ Exposing only a subset of properties — the module must surface **every** non-read-only property and nested sub-property from the source of truth.
- ❌ Stopping at the top level of a nested object instead of recursively expanding its sub-properties.
- ❌ Hardcoding `location`, `tags`, names, or IDs — everything comes from the variable.
- ❌ Omitting the heredoc field-by-field documentation on the primary variable.
- ❌ Squeezing a map/object and its sub-fields into one bullet, or merging a bold header into a field line (`**Role assignments** - \`role_assignments\` is ...`). Use one nested bullet per field — see [conventions.md](references/conventions.md#heredoc-description-structure-line-by-line-verbatim-passthrough).
- ❌ Paraphrasing or inventing field descriptions that exist in the wrapped source — copy them **verbatim** from the AVM/azurerm/azapi docs. Only module-special pattern fields get authored wording.
- ❌ Adding a `README.md` (resource modules in this repo have none).
- ❌ Labeling the AVM wrap `module` block `"this"` — name it after the module folder / resource (e.g. `module "app_service_plan"`) and reference it as `module.<module_name>` in outputs.
- ❌ Wiring the module into a root environment here — that's the wirer skill.
- ❌ Using `azapi` when a maintained AVM module or first-class `azurerm` resource exists and is preferred — confirm with the user.
- ❌ Returning a curated/trimmed output — always expose the raw resource object; child resources get their own raw output keyed `"<parent>|<child>"`.
