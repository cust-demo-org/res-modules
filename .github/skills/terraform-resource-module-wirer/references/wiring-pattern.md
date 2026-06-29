# Wiring Pattern — Worked Examples

Concrete templates for wiring a resource module into a root environment. There are three scenarios depending on whether the environment is built on a foundation pattern module:

- **Scenario 1 — Spoke shared-services pattern** (`../modules/ptn-lza-ntwk-shared-services`): the most common app/workload environment.
- **Scenario 2 — Connectivity hub pattern** (`../modules/ptn-lzp-connectivity-hub-vnet`): the platform connectivity environment.
- **Scenario 3 — No pattern module**: a plain environment that owns its own resource groups / networking; supporting vars wire against raw resources, data sources, or root locals.

Throughout, `module.<pattern>` is the foundation module label, `<env>` is the root environment dir, and `<rg-key>` / `<vnet-key>` / `<resource>` are placeholders.

## Scenario 1 — Spoke shared-services pattern

Wire against `module.<spoke_pattern>` (source `../modules/ptn-lza-ntwk-shared-services`), which exposes, among others:

| Output | Use for |
|--------|---------|
| `resource_groups` | resolve `resource_group_key` |
| `managed_identities` | resolve `user_assigned_keys` |
| `key_vaults` | key vault cross-references |
| `virtual_networks` | subnet / vnet cross-references |
| `recovery_services_vaults` | backup cross-references |
| `log_analytics_workspace` | diagnostic settings (`.resource_id`) |

## Example A — Simple module (one pattern output)

Module depends only on resource groups.

**`<env>/main.tf`**
```terraform
module "email_communication_services" {
  source = "../modules/email_communication_services"

  email_communication_services = var.email_communication_services

  resource_groups = module.<spoke_pattern>.resource_groups

  location = "global"   # global control-plane resource
  tags     = var.tags
}
```

## Example B — Module with multiple pattern outputs

**`<env>/main.tf`**
```terraform
module "disk_encryption_set" {
  source = "../modules/disk_encryption_set"

  disk_encryption_sets = var.disk_encryption_sets

  resource_groups    = module.<spoke_pattern>.resource_groups
  key_vaults         = module.<spoke_pattern>.key_vaults
  managed_identities = module.<spoke_pattern>.managed_identities

  location = var.location
  tags     = var.tags
}
```

## Example C — Module that depends on ANOTHER resource module

When a module references resources created by a sibling module, pass that module's **output** directly. Terraform infers ordering. Note that Communication Services links to email **domains** (a child resource), so it consumes the sibling's **child output** (`email_services_domains`), not the parent service output.

**`<env>/main.tf`**
```terraform
module "communication_services" {
  source = "../modules/communication_services"

  communication_services = var.communication_services

  resource_groups        = module.<spoke_pattern>.resource_groups
  email_services_domains = module.email_communication_services.email_services_domains   # sibling child output (keyed "<svc>|<domain>")
  managed_identities     = module.<spoke_pattern>.managed_identities

  location = "global"
  tags     = var.tags
}
```

The `communication_services` map then references the sibling by dotted compound key (rewritten internally to the `<svc>|<domain>` child output key):

**`<env>/terraform.tfvars`**
```terraform
communication_services = {
  <acs-key> = {
    name               = "<acs-name>"
    resource_group_key = "<rg-key>"
    linked_domains = {
      # "<email_service_key>.<domain_key>" — resolved to the domain resource ID by the module
      keys = ["<email-svc-key>.AzureManagedDomain"]
      # resource_ids = ["/subscriptions/.../emailServices/<svc>/domains/AzureManagedDomain"]  # direct alternative
    }
  }
}
```

## Variable sync (Example: `email_communication_services`)

The environment wrapper variable's type must equal the module's primary variable type. Below is the wrapper as it appears in `<env>/variables.tf` — note the **short** description versus the module's full heredoc.

```terraform
variable "email_communication_services" {
  type = map(object({
    name                = string
    resource_group_key  = optional(string)
    resource_group_name = optional(string)
    data_location       = optional(string, "United States")
    tags                = optional(map(string), {})
    domains = optional(map(object({
      name                     = optional(string, "AzureManagedDomain")
      domain_management        = optional(string, "AzureManaged")
      user_engagement_tracking = optional(string, "Disabled")
      tags                     = optional(map(string), {})
    })), { AzureManagedDomain = {} })
  }))
  default     = {}
  description = "Map of Azure Email Communication Services to create. Refer to the module's variable descriptions for complete details."
}
```

## Ordering in `main.tf`

1. Root foundation pattern module (`module.<pattern>`), when present.
2. Resource modules with no inter-module dependencies.
3. Resource modules that depend on other resource modules — placed after their dependency (readability; Terraform resolves the real order from references).

## Scenario 2 — Connectivity hub pattern

Identical wiring shape to Scenario 1, but the foundation module is `module.<hub_pattern>` (source `../modules/ptn-lzp-connectivity-hub-vnet`). Wire each supporting variable to the hub pattern's matching output, e.g.:

```terraform
module "<resource>" {
  source = "../modules/<resource>"

  <resources>      = var.<resources>
  resource_groups  = module.<hub_pattern>.resource_groups
  virtual_networks = module.<hub_pattern>.virtual_networks
  managed_identities = module.<hub_pattern>.managed_identities

  location = var.location
  tags     = var.tags
}
```

Use whichever outputs the hub pattern exposes (resource groups, hub vnets, DNS zones, etc.); the cross-reference tables in `SKILL.md` apply the same way.

## Scenario 3 — No pattern module

When the root environment has no foundation pattern module, supporting variables wire against resources the environment owns directly — raw `azurerm_*` resources, data sources, or root locals — reshaped into the same `{ key = { … } }` maps the module expects.

**`<env>/main.tf`**
```terraform
resource "azurerm_resource_group" "this" {
  for_each = var.resource_groups_in
  name     = each.value.name
  location = var.location
}

module "<resource>" {
  source = "../modules/<resource>"

  <resources> = var.<resources>

  # Reshape owned resources into the map(key => object) the module resolves against.
  resource_groups = {
    for k, rg in azurerm_resource_group.this : k => { name = rg.name, resource_id = rg.id }
  }
  # Sibling module outputs are still passed directly:
  # email_services_domains = module.email_communication_services.email_services_domains

  location = var.location
  tags     = var.tags
}
```

Keys in `terraform.tfvars` (`resource_group_key`, `vnet_key`, …) index these locally built maps instead of pattern outputs. Cross-reference fields with no local source can pass direct IDs (`*_resource_ids` / `subnet_resource_id`) instead of `*_keys`.
