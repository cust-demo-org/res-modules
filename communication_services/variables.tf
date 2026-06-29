variable "communication_services" {
  type = map(object({
    name                  = string
    resource_group_key    = optional(string)
    resource_group_name   = optional(string)
    location              = optional(string, "global")
    data_location         = string
    disable_local_auth    = optional(bool, true)
    public_network_access = optional(string, "Disabled")
    linked_domains = optional(object({
      resource_ids = optional(set(string), [])
      keys         = optional(set(string), [])
    }), {})
    managed_identities = optional(object({
      system_assigned            = optional(bool, false)
      user_assigned_resource_ids = optional(set(string), [])
      user_assigned_keys         = optional(set(string), [])
    }), {})
    tags = optional(map(string), {})
  }))
  default     = {}
  description = <<-EOT
    A map of Azure Communication Services to create using the `azapi_resource` (`Microsoft.Communication/communicationServices`).
    The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.

    - `name` - (Required) The name of the Communication Service. Changing this forces a new resource to be created.
    - `resource_group_key` - (Optional) **Pattern cross-reference**: the key of a resource group in the `resource_groups` variable (created by `spoke_network_and_share_services_pattern`). Resolved to the resource group `id` and `name`. At least one of `resource_group_key` or `resource_group_name` must be provided.
    - `resource_group_name` - (Optional) The name of the resource group. Used in outputs. Overrides the name resolved from `resource_group_key`.
    - `location` - (Optional) The Azure region for the Communication Service control-plane resource. Defaults to `"global"` (the only currently supported control-plane region for Communication Services).
    - `data_location` - (Required) The geography where the Communication Service stores its data at rest. Examples: `United States`, `Europe`, `Asia Pacific`, `Australia`, `United Kingdom`, `France`, `Germany`, `Norway`, `Switzerland`, `UAE`, `Korea`, `India`, `Brazil`, `Canada`, `Japan`, `Africa`.
    - `disable_local_auth` - (Optional) When set to `true`, disables local (access-key) authentication and requires Microsoft Entra ID authentication. Defaults to `true`.
    - `public_network_access` - (Optional) Whether requests from the public network are allowed. Possible values are `Enabled` and `Disabled`. Defaults to `Disabled`.
    - `linked_domains` - (Optional) Email domains to link to the Communication Service. Defaults to `{}`.
      - `resource_ids` - (Optional) A set of resource IDs of `Microsoft.Communication/emailServices/domains` to link directly. Defaults to `[]`.
      - `keys` - (Optional) **Pattern cross-reference**: a set of keys from the `email_communication_services` variable. Each key is resolved to an email domain resource ID and merged with `resource_ids`. Each key must be in the form `"<email_communication_services_key>.<domain_key>"`, which links a **single** email domain by its key in the service's `domains` map (e.g. `"aecs-meralion.AzureManagedDomain"`). Defaults to `[]`.
    - `managed_identities` - (Optional) Managed identity configuration for the Communication Service. Defaults to `{}`.
      - `system_assigned` - (Optional) Whether to enable system-assigned managed identity. Defaults to `false`.
      - `user_assigned_resource_ids` - (Optional) A set of user-assigned managed identity resource IDs to assign directly. Defaults to `[]`.
      - `user_assigned_keys` - (Optional) **Pattern cross-reference**: a set of keys from the `managed_identities` variable. Resolved to user-assigned managed identity resource IDs and merged with `user_assigned_resource_ids`. Defaults to `[]`.
    - `tags` - (Optional) A mapping of tags merged with `var.tags`. Defaults to `{}`.

    > **Downstream references:** Other modules may reference this resource via the map key:
    > - `communication_services.<cs_key>` → key from this map (exposed in the module output).

    > **Pattern note:** If `location` is not specified, defaults to `"global"`. Tags in `tags` are merged with `var.tags`.
  EOT
}

variable "location" {
  description = "Default location fallback. Communication Services control-plane resources are typically `global`."
  type        = string
  default     = "global"
}

variable "resource_groups" {
  description = "Resource groups output map from spoke module. Used to resolve resource_group_key to resource group id and name."
  type        = any
  default     = {}
}

variable "email_services_domains" {
  description = "Email domains output map from the email_communication_services module (keyed `<service_key>|<domain_key>`). Used to resolve linked_domains.keys to email domain resource IDs."
  type        = any
  default     = {}
}

variable "managed_identities" {
  description = "Managed identities output map from spoke module. Used to resolve user_assigned_keys to UAMI resource IDs."
  type        = any
  default     = {}
}

variable "tags" {
  description = "Default tags to merge with per-resource tags."
  type        = map(string)
  default     = {}
}
