---
name: terraform-resource-module-wirer
description: Wire an existing Terraform resource module (from modules/) into a root environment configuration following standard repo conventions. Use when the user says "wire <module> into <env>", "hook up the module", "add the module to the root environment", "expose the module variable", or "consume the module outputs". This skill adds the wrapper variable to the environment's variables.tf, the module block (passing foundation/pattern-module outputs) to main.tf, an example to terraform.tfvars, and ensures the required providers exist. It does NOT author the module files themselves — use the terraform-resource-module-creator skill for that.
---

# Terraform Resource Module Wirer

Connect a module that already exists in `modules/<name>/` into a root environment so it deploys with the rest of the stack. This skill is the counterpart to **terraform-resource-module-creator** (which authors the module files).

> **Prerequisite:** The module under `modules/<name>/` already exists with its `variables.tf`, `main.tf`, `outputs.tf`, and `terraform.tf`. If it doesn't, run **terraform-resource-module-creator** first.

> **Handover from the creator skill:** When invoked as a handover from **terraform-resource-module-creator**, you may already have been given the module folder name, the primary variable name and type, the supporting/cross-reference variables, the `location` strategy (`var.location` vs `"global"`), and the target environment. Reuse that context and skip re-deriving it; only ask the user for anything still missing (e.g. the target environment).

## When to Use

- "Wire the `<module>` module into the root environment"
- "Add the new module to the connectivity environment"
- "Expose the module's variable at the environment level and pass the pattern outputs"

## Step 1 — Choose the Environment

| Environment | Root pattern module | Pattern source |
|-------------|---------------------|----------------|
| Spoke shared-services env | `module.<spoke_pattern>` | `../modules/ptn-lza-ntwk-shared-services` |
| Connectivity hub env | `module.<hub_pattern>` | `../modules/ptn-lzp-connectivity-hub-vnet` |
| No pattern module | none | wire against raw resources / data sources / root locals |

Three wiring scenarios are documented end-to-end in [references/wiring-pattern.md](references/wiring-pattern.md): (1) spoke shared-services pattern, (2) connectivity hub pattern, (3) no pattern module. Pick the target root env and identify its foundation pattern module **if any**.

When a pattern module exists, its **outputs** (`resource_groups`, `key_vaults`, `managed_identities`, `virtual_networks`, `storage_accounts`, `log_analytics_workspace`, `combined_private_dns_zones_resource_ids`, …) are what downstream resource modules consume. With no pattern module, wire supporting vars against raw resources / data sources / root locals instead (Scenario 3). Some keys instead resolve against a **sibling resource module's** output (e.g. `service_plans` ← `module.app_service_plan`, `application_insights` ← `module.application_insights`). See the [pattern-output reference table](#additional-cross-reference-wiring-identities-app-insights-storage-key-vault-sibling-modules-pe-dns-zones). Confirm the environment with the user if ambiguous.

## Step 2 — Add the Wrapper Variable (`<env>/variables.tf`)

Copy the module's **primary variable** declaration (the strongly-typed `map(object({...}))`) into the environment `variables.tf`. Keep the full type; replace the long heredoc with a short pointer description.

```terraform
variable "<resources>" {
  type = map(object({
    # ... exact copy of the module's primary variable type ...
  }))
  default     = {}
  description = "Map of Azure <Resource> to create via the <module> module. Refer to the module's variable descriptions for complete details."
}
```

> The environment wrapper variable's `type` must stay **in sync** with the module's primary variable. If the module type changes later, update both.

## Step 3 — Add the Module Block (`<env>/main.tf`)

Add a `module` block after the pattern module (and after any modules it depends on). Pass the wrapper variable, the pattern-module outputs the module needs, and `location` / `tags`.

```terraform
module "<name>" {
  source = "../modules/<name>"

  <resources> = var.<resources>

  # Wire pattern-module outputs to the module's supporting variables.
  resource_groups    = module.<pattern_module>.resource_groups
  managed_identities = module.<pattern_module>.managed_identities
  # ... plus any cross-reference inputs, e.g.:
  # key_vaults       = module.<pattern_module>.key_vaults

  # If this module depends on ANOTHER resource module's output, pass it directly:
  # email_communication_services = module.email_communication_services.email_communication_services

  location = var.location   # use "global" for global control-plane resources
  tags     = var.tags
}
```

Wiring rules:

