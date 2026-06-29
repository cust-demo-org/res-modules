variable "email_communication_services" {
  type = map(object({
    name                = string
    resource_group_key  = optional(string)
    resource_group_name = optional(string)
    location            = optional(string, "global")
    data_location       = string
    domains = optional(map(object({
      name                     = optional(string, "AzureManagedDomain")
      domain_management        = optional(string, "AzureManaged")
      user_engagement_tracking = optional(string, "Disabled")
      tags                     = optional(map(string), {})
    })), { AzureManagedDomain = {} })
    tags = optional(map(string), {})
  }))
  default     = {}
  description = <<-EOT
    A map of Azure Email Communication Services to create using the `azapi_resource` (`Microsoft.Communication/emailServices`).
    The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.

    - `name` - (Required) The name of the Email Communication Service. Changing this forces a new resource to be created.
    - `resource_group_key` - (Optional) **Pattern cross-reference**: the key of a resource group in the `resource_groups` variable (created by `spoke_network_and_share_services_pattern`). Resolved to the resource group `id` and `name`. At least one of `resource_group_key` or `resource_group_name` must be provided.
    - `resource_group_name` - (Optional) The name of the resource group. Used in outputs. Overrides the name resolved from `resource_group_key`.
    - `location` - (Optional) The Azure region for the Email Communication Service control-plane resource. Defaults to `"global"` (the only currently supported control-plane region for Email Communication Services).
    - `data_location` - (Required) The geography where the Email Communication Service stores its data at rest. Examples: `United States`, `Europe`, `Asia Pacific`, `Australia`, `United Kingdom`, `France`, `Germany`, `Norway`, `Switzerland`, `UAE`, `Korea`, `India`, `Brazil`, `Canada`, `Japan`, `Africa`.
    - `domains` - (Optional) A map of email domains to create under this Email Communication Service (`Microsoft.Communication/emailServices/domains`). The domain resource IDs are what a Communication Service links to via `linked_domains`. Defaults to a single Azure-managed domain (`{ AzureManagedDomain = {} }`). Set to `{}` to create no domains.
      - `name` - (Optional) The domain name. For `AzureManaged` domains this must be `AzureManagedDomain`. For customer-managed domains, use the fully-qualified custom domain (e.g. `contoso.com`). Defaults to `AzureManagedDomain`.
      - `domain_management` - (Optional) How the domain is managed. Possible values are `AzureManaged`, `CustomerManaged`, and `CustomerManagedInExchangeOnline`. Defaults to `AzureManaged`.
      - `user_engagement_tracking` - (Optional) Whether user engagement tracking is enabled. Possible values are `Enabled` and `Disabled`. Defaults to `Disabled`.
      - `tags` - (Optional) A mapping of tags merged with `var.tags`. Defaults to `{}`.
    - `tags` - (Optional) A mapping of tags merged with `var.tags`. Defaults to `{}`.

    > **Downstream references:** Other modules may reference this resource via the map key:
    > - `email_communication_services.<cs_key>` → key from this map (exposed in the module output, including the created domain resource IDs).

    > **Pattern note:** If `location` is not specified, defaults to `"global"`. Tags in `tags` are merged with `var.tags`.
  EOT
}

variable "location" {
  description = "Default location fallback. Email Communication Services control-plane resources are typically `global`."
  type        = string
  default     = "global"
}

variable "resource_groups" {
  description = "Resource groups output map from spoke module. Used to resolve resource_group_key to resource group id and name."
  type        = any
  default     = {}
}

variable "tags" {
  description = "Default tags to merge with per-resource tags."
  type        = map(string)
  default     = {}
}
