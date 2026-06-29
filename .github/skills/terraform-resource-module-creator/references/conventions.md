# Module Conventions

Shared conventions every resource module in `modules/` must follow. The reference patterns derive from a native azurerm resource (e.g. `disk_encryption_set`) and azapi parent/child resources (e.g. `communication_services` / `email_communication_services`).

## File: `terraform.tf`

Pin Terraform and provider versions. Include only the providers the module actually uses.

```terraform
terraform {
  required_version = ">= 1.13, < 2.0"

  required_providers {
    # azurerm path
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    # azapi path
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
  }
}
```

## File: `variables.tf`

### Primary variable

- Named after the resource, **plural snake_case** (e.g. `disk_encryption_sets`, `communication_services`).
- Type `map(object({...}))`, `default = {}`.
- The map **key is arbitrary** (used by `for_each` and for downstream cross-references) — note this in the description.
- Use `optional(...)` with sensible defaults for non-required fields.
- A heredoc `<<-EOT ... EOT` description that documents **every** field as a markdown bullet list, including:
  - `(Required)` / `(Optional)` marker and default.
  - `**Pattern cross-reference**` callouts for any field that resolves a key from another variable.
  - A `> **Downstream references:**` note listing how other modules reference this one by map key.
  - A `> **Pattern note:**` for location/tags defaults.

### Heredoc description structure (line-by-line, verbatim passthrough)

The heredoc is a **nested bullet list mirroring the object tree** — never squeeze a map/object and its sub-fields into one line, and never merge a bold section header into a field's description line.

