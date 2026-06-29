variable "app_service_plans" {
  type = map(object({
    # --- Standard module fields ---
    name                = string
    resource_group_key  = optional(string)
    resource_group_name = optional(string)
    location            = optional(string)
    tags                = optional(map(string), {})

    # --- Core App Service Plan settings ---
    os_type                         = string
    sku_name                        = optional(string, "P1v2")
    worker_count                    = optional(number, 3)
    maximum_elastic_worker_count    = optional(number, 3)
    per_site_scaling_enabled        = optional(bool, false)
    premium_plan_auto_scale_enabled = optional(bool, false)
    zone_balancing_enabled          = optional(bool, true)
    app_service_environment_id      = optional(string)
    server_farm_resource_type       = optional(string, "Microsoft.Web/serverfarms@2025-03-01")

    # --- VNet integration (key-based reference to a pattern-managed subnet) ---
    network_configuration = optional(object({
      vnet_key           = optional(string)
      subnet_key         = optional(string)
      subnet_resource_id = optional(string)
    }))

    # --- Managed identity (repo pattern: adds user_assigned_keys) ---
    managed_identities = optional(object({
      system_assigned            = optional(bool, false)
      user_assigned_resource_ids = optional(set(string), [])
      user_assigned_keys         = optional(set(string), [])
    }), {})

    # --- Windows Managed Instance plan settings (os_type = "WindowsManagedInstance") ---
    rdp_enabled = optional(bool)
    plan_default_identity = optional(object({
      identity_type                      = optional(string, "UserAssigned")
      user_assigned_identity_resource_id = string
    }))
    install_scripts = optional(list(object({
      name = string
      source = object({
        type       = optional(string, "RemoteAzureBlob")
        source_uri = string
      })
    })))
    registry_adapters = optional(list(object({
      registry_key = string
      type         = string
      key_vault_secret_reference = object({
        secret_uri = string
      })
    })))
    storage_mounts = optional(list(object({
      name             = string
      type             = optional(string, "LocalStorage")
      source           = optional(string, "")
      destination_path = string
      credentials_key_vault_reference = optional(object({
        secret_uri = optional(string)
      }), {})
    })))

    # --- Lock ---
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }))

    # --- azapi retry / timeouts ---
    retry = optional(object({
      error_message_regex  = optional(list(string), ["ScopeLocked"])
      interval_seconds     = optional(number, null)
      max_interval_seconds = optional(number, null)
    }))
    timeouts = optional(object({
      create = optional(string, null)
      delete = optional(string, null)
      read   = optional(string, null)
      update = optional(string, null)
    }))

    # --- Diagnostic settings (repo-standard user-facing shape) ---
    diagnostic_settings = optional(map(object({
      name                                     = optional(string, null)
      log_categories                           = optional(set(string), [])
      log_groups                               = optional(set(string), ["allLogs"])
      metric_categories                        = optional(set(string), ["AllMetrics"])
      log_analytics_destination_type           = optional(string, "Dedicated")
      workspace_resource_id                    = optional(string, null)
      workspace_key                            = optional(string, null)
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
  }))
  default = {}

  description = <<-EOT
    Map of App Service Plans (Microsoft.Web/serverfarms) to create. The map key is arbitrary and is
    used by `for_each` and for downstream cross-references (e.g. `web_sites.<key>.service_plan_key`).
    Each object maps directly to an input of the wrapped `Azure/avm-res-web-serverfarm/azurerm` module.

    - `name` - (Required) The name of the App Service Plan.
    - `resource_group_key` - (Optional) **Pattern cross-reference**: the key of a resource group in the `resource_groups` variable (created by the spoke/pattern module). Resolved to the resource group resource ID and passed as `parent_id`. At least one of `resource_group_key` or `resource_group_name` must be provided.
    - `resource_group_name` - (Optional) The name of the resource group to deploy the App Service Plan into. Overrides `resource_group_key`. At least one of `resource_group_key` or `resource_group_name` must be provided.
    - `location` - (Optional) The location where the resources will be deployed. Defaults to `var.location` when not set.
    - `tags` - (Optional) A mapping of tags merged with `var.tags`. Defaults to `{}`.
    - `os_type` - (Required) The operating system type of the service plan. Possible values are `Windows`, `Linux`, `WindowsContainer` or `WindowsManagedInstance`.
    - `sku_name` - (Optional) The SKU name of the service plan. Defaults to `P1v2`.
    - `worker_count` - (Optional) The number of workers to allocate for this App Service Plan. Defaults to `3`, which is the recommended minimum for production workloads.
    - `maximum_elastic_worker_count` - (Optional) The maximum number of total workers allowed for this ElasticScaleEnabled App Service Plan. Defaults to `3`.
    - `per_site_scaling_enabled` - (Optional) Should per site scaling be enabled for this App Service Plan. Defaults to `false`.
    - `premium_plan_auto_scale_enabled` - (Optional) Defaults to false. Should elastic scale be enabled for this App Service Plan. Only set to true if deploying a Premium or Elastic Premium SKU.
    - `zone_balancing_enabled` - (Optional) Should zone balancing be enabled for this App Service Plan? Defaults to `true`. Note: when `sku_name = "FC1"` (Flex Consumption), zone redundancy is only available in Azure regions that advertise the `FCZONEREDUNDANCY` capability. In regions that do not support it, this module fails early with a precondition error listing the supported regions. Set this to `false` to deploy FC1 in an unsupported region.
    - `app_service_environment_id` - (Optional) The ID of the App Service Environment.
    - `network_configuration` - (Optional) VNet integration target, resolved to the wrapped module's `virtual_network_subnet_id`. Provide either the key-based references or a direct `subnet_resource_id`.
      - `vnet_key` - (Optional) **Pattern cross-reference**: the key of a virtual network in the `virtual_networks` variable.
      - `subnet_key` - (Optional) **Pattern cross-reference**: the key of a subnet within the VNet identified by `vnet_key`.
      - `subnet_resource_id` - (Optional) The resource ID of the subnet to integrate the App Service Plan with, used directly. Fallback when `vnet_key`/`subnet_key` are not provided.
    - `server_farm_resource_type` - (Optional) The resource type for the server farm. Defaults to `Microsoft.Web/serverfarms@2025-03-01`.

    - `managed_identities` - (Optional) Controls the managed identity configuration on this resource. The following properties can be specified:
      - `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled. Defaults to `false`.
      - `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource. Defaults to `[]`.
      - `user_assigned_keys` - (Optional) The keys of managed identities in the `managed_identities` variable, resolved to UAMI resource IDs and merged with `user_assigned_resource_ids`. Defaults to `[]`.

    - `rdp_enabled` - (Optional) Whether RDP is enabled for the Managed Instance App Service Plan. Only applicable when `os_type` is `WindowsManagedInstance`. Set to `null` for non-managed instance plans. A Bastion host with must be deployed in the virtual network for RDP connectivity to work.
    - `plan_default_identity` - (Optional) The default identity configuration for the Managed Instance App Service Plan. Only applicable when `os_type` is `WindowsManagedInstance`.
      - `identity_type` - (Optional) The type of the identity. Defaults to `UserAssigned`.
      - `user_assigned_identity_resource_id` - (Required) The resource ID of the user-assigned managed identity to use as the plan default identity.
    - `install_scripts` - (Optional) A list of install scripts to run on the Managed Instance App Service Plan. Only applicable when `os_type` is `WindowsManagedInstance`.
      - `name` - (Required) The name of the install script (e.g. `"FontInstaller"`).
      - `source` - (Required) The source configuration for the install script.
        - `type` - (Optional) The type of the source. Defaults to `RemoteAzureBlob`.
        - `source_uri` - (Required) The URI of the install script package (e.g. a blob URI to a `.zip` file).
    - `registry_adapters` - (Optional) A list of registry adapters associated with this App Service Plan. Only applicable when `os_type` is `WindowsManagedInstance`.
      - `registry_key` - (Required) Registry key for the adapter. The registry key must start with `HKEY_LOCAL_MACHINE`, `HKEY_CURRENT_USER`, or `HKEY_USERS` and contain at least one forward slash (e.g. `HKEY_LOCAL_MACHINE/SOFTWARE/MyApp/Config`).
      - `type` - (Required) Type of the registry adapter. Possible values are `DWORD` or `String`.
      - `key_vault_secret_reference` - (Required) Key vault reference to the value that will be placed in the registry location.
        - `secret_uri` - (Required) The URI of the Key Vault secret.
    - `storage_mounts` - (Optional) A list of storage mounts to configure on the App Service Plan. Only applicable when `os_type` is `WindowsManagedInstance`.
      - `name` - (Required) The name of the storage mount (e.g. `"g-drive"`).
      - `type` - (Optional) The type of the storage mount. Defaults to `LocalStorage`.
      - `source` - (Optional) The source of the storage mount. Defaults to `""`.
      - `destination_path` - (Required) The destination path for the storage mount (e.g. `"G:\\"`).
      - `credentials_key_vault_reference` - (Optional) A Key Vault reference for storage credentials.
        - `secret_uri` - (Required) The URI of the Key Vault secret.

    - `lock` - (Optional) Controls the Resource Lock configuration for this resource. The following properties can be specified:
      - `kind` - (Required) The type of lock. Possible values are `CanNotDelete` and `ReadOnly`.
      - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.

    - `retry` - (Optional) The retry configuration for azapi resources. The following properties can be specified:
      - `error_message_regex` - (Required) A list of regular expressions to match against error messages. If any match, the request will be retried. Defaults to `["ScopeLocked"]`.
      - `interval_seconds` - (Optional) The base number of seconds to wait between retries. Default is `10`.
      - `max_interval_seconds` - (Optional) The maximum number of seconds to wait between retries. Default is `180`.

    - `timeouts` - (Optional) The timeout configuration for azapi resources. The following properties can be specified:
      - `create` - (Optional) The timeout for create operations e.g. `"30m"`, `"1h"`.
      - `delete` - (Optional) The timeout for delete operations e.g. `"30m"`, `"1h"`.
      - `read` - (Optional) The timeout for read operations e.g. `"30m"`, `"1h"`.
      - `update` - (Optional) The timeout for update operations e.g. `"30m"`, `"1h"`.

    - `diagnostic_settings` - (Optional) A map of diagnostic settings to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
      - `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
      - `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
      - `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
      - `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
      - `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
      - `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
      - `workspace_key` - (Optional) The key of a Log Analytics workspace in the `log_analytics_workspaces` variable, resolved to its resource ID. Used when `workspace_resource_id` is not set.
      - `use_default_log_analytics` - (Optional) When `true` (and neither `workspace_resource_id` nor `workspace_key` is set), uses the first workspace in the `log_analytics_workspaces` variable. Defaults to `false`. A workspace is not required — `storage_account_resource_id`, event hub, or marketplace destinations are also valid.
      - `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
      - `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
      - `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
      - `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic Logs.

    - `role_assignments` - (Optional) A map of role assignments to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
      - `role_definition_id_or_name` - (Required) The ID or name of the role definition to assign to the principal.
      - `principal_id` - (Optional) The ID of the principal to assign the role to. Mutually exclusive with `managed_identity_key` and `assign_to_caller`.
      - `managed_identity_key` - (Optional) The key of a managed identity in the `managed_identities` variable, resolved to its principal ID. Sets `principal_type` to `ServicePrincipal`. Mutually exclusive with `principal_id` and `assign_to_caller`.
      - `assign_to_caller` - (Optional) When `true`, automatically uses the object ID of the identity running Terraform as the principal. Mutually exclusive with `principal_id` and `managed_identity_key`. Defaults to `false`.
      - `description` - (Optional) The description of the role assignment.
      - `skip_service_principal_aad_check` - (Optional) No effect when using AzAPI. Defaults to `false`.
      - `condition` - (Optional) The condition which will be used to scope the role assignment.
      - `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are `2.0`.
      - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
      - `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

    > **Downstream references:** Other modules may reference this resource via the map key:
    > - `app_service_plans.<plan_key>` → key from this map (exposed in the module output as `resource_id`/`name`).
    > - Consumed by the `web_site` module via `web_sites.<site_key>.service_plan_key`.

    > **Pattern note:** If `location` is not specified, defaults to `var.location`. Tags in `tags` are merged with `var.tags`. Every field maps directly to the corresponding `Azure/avm-res-web-serverfarm/azurerm` input.
  EOT
}

variable "location" {
  description = "Default location fallback when an App Service Plan does not set location."
  type        = string
}

variable "resource_groups" {
  description = "Resource groups output map from spoke module. Used to resolve resource_group_key to the resource group resource_id (passed as parent_id)."
  type        = any
  default     = {}
}

variable "managed_identities" {
  description = "Managed identities output map from spoke module. Used to resolve user_assigned_keys to UAMI resource IDs."
  type        = any
  default     = {}
}

variable "virtual_networks" {
  description = "Virtual networks output map from spoke module. Used to resolve subnet.vnet_key/subnet_key to a subnet resource ID."
  type        = any
  default     = {}
}

variable "log_analytics_workspaces" {
  description = "Log Analytics workspaces output map from the spoke module. Used to resolve a diagnostic setting's workspace_key to a workspace resource ID. When a diagnostic setting sets use_default_log_analytics = true (and no workspace_resource_id/workspace_key), the first workspace in this map is used."
  type        = any
  default     = {}
}

variable "tags" {
  description = "Default tags to merge with per-resource tags."
  type        = map(string)
  default     = {}
}

variable "enable_telemetry" {
  description = "Controls whether telemetry is enabled for the wrapped AVM module. See <https://aka.ms/avm/telemetryinfo>."
  type        = bool
  default     = true
}