- Map each of the module's `any`-typed supporting variables to the matching **pattern-module output** (`module.<pattern_module>.<output>`).
- If the module consumes another resource module's output (inter-module dependency, e.g. Communication Services → Email Communication Services), pass that module's output and let Terraform infer the dependency order. When the dependency is on a **child resource** (e.g. email domains), pass the producing module's **child output** (`module.<x>.email_services_domains`), not its parent output.
- Use `location = "global"` for resources whose control plane is global; otherwise `var.location`.
- Pass `enable_telemetry = var.enable_telemetry` and `lock = var.lock` only if the module declares those variables.

### Common cross-reference wiring (network + diagnostics)

Most resource modules need one or both of the foundation pattern's network and Log Analytics outputs. Wire them the same way every time.

**Network (VNet / subnet keys).** When the module integrates with a subnet (e.g. App Service VNet integration, private endpoints), it exposes a `network_configuration` object with `vnet_key` / `subnet_key` (key-based) and a `subnet_resource_id` (direct) fallback, plus a supporting `virtual_networks` variable. Wire the pattern's `virtual_networks` output:

```terraform
module "<name>" {
  source = "../modules/<name>"

  <resources>      = var.<resources>
  resource_groups  = module.<pattern_module>.resource_groups
  virtual_networks = module.<pattern_module>.virtual_networks   # resolves vnet_key/subnet_key → subnet resource_id
  # ...
}
```

The module resolves the subnet internally as `var.virtual_networks[network_configuration.vnet_key].subnets[network_configuration.subnet_key].resource_id`, falling back to `network_configuration.subnet_resource_id`. In `terraform.tfvars`:

```terraform
network_configuration = {
  vnet_key   = "<vnet-key>"   # key into virtual_networks
  subnet_key = "MLSubnet"                # subnet key within that VNet
}
```

**Diagnostic settings (existing Log Analytics workspace).** Modules with `diagnostic_settings` take a supporting `log_analytics_workspaces` map and resolve each setting's destination workspace as `workspace_resource_id` → `var.log_analytics_workspaces[workspace_key].resource_id` → (when `use_default_log_analytics = true`) the **first** workspace in the map → otherwise `null` (a workspace is not required — storage/event hub/marketplace destinations are also valid). Wire the pattern's single `log_analytics_workspace` output as the map (it becomes the first/`default` entry):

```terraform
module "<name>" {
  source = "../modules/<name>"

  # ...
  log_analytics_workspaces = {
    default = module.<pattern_module>.log_analytics_workspace
  }
}
```

In `terraform.tfvars`, set `use_default_log_analytics = true` to route to the pattern workspace, or pass an explicit `workspace_key` / `workspace_resource_id`:

```terraform
diagnostic_settings = {
  diag-<resource>-law = {
    name                      = "diag-<resource>-law"
    log_groups                = ["allLogs"]
    metric_categories         = ["AllMetrics"]
    use_default_log_analytics = true   # first workspace in log_analytics_workspaces (pattern)
  }
}
```

**Role assignments (caller + pattern-managed identities).** When the module exposes `role_assignments`, it follows the pattern module's principal-resolution convention so roles can be granted to the Terraform runner or to a pattern-created managed identity. The object replaces a required `principal_id` with three mutually-exclusive principal sources:

```terraform
role_assignments = optional(map(object({
  role_definition_id_or_name             = string
  principal_id                           = optional(string)        # explicit principal object ID
  managed_identity_key                   = optional(string)        # key into var.managed_identities → principal_id
  assign_to_caller                       = optional(bool, false)   # use the Terraform runner's object ID
  description                            = optional(string, null)
  skip_service_principal_aad_check       = optional(bool, false)
  condition                              = optional(string, null)
  condition_version                      = optional(string, null)
  delegated_managed_identity_resource_id = optional(string, null)
  principal_type                         = optional(string, null)
})), {})
```

The module resolves the principal as `assign_to_caller` (→ `data.azurerm_client_config.current.object_id`) → `managed_identity_key` (→ `var.managed_identities[key].principal_id`, with `principal_type = "ServicePrincipal"`) → explicit `principal_id`. This depends on the `managed_identities` supporting variable, so wire the pattern output:

```terraform
module "<name>" {
  source = "../modules/<name>"

  # ...
  managed_identities = module.<pattern_module>.managed_identities   # resolves managed_identity_key → principal_id
}
```