- **One bullet per field.** Every top-level field is a top-level bullet `- \`field\` - (Optional) <description>`. Each nested sub-field is a bullet indented two spaces under its parent, recursively down to scalars (e.g. `source.source_uri`, `key_vault_secret_reference.secret_uri`).
- **No merged headers.** Do **not** write `**Role assignments** - \`role_assignments\` is a map ...`. Write `- \`role_assignments\` - (Optional) A map of ...`. Avoid standalone bold group headers too (`**Core settings**`, `**Managed Instance settings**`) — the reference modules (`application_insights`, `ptn-lza-ntwk-shared-services`) use a flat bullet list, optionally separated by blank lines for readability.
- **Verbatim passthrough.** Copy each field's description **verbatim from the wrapped source's** variable/input docs (the AVM module's `variables.tf` / registry inputs, or the azurerm/azapi resource argument reference). Preserve `(Required)`/`(Optional)`, allowed values, defaults, and caveats (e.g. "Only applicable when `os_type` is `WindowsManagedInstance`."). Do **not** paraphrase or invent wording for fields that exist in the source.
- **For a parent object**, use the source's lead-in (e.g. "Controls the managed identity configuration on this resource. The following properties can be specified:") then nest its sub-fields.
- **Author descriptions ONLY for module-special fields** — fields that do not exist in the wrapped source because they are the repo's cross-reference/standard pattern (`resource_group_key`, `*_key` / `*_keys`, `network_configuration.vnet_key`/`subnet_key`/`subnet_resource_id`, `managed_identities.user_assigned_keys`, `diagnostic_settings.workspace_key` / `use_default_log_analytics`, `role_assignments.managed_identity_key` / `assign_to_caller`). Mark these `**Pattern cross-reference**`. (The exact wording for these pattern fields is owned by the **terraform_resource_module_wirer** skill — keep it consistent with that skill.)

Example (correct shape):

```markdown
- `role_assignments` - (Optional) A map of role assignments to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  - `role_definition_id_or_name` - (Required) The ID or name of the role definition to assign to the principal.
  - `principal_id` - (Optional) The ID of the principal to assign the role to. Mutually exclusive with `managed_identity_key` and `assign_to_caller`.
  - `managed_identity_key` - (Optional) The key of a managed identity in the `managed_identities` variable, resolved to its principal ID. Mutually exclusive with `principal_id` and `assign_to_caller`.
  - `assign_to_caller` - (Optional) When `true`, automatically uses the object ID of the identity running Terraform as the principal. Defaults to `false`.
```

### Exhaustive property coverage

The primary variable must expose **every** non-read-only property the resource supports, recursively including nested sub-properties. Translate the schema tree you built in Step 2 into the object type:

| Schema shape | HCL type |
|--------------|----------|
| Required scalar | `name = string` (no `optional`) |
| Optional scalar w/ default | `optional(string, "AzureManaged")` |
| Optional scalar, no default | `optional(string)` (resolves to `null`) |
| Optional bool/number | `optional(bool, false)` / `optional(number, 30)` |
| Optional nested object | `optional(object({ ...full sub-tree... }), {})` |
| Optional list of objects | `optional(list(object({ ... })), [])` |
| Optional set of objects/keys | `optional(set(object({ ... })), [])` |
| Enum | scalar typed `string`; document allowed values in the heredoc and optionally add a `validation` block |
| Cross-reference (ID/key) | the `resource_ids` + `keys` dual-field object (see below) |

Rules:

- **Recurse fully.** For every nested object, expand its sub-properties — and the sub-properties of *those* objects — down to scalars. Never collapse a nested block to `any` or omit its inner fields.
- **Mirror defaults from the schema.** When the platform default is known, set it as the `optional(..., <default>)` second argument so the module is non-surprising.
- **Read-only / computed** properties (e.g. `provisioningState`, generated IDs, immutable system fields) are **not** inputs — surface them via outputs (the raw object already does this).
- **Document each field** (including nested ones) in the heredoc with its `(Required)`/`(Optional)`, default, type, and allowed values.
- When a property's name differs between Terraform/AVM and the ARM/azapi body, use snake_case in the variable and map it to the camelCase body key in `main.tf`.

> **Completeness gate:** Before finishing, diff your variable's field set against the schema. Every non-deprecated, non-read-only property — at every nesting depth — must be present. If you intentionally omit one, note why in the heredoc.

### Standard object fields (every module)

```terraform
name                = string                       # (Required)
resource_group_key  = optional(string)             # key into var.resource_groups
resource_group_name = optional(string)             # overrides resource_group_key
location            = optional(string)             # falls back to var.location
tags                = optional(map(string), {})    # merged with var.tags
```

> At least one of `resource_group_key` / `resource_group_name` must be provided. For `global` control-plane resources, default `location` to `"global"`.

### Managed identity field (when the resource supports identity)

```terraform
managed_identities = optional(object({
  system_assigned            = optional(bool, false)
  user_assigned_resource_ids = optional(set(string), [])
  user_assigned_keys         = optional(set(string), [])   # keys into var.managed_identities
}), {})
```

### Cross-reference field pattern

When a field links to another resource managed elsewhere, expose **both** a direct ID set and a key set:

```terraform
linked_x = optional(object({
  resource_ids = optional(set(string), [])   # direct resource IDs
  keys         = optional(set(string), [])   # keys into a supporting var, resolved to IDs
}), {})
```

### Supporting variables

```terraform
variable "location" {
  description = "Default location fallback when a resource does not set location."
  type        = string
  # `default = "global"` for global control-plane resources; otherwise no default.
}

variable "resource_groups" {
  description = "Resource groups output map from the foundation/pattern module. Used to resolve resource_group_key."
  type        = any
  default     = {}
}

variable "managed_identities" {
  description = "Managed identities output map from the foundation/pattern module. Used to resolve user_assigned_keys to UAMI resource IDs."
  type        = any
  default     = {}
}

variable "tags" {
  description = "Default tags to merge with per-resource tags."
  type        = map(string)
  default     = {}
}

# Add one `any`-typed variable per cross-reference (e.g. key_vaults, email_communication_services).
```

> Supporting variables that receive **foundation/pattern module outputs** are typed `any` (their shape comes from the upstream module). The primary variable is strongly typed.

## File: `main.tf`

### Shared resolution helpers

```terraform
location = coalesce(each.value.location, var.location)
tags     = merge(var.tags, each.value.tags)
```

### Resource group resolution

- **azurerm**:
  ```terraform
  resource_group_name = coalesce(each.value.resource_group_name, var.resource_groups[each.value.resource_group_key].name)
  ```
- **azapi** (needs the client config data source):
  ```terraform
  data "azurerm_client_config" "current" {}

  parent_id = each.value.resource_group_name != null
    ? "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${each.value.resource_group_name}"
    : var.resource_groups[each.value.resource_group_key].resource_id
  ```

### Managed identity dynamic block (identical for azurerm and azapi)

```terraform
dynamic "identity" {
  for_each = (
    each.value.managed_identities.system_assigned ||
    length(each.value.managed_identities.user_assigned_resource_ids) > 0 ||
    length(each.value.managed_identities.user_assigned_keys) > 0
  ) ? { this = each.value.managed_identities } : {}

  content {
    type = (
      identity.value.system_assigned &&
      (length(identity.value.user_assigned_resource_ids) > 0 || length(identity.value.user_assigned_keys) > 0)
      ? "SystemAssigned, UserAssigned"
      : (length(identity.value.user_assigned_resource_ids) > 0 || length(identity.value.user_assigned_keys) > 0)
      ? "UserAssigned"
      : "SystemAssigned"
    )
    identity_ids = setunion(
      identity.value.user_assigned_resource_ids,
      toset([for key in identity.value.user_assigned_keys : var.managed_identities[key].resource_id])
    )
  }
}
```

### Cross-reference resolution

Merge direct resource IDs with key-resolved IDs:

```terraform
setunion(
  each.value.linked_x.resource_ids,
  toset([for key in each.value.linked_x.keys : var.<supporting_var>[key].<attr>])
)
```

For a compound `"<parent_key>.<child_key>"` reference (as in Communication Services linked domains), resolve against the child resource's own output map (keyed `"<parent_key>|<child_key>"`) that the producing module exposes:

```terraform
toset([
  for key in each.value.linked_domains.keys :
  var.email_services_domains["${split(".", key)[0]}|${split(".", key)[1]}"].id
])
```

> The consumer takes the **child resource output map** as an `any`-typed supporting variable (e.g. `email_services_domains`), not the parent service output. The user-facing key stays dotted (`"<parent>.<child>"`); it is rewritten to the pipe-delimited child output key internally.

## File: `outputs.tf`

**Always expose the raw resource/module object**, keyed by the map key. This is the repo default — prefer it even when a downstream module needs specific attributes (the consumer indexes into the raw object).

```terraform
output "<resources_plural>" {
  value       = azurerm_<type>.this          # native azurerm; or azapi_resource.<name>; or module.<module_name> for AVM wrap
  description = "Map of <resource> keys to their resource objects. Each object includes id, name, and other resource attributes."
}
```

### Child resources get their own raw output

When the module creates **child resources** with a separate `for_each` (e.g. email domains under an email service), expose them as a **separate raw output**, keyed by the flattened compound key (`"<parent_key>|<child_key>"`). Do **not** fold children into a curated parent output.

```terraform
output "<children_plural>" {
  value       = azapi_resource.<child_singular>   # keyed "<parent_key>|<child_key>"
  description = "Map of <child> keys (form `<parent_key>|<child_key>`) to their raw resource objects. Each includes id, name, etc."
}
```

Consumers then resolve a dotted `"<parent>.<child>"` reference by rewriting it to the pipe key and indexing the child output map (see [Cross-reference resolution](#cross-reference-resolution)). Avoid curated/trimmed outputs entirely — raw objects (parent and child) are the convention.

## Naming Summary

| Item | Convention | Example |
|------|-----------|---------|
| Module folder | snake_case, singular or matching resource | `disk_encryption_set`, `communication_services` |
| Primary variable | plural snake_case | `disk_encryption_sets` |
| AVM module label | module folder name / resource name (snake_case) — **never `this`** | `module.application_insights`, `module.app_service_plan` |
| azurerm resource label | `this` (underlying `resource` in a native module) | `azurerm_disk_encryption_set.this` |
| azapi resource label | singular snake_case | `azapi_resource.communication_service` |
| azapi child resource label | singular snake_case | `azapi_resource.email_services_domain` |
| Child output key | `"<parent_key>|<child_key>"` | `"<service-key>|AzureManagedDomain"` |
| Output name | plural snake_case (matches variable) | `disk_encryption_sets` |
