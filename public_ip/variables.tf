variable "public_ips" {
  type = map(object({
    # --- Standard module fields ---
    name                = string
    resource_group_key  = optional(string)
    resource_group_name = optional(string)
    location            = optional(string)
    tags                = optional(map(string), {})

    # --- Core public IP settings ---
    allocation_method       = optional(string, "Static")
    sku                     = optional(string, "Standard")
    sku_tier                = optional(string, "Regional")
    ip_version              = optional(string, "IPv4")
    zones                   = optional(set(number), [1, 2, 3])
    idle_timeout_in_minutes = optional(number, 4)
    ip_tags                 = optional(map(string), {})

    # --- DNS / FQDN ---
    domain_name_label = optional(string)
    reverse_fqdn      = optional(string)

    # --- Edge zone / prefix ---
    edge_zone           = optional(string)
    public_ip_prefix_id = optional(string)

    # --- DDoS protection ---
    ddos_protection_mode    = optional(string, "VirtualNetworkInherited")
    ddos_protection_plan_id = optional(string)

    # --- Diagnostic settings ---
    diagnostic_settings = optional(map(object({
      name                                     = optional(string, null)
      log_categories                           = optional(set(string), [])
      log_groups                               = optional(set(string), ["allLogs"])
      metric_categories                        = optional(set(string), ["AllMetrics"])
      log_analytics_destination_type           = optional(string, "Dedicated")
      workspace_resource_id                    = optional(string, null)
      workspace_key                            = optional(string)
      use_default_log_analytics                = optional(bool, false)
      storage_account_resource_id              = optional(string, null)
      event_hub_authorization_rule_resource_id = optional(string, null)
      event_hub_name                           = optional(string, null)
      marketplace_partner_resource_id          = optional(string, null)
    })), {})

    # --- Role assignments ---
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = optional(string)
      managed_identity_key                   = optional(string)
      assign_to_caller                       = optional(bool, false)
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})

    # --- Lock ---
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }))
  }))
  default     = {}
  description = <<-EOT
    A map of Azure Public IP Addresses to create using the `Azure/avm-res-network-publicipaddress/azurerm` AVM module.
    The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.

    - `name` - (Required) Name of public IP address resource. The name must be between 3 and 24 characters long and can only contain lowercase letters, numbers and dashes.
    - `resource_group_key` - (Optional) **Pattern cross-reference**: the key of a resource group in the `resource_groups` variable (created by the spoke/pattern module). Resolved to the resource group name. At least one of `resource_group_key` or `resource_group_name` must be provided.
    - `resource_group_name` - (Optional) The resource group where the resources will be deployed. Overrides `resource_group_key`. At least one of `resource_group_key` or `resource_group_name` must be provided.
    - `location` - (Optional) The Azure location where the resources will be deployed. Defaults to `var.location`.
    - `tags` - (Optional) A mapping of tags merged with `var.tags`. Defaults to `{}`.

    - `allocation_method` - (Optional) The allocation method to use. Possible values are `Static` and `Dynamic`. Defaults to `Static`.
    - `sku` - (Optional) The SKU of the public IP address. Possible values are `Basic` and `Standard`. Defaults to `Standard`.
    - `sku_tier` - (Optional) The tier of the SKU of the public IP address. Possible values are `Global` and `Regional`. Defaults to `Regional`.
    - `ip_version` - (Optional) The IP version to use. Possible values are `IPv4` and `IPv6`. Defaults to `IPv4`.
    - `zones` - (Optional) A set of availability zones to use. Defaults to `[1, 2, 3]`.
    - `idle_timeout_in_minutes` - (Optional) The idle timeout in minutes. Defaults to `4`.
    - `ip_tags` - (Optional) The IP tags for the public IP address. Defaults to `{}`.

    - `domain_name_label` - (Optional) The domain name label for the public IP address.
    - `reverse_fqdn` - (Optional) The reverse FQDN for the public IP address. This must be a valid FQDN. If you specify a reverse FQDN, you cannot specify a DNS name label. Not all regions support this.

    - `edge_zone` - (Optional) The edge zone to use for the public IP address. This is required if `sku_tier` is set to `Global`.
    - `public_ip_prefix_id` - (Optional) The ID of the public IP prefix to associate with the public IP address.

    - `ddos_protection_mode` - (Optional) The DDoS protection mode to use. Possible values are `Disabled`, `Enabled` and `VirtualNetworkInherited`. Defaults to `VirtualNetworkInherited`.
    - `ddos_protection_plan_id` - (Optional) The ID of the DDoS protection plan to associate with the public IP address. This is required if `ddos_protection_mode` is set to `Standard`.

    - `diagnostic_settings` - (Optional) A map of diagnostic settings to create on the public IP address. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time. Defaults to `{}`.
      - `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
      - `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
      - `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
      - `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
      - `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
      - `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
      - `workspace_key` - (Optional) **Pattern cross-reference**: the key of a Log Analytics workspace in the `log_analytics_workspaces` variable, resolved to its resource ID. Used when `workspace_resource_id` is not set.
      - `use_default_log_analytics` - (Optional) When `true` (and neither `workspace_resource_id` nor `workspace_key` is set), uses the first workspace in the `log_analytics_workspaces` variable. Defaults to `false`. A workspace is not required — storage account, event hub, or marketplace destinations are also valid.
      - `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
      - `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
      - `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
      - `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic Logs.

    - `role_assignments` - (Optional) A map of role assignments to create on the public IP address. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time. Defaults to `{}`.
      - `role_definition_id_or_name` - (Required) The ID or name of the role definition to assign to the principal.
      - `principal_id` - (Optional) The ID of the principal to assign the role to. Mutually exclusive with `managed_identity_key` and `assign_to_caller`.
      - `managed_identity_key` - (Optional) **Pattern cross-reference**: the key of a managed identity in the `managed_identities` variable, resolved to its principal ID. Sets `principal_type` to `ServicePrincipal`. Mutually exclusive with `principal_id` and `assign_to_caller`.
      - `assign_to_caller` - (Optional) When `true`, automatically uses the object ID of the identity running Terraform as the principal. Mutually exclusive with `principal_id` and `managed_identity_key`. Defaults to `false`.
      - `description` - (Optional) The description of the role assignment.
      - `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false. Only set this to `true` if you are assigning a role to a service principal.
      - `condition` - (Optional) The condition which will be used to scope the role assignment.
      - `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are `2.0`.
      - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
      - `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

    - `lock` - (Optional) Controls the Resource Lock configuration for this resource.
      - `kind` - (Required) The type of lock. Possible values are `CanNotDelete` and `ReadOnly`.
      - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.

    > **Downstream references:** Other modules reference this resource via the map key, e.g. an application gateway or NAT gateway reading `public_ips.<key>.public_ip_id` or `public_ips.<key>.public_ip_address`.

    > **Pattern note:** If `location` is not specified, defaults to `var.location`. Tags in `tags` are merged with `var.tags`.
  EOT
}

variable "location" {
  description = "Default location fallback when a public IP address does not set location."
  type        = string
}

variable "resource_groups" {
  description = "Resource groups output map from spoke module. Used to resolve resource_group_key to name."
  type        = any
  default     = {}
}

variable "log_analytics_workspaces" {
  description = "Log Analytics workspaces output map from the spoke module. Used to resolve diagnostic_settings.workspace_key to a workspace resource ID."
  type        = any
  default     = {}
}

variable "managed_identities" {
  description = "Managed identities output map from the spoke module. Used to resolve role_assignments.managed_identity_key to a principal ID."
  type        = any
  default     = {}
}

variable "enable_telemetry" {
  description = "Controls whether telemetry is enabled for the AVM module. See https://aka.ms/avm/telemetryinfo."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Default tags to merge with per-resource tags."
  type        = map(string)
  default     = {}
}
