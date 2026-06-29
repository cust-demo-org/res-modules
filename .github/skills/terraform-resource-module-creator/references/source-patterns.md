# Source Patterns

Three construction paths for a resource module. All share the conventions in [conventions.md](conventions.md); they differ only in how the resource is declared in `main.tf`, the provider in `terraform.tf`, and the resource-group target.

---

## AVM module wrap

Use when an **Azure Verified Module** exists and the user provides/prefers it. The module wraps the AVM module with `for_each`.

**`terraform.tf`** — provider(s) required by the AVM module (usually `azurerm`):

```terraform
terraform {
  required_version = ">= 1.13, < 2.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
```

**`main.tf`** — label the `module` block with the **module folder name / resource name** (snake_case), never `"this"`:

```terraform
module "<module_name>" {   # e.g. module "application_insights", module "app_service_plan"
  source  = "Azure/avm-res-<service>-<type>/azurerm"
  version = "<pinned version>"   # always pin; confirm latest with Terraform MCP

  for_each = var.<resources>

  enable_telemetry    = var.enable_telemetry
  name                = each.value.name
  resource_group_name = coalesce(each.value.resource_group_name, var.resource_groups[each.value.resource_group_key].name)
  location            = coalesce(each.value.location, var.location)

  # Map every supported AVM input explicitly from each.value.*
  # ...

  tags = merge(var.tags, each.value.tags)
}
```

**`outputs.tf`**:

```terraform
output "<resources>" {
  value       = module.<module_name>   # same label used in main.tf, never module.this
  description = "Map of <resource> keys to their AVM module objects (includes resource_id, name, and module outputs)."
}
```

> Add `enable_telemetry` as a supporting variable (`type = bool`) when wrapping AVM modules. Pin the `version`; verify with `get_latest_module_version` / `get_module_details`.

---

## Native azurerm resource

Use when no AVM module exists but a first-class `azurerm_*` resource does. **Reference implementation: `modules/disk_encryption_set`.**

**`terraform.tf`**: `hashicorp/azurerm ~> 4.0`.

**`main.tf`**:

```terraform
resource "azurerm_<type>" "this" {
  for_each = var.<resources>

  name                = each.value.name
  location            = coalesce(each.value.location, var.location)
  resource_group_name = coalesce(each.value.resource_group_name, var.resource_groups[each.value.resource_group_key].name)

  # Map every argument explicitly from each.value.*
  # ...

  tags = merge(var.tags, each.value.tags)

  # dynamic "identity" { ... }   # see conventions.md (when supported)
}
```

**`outputs.tf`**:

```terraform
output "<resources>" {
  value       = azurerm_<type>.this
  description = "Map of <resource> keys to their azurerm_<type> resource objects. Each object includes id, name, and other attributes."
}
```

---

## azapi resource

Use when **no AVM module and no/insufficient azurerm resource** exists (e.g. Communication Services). **Reference implementation: `modules/communication_services`.**

**`terraform.tf`**: `azure/azapi ~> 2.0` (the `azurerm` provider is also needed if you use `azurerm_client_config`).

```terraform
terraform {
  required_version = ">= 1.13, < 2.0"
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
  }
}
```

**`main.tf`**:

```terraform
data "azurerm_client_config" "current" {}

resource "azapi_resource" "<resource_singular>" {
  for_each = var.<resources>

  type      = "Microsoft.<Provider>/<types>@<apiVersion>"   # confirm latest stable API version
  name      = each.value.name
  parent_id = each.value.resource_group_name != null
    ? "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${each.value.resource_group_name}"
    : var.resource_groups[each.value.resource_group_key].resource_id
  location  = coalesce(each.value.location, var.location)

  # Map every variable field explicitly into the body. Property names are camelCase per the ARM schema.
  body = {
    properties = {
      # exampleProperty = each.value.example_property
    }
  }

  tags = merge(var.tags, each.value.tags)

  # dynamic "identity" { ... }   # see conventions.md (when supported)
}
```

**`outputs.tf`**:

```terraform
output "<resources>" {
  value       = azapi_resource.<resource_singular>
  description = "Map of <resource> keys to their azapi_resource objects."
}
```

### azapi specifics

- **Child resources** (e.g. email domains under an email service) are separate `azapi_resource` blocks with `parent_id = azapi_resource.<parent>[<key>].id` and `type = "Microsoft.<Provider>/<types>/<childTypes>@<apiVersion>"`. Flatten per-parent child maps into one keyed map (keyed `"<parent_key>|<child_key>"`) for a single `for_each` (see `email_communication_services`).
- A child's `location` should inherit the parent: `location = azapi_resource.<parent>[each.value.service_key].location`.
- Confirm the `type@apiVersion`, body property names, enums, and identity support against the ARM template reference and azapi schema tools before writing.
- **Expose child resources as their own raw output** keyed by the compound `"<parent_key>|<child_key>"`, alongside the parent's raw output. Do **not** build a curated/trimmed output. A sibling module consumes the child output map (as an `any`-typed variable) and resolves a dotted `"<parent>.<child>"` reference by rewriting it to the pipe key:

  ```terraform
  # producing module: outputs.tf
  output "email_communication_services" {
    value = azapi_resource.email_communication_service          # keyed "<service_key>"
  }
  output "email_services_domains" {
    value = azapi_resource.email_services_domain                # keyed "<service_key>|<domain_key>"
  }

  # consuming module: main.tf
  var.email_services_domains["${split(".", key)[0]}|${split(".", key)[1]}"].id
  ```