In `terraform.tfvars`:

```terraform
role_assignments = {
  grant-caller-contributor = {
    role_definition_id_or_name = "Contributor"
    assign_to_caller           = true                # Terraform runner identity
  }
  grant-uami-reader = {
    role_definition_id_or_name = "Reader"
    managed_identity_key       = "<uami-key>" # key into managed_identities (pattern)
  }
}
```

> Keep the wrapper variable's `diagnostic_settings` / `network_configuration` / `role_assignments` types **identical** to the module's (including `use_default_log_analytics`, `workspace_key`, `subnet_resource_id`, `assign_to_caller`, `managed_identity_key`). These are repo-standard user-facing fields — don't drop them when copying the type.

### Additional cross-reference wiring (identities, app insights, storage, key vault, sibling modules, PE DNS zones)

Beyond network/diagnostics/role-assignments, modules commonly resolve these keys. Wire each supporting variable to the listed output. **Direct values always win; the key is the fallback** (resolution is `coalesce(<direct>, try(var.<supporting>[<key>].<attr>, null))` or a `!= null ? : try(...)` ternary).

| Supporting variable | Wire from | Resolves (module field → target) |
|---------------------|-----------|----------------------------------|
| `resource_groups` | `module.<pattern>.resource_groups` | `resource_group_key` → RG `name` / `resource_id` (often passed as `parent_id`) |
| `managed_identities` | `module.<pattern>.managed_identities` | `*_keys` / `*_key` → UAMI `resource_id`, `principal_id`, or `client_id` |
| `virtual_networks` | `module.<pattern>.virtual_networks` | `vnet_key`/`subnet_key` → subnet `resource_id` |
| `log_analytics_workspaces` | `{ default = module.<pattern>.log_analytics_workspace }` | `workspace_key` / `use_default_log_analytics` → workspace `resource_id` |
| `key_vaults` | `module.<pattern>.key_vaults` | `key_vault_key` (e.g. on `certificates`, `customer_managed_key`) → Key Vault `resource_id`; `customer_managed_key.key_key` → key name (from the vault's `keys[key].versionless_id`) |
| `storage_accounts` | `module.<pattern>.storage_accounts` | `storage_account_key` → storage account `name` |
| `private_dns_zones` | `module.<pattern>.combined_private_dns_zones_resource_ids` | `private_dns_zone.keys` → DNS zone `resource_id` |
| `application_insights` | `module.application_insights.application_insights` | `application_insights.key` → `connection_string` + `instrumentation_key` |
| `service_plans` | `module.app_service_plan.app_service_plans` | `service_plan_key` → plan `resource_id` |

**Single-identity references (key → UAMI resource ID).** Standalone identity fields (not the `managed_identities` block) follow a `<field>` + `<field>_key` dual pattern resolved via the already-wired `managed_identities` output — no extra wiring needed. Examples: `key_vault_reference_identity` + `key_vault_reference_identity_key`, `storage_user_assigned_identity_id` + `storage_user_assigned_identity_key`.

**Application Insights (one reference, two outputs).** A single `application_insights = { key = "<appi-key>" }` object resolves BOTH the connection string and the instrumentation key from the `application_insights` supporting variable (the `application_insights` module's output objects expose `connection_string` and `instrumentation_key`). Wire it as an inter-module dependency:

```terraform
application_insights = module.application_insights.application_insights
```

> Name the direct instrumentation-key field `application_insights_instrumentation_key` (not `application_insights_key`) so it doesn't collide visually with the `application_insights.key` reference field.

**Sibling resource-module outputs (inter-module dependencies).** Some keys resolve against ANOTHER resource module's output, not the pattern module. Wire the producing module's output and place the consuming `module` block AFTER it so Terraform infers order:

```terraform
service_plans        = module.app_service_plan.app_service_plans      # service_plan_key → plan resource_id
application_insights = module.application_insights.application_insights
```

**Private endpoint DNS zones (key → zone resource ID).** Private-endpoint modules expose a `private_dns_zone = { resource_ids, keys }` sub-object per endpoint. `keys` resolve via the pattern's **combined** zone map (pattern-managed zones + BYO zone links), so wire `combined_private_dns_zones_resource_ids` (NOT the plain `private_dns_zones` output):

```terraform
private_dns_zones = module.<pattern_module>.combined_private_dns_zones_resource_ids
```

```terraform
private_endpoints = {
  pe-<resource> = {
    vnet_key   = "<vnet-key>"
    subnet_key = "PESubnet"
    private_dns_zone = {
      keys = ["pvt-dns-zone-azurewebsites"]   # key into private_dns_zones (combined map)
      # resource_ids = ["/subscriptions/.../privateDnsZones/privatelink.azurewebsites.net"]
    }
  }
}
```

**Customer-managed key (Key Vault + key + identity by key).** When a module exposes `customer_managed_key`, it follows a triple key-reference convention so the encryption key, its Key Vault, and the accessing identity all resolve from pattern outputs. Wire the pattern's `key_vaults` output (and the already-wired `managed_identities`):

```terraform
module "<name>" {
  source = "../modules/<name>"

  # ...
  key_vaults         = module.<pattern_module>.key_vaults          # customer_managed_key.key_vault_key / key_key
  managed_identities = module.<pattern_module>.managed_identities   # customer_managed_key.user_assigned_identity.key
}
```

The module resolves `key_vault_resource_id` ← `coalesce(direct, key_vaults[key_vault_key].resource_id)`, the key name ← `key_key` (derived from `key_vaults[key_vault_key].keys[key_key].versionless_id`, since the pattern output exposes `versionless_id` not `name`) → direct `key_name`, and the UAMI ← `user_assigned_identity.key` → direct `resource_id`. In `terraform.tfvars`:

```terraform
customer_managed_key = {
  key_vault_key = "<kv-key>"   # key into key_vaults (resolved to its resource_id)
  key_key       = "<key-key>"  # key into key_vaults[key_vault_key].keys (resolved to the key name)
  user_assigned_identity = {
    key = "<uami-key>"          # key into managed_identities (resolved to its resource_id)
  }
}
```

### Canonical descriptions for module-special pattern fields

These fields do **not** exist in the wrapped AVM/azurerm/azapi source — they are the repo's cross-reference/standard pattern fields. The **creator** skill copies all other field descriptions verbatim from the source, but defers to the **wirer** skill (this list) for the wording of these fields. Use these exact descriptions in the module's heredoc, each marked `**Pattern cross-reference**` where it resolves a key:

- `resource_group_key` - (Optional) **Pattern cross-reference**: the key of a resource group in the `resource_groups` variable (created by the foundation/pattern module). Resolved to the resource group resource ID / name. At least one of `resource_group_key` or `resource_group_name` must be provided.
- `network_configuration` - (Optional) VNet integration target. Provide either the key-based references or a direct `subnet_resource_id`.
  - `vnet_key` - (Optional) **Pattern cross-reference**: the key of a virtual network in the `virtual_networks` variable.
  - `subnet_key` - (Optional) **Pattern cross-reference**: the key of a subnet within the VNet identified by `vnet_key`.
  - `subnet_resource_id` - (Optional) The subnet resource ID, used directly. Fallback when `vnet_key`/`subnet_key` are not provided.
- `managed_identities.user_assigned_keys` - (Optional) **Pattern cross-reference**: the keys of managed identities in the `managed_identities` variable, resolved to UAMI resource IDs and merged with `user_assigned_resource_ids`. Defaults to `[]`.
- `diagnostic_settings.workspace_key` - (Optional) **Pattern cross-reference**: the key of a Log Analytics workspace in the `log_analytics_workspaces` variable, resolved to its resource ID. Used when `workspace_resource_id` is not set.
- `diagnostic_settings.use_default_log_analytics` - (Optional) When `true` (and neither `workspace_resource_id` nor `workspace_key` is set), uses the first workspace in the `log_analytics_workspaces` variable. Defaults to `false`. A workspace is not required — storage account, event hub, or marketplace destinations are also valid.
- `role_assignments.managed_identity_key` - (Optional) **Pattern cross-reference**: the key of a managed identity in the `managed_identities` variable, resolved to its principal ID. Sets `principal_type` to `ServicePrincipal`. Mutually exclusive with `principal_id` and `assign_to_caller`.
- `role_assignments.assign_to_caller` - (Optional) When `true`, automatically uses the object ID of the identity running Terraform as the principal. Mutually exclusive with `principal_id` and `managed_identity_key`. Defaults to `false`.
- `service_plan_key` - (Optional) **Pattern cross-reference**: the key of an App Service Plan in the `service_plans` variable, resolved to its `resource_id`. Used when the direct `service_plan_resource_id` is not set.
- `storage_account_key` - (Optional) **Pattern cross-reference**: the key of a storage account in the `storage_accounts` variable, resolved to its `name`. Used when the direct `storage_account_name` is not set.
- `key_vault_reference_identity_key` / `storage_user_assigned_identity_key` - (Optional) **Pattern cross-reference**: the key of a managed identity in the `managed_identities` variable, resolved to its UAMI `resource_id`. Used when the matching direct field is not set.
- `certificates.key_vault_key` - (Optional) **Pattern cross-reference**: the key of a Key Vault in the `key_vaults` variable, resolved to its `resource_id`. Used when the direct `key_vault_id` is not set.
- `customer_managed_key` - (Optional) Customer-managed key encryption configuration. Provide either the key-based references or the direct resource IDs / names.
  - `key_vault_key` - (Optional) **Pattern cross-reference**: the key of a Key Vault in the `key_vaults` variable, resolved to its `resource_id`. Used when the direct `key_vault_resource_id` is not set.
  - `key_key` - (Optional) **Pattern cross-reference**: the key of a key in the referenced Key Vault's `keys` map (`key_vaults[key_vault_key].keys`), resolved to the key name (derived from the key's `versionless_id`). Used when the direct `key_name` is not set.
  - `user_assigned_identity.key` - (Optional) **Pattern cross-reference**: the key of a managed identity in the `managed_identities` variable, resolved to its UAMI `resource_id`. Used when the direct `user_assigned_identity.resource_id` is not set.
- `application_insights.key` - (Optional) **Pattern cross-reference**: the key of an Application Insights component in the `application_insights` variable, resolved to its `connection_string` and `instrumentation_key`. Used when the direct values are not set.
- `private_endpoints.<pe>.private_dns_zone` - (Optional) Private DNS zones for the endpoint, resolved to the wrapped module's `private_dns_zone_resource_ids`.
  - `resource_ids` - (Optional) A set of private DNS zone resource IDs, used directly.
  - `keys` - (Optional) **Pattern cross-reference**: a set of keys from the `private_dns_zones` variable (the pattern's `combined_private_dns_zones_resource_ids`), each resolved to a DNS zone resource ID and merged with `resource_ids`.

> When a pattern field changes the semantics of a source field (e.g. `principal_id` becomes optional and mutually exclusive with `managed_identity_key`/`assign_to_caller`), update that source field's description to note the mutual exclusivity.

## Step 4 — Add a `terraform.tfvars` Example (`<env>/terraform.tfvars`)

Add a commented, conventional example under a section header, mirroring existing entries (commented by default unless the user wants it active). Include `# TODO` markers for values the user must change and inline comments explaining cross-reference key formats.

```terraform
# --------------------------------------------------------------------------
# <Resource>
# --------------------------------------------------------------------------
<resources> = {
  <example-key> = {
    name               = "<example-name>"
    resource_group_key = "<rg-key>"
    # ... other fields with TODO/explanatory comments ...
  }
}
```

## Step 5 — Ensure Providers Exist

Confirm the environment can satisfy the module's providers:

- **`<env>/terraform.tf`** `required_providers` must include what the module uses:
  - azurerm → `hashicorp/azurerm ~> 4.0`
  - azapi → `Azure/azapi ~> 2.0`
- **`<env>/providers.tf`** must configure them (e.g. `provider "azapi" { subscription_id = var.subscription_id }`).

Most root environments already declare `azurerm` and `azapi`; only add a provider if a genuinely new one is introduced.

## Step 6 — Validate

```pwsh
terraform -chdir=<env> fmt
terraform -chdir=<env> validate
```

Optionally run `terraform -chdir=<env> plan` to confirm the resources resolve and cross-references bind. Resolve any errors (common ones: wrapper variable type drift, missing pattern output wiring, wrong `location`, unresolved cross-reference keys).

### Troubleshooting common `plan`/`apply` errors

These surface only at `plan`/`apply` (not `validate`). When they trace back to the **module's** `main.tf`, fix them there (creator territory) but they are routinely hit while validating wiring:

- **`Call to function "setunion" failed: given sets must all have compatible element types`** (e.g. resolving `private_dns_zone.keys`). The pattern output (`combined_private_dns_zones_resource_ids`, `key_vaults`, etc.) is typed as an **object** (fixed keys), so a dynamic index `var.<supporting>[k]` yields a non-`string` element type. Wrap the lookup in `tostring(...)` inside the comprehension:
  ```terraform
  toset([for k in coalesce(try(pe.private_dns_zone.keys, null), toset([])) : tostring(var.private_dns_zones[k])])
  ```
- **`Inconsistent conditional result types` / `Type mismatch for object attribute`** (e.g. `retry`, `timeouts`). A `each.value.<obj> != null ? each.value.<obj> : { ...partial... }` ternary fails because the literal false branch doesn't match the full object type (missing optional attributes, or `["x"]` tuple vs `list(string)`). Don't conditionalize in `main.tf` — give the **variable** a complete default via `optional(object({...}), { <required fields> })` and pass it straight through (`retry = each.value.retry`). Mirror the same default in the wrapper variable so both levels agree.
- **`Invalid template interpolation value` / `expression result is null`** from inside the wrapped AVM module (e.g. `avm-res-web-site` Logic App builds `AzureWebJobsStorage=...AccountKey=${var.storage_account_access_key}`). Some AVM code paths hardcode connection-string auth and don't support managed identity — e.g. the **Logic App** path requires a non-null `storage_account_access_key` even when `storage_uses_managed_identity = true` (which only affects the Function App path). If the backing storage account has `shared_access_key_enabled = false`, there is no key to supply; surface this AVM constraint to the user rather than working around it in the wiring.

## Checklist

- [ ] Wrapper variable added to `<env>/variables.tf`, type matches the module.
- [ ] `module` block added to `<env>/main.tf` with all supporting/cross-ref inputs wired from pattern/other modules.
- [ ] Network modules wire `virtual_networks` (for `network_configuration` vnet_key/subnet_key resolution).
- [ ] Diagnostics modules wire `log_analytics_workspaces = { default = module.<pattern>.log_analytics_workspace }` (for `use_default_log_analytics` / `workspace_key`).
- [ ] Role-assignment modules wire `managed_identities` (for `managed_identity_key` → `principal_id`; supports `assign_to_caller`).
- [ ] Identity/storage/key-vault/app-insights/service-plan/PE-DNS cross-refs wired: `managed_identities` (`*_identity_key`), `storage_accounts` (`storage_account_key`), `key_vaults` (`certificates.key_vault_key`, `customer_managed_key.key_vault_key` / `key_key`), `application_insights` (`application_insights.key`), `service_plans` (`service_plan_key`), `private_dns_zones = module.<pattern>.combined_private_dns_zones_resource_ids` (`private_dns_zone.keys`).
- [ ] Sibling-module dependencies wired from the producing module's output, with the consuming `module` block placed after it.
- [ ] Example added to `<env>/terraform.tfvars` with TODO markers.
- [ ] Providers present in `<env>/terraform.tf` + `<env>/providers.tf`.
- [ ] `terraform fmt` clean and `terraform validate` passes.

## Anti-Patterns to Avoid

- ❌ Declaring the wrapper variable with a different/loosened type than the module's primary variable.
- ❌ Passing raw `var.*` for cross-references instead of the pattern-module output (`module.<pattern>.<output>`).
- ❌ Editing the module's own files here — that's the creator skill's job.
- ❌ Hardcoding subscription IDs, resource group names, or resource IDs in `main.tf`.
- ❌ Forgetting `location = "global"` for global control-plane resources.
- ❌ Forgetting to wire `virtual_networks` (for `network_configuration` subnet resolution) or `log_analytics_workspaces` (for `use_default_log_analytics` / `workspace_key`) when the module declares those supporting variables.
- ❌ Forgetting to wire `managed_identities` when the module's `role_assignments` support `managed_identity_key`, or omitting `assign_to_caller` / `managed_identity_key` when copying the `role_assignments` type.
- ❌ Dropping the `use_default_log_analytics`, `workspace_key`, or `subnet_resource_id` fields when copying the module's `diagnostic_settings` / `network_configuration` type into the wrapper variable.
- ❌ Wiring the plain `private_dns_zones` pattern output for PE DNS-zone key resolution — use `combined_private_dns_zones_resource_ids` (it includes BYO zone links).
- ❌ Placing a consuming `module` block before the sibling module it depends on (e.g. `web_site` before `app_service_plan` / `application_insights`).
