variable "application_insights" {
  type = map(object({
    # --- Standard module fields ---
    name                = string
    resource_group_key  = optional(string)
    resource_group_name = optional(string)
    location            = optional(string)
    tags                = optional(map(string), {})

    # --- Core Application Insights settings ---
    application_type = optional(string, "web")

    # --- Log Analytics workspace (cross-reference) ---
    workspace_resource_id = optional(string)
    workspace_key         = optional(string)

    # --- Data cap / retention / sampling ---
    daily_data_cap_in_gb                  = optional(number, 100)
    daily_data_cap_notifications_disabled = optional(bool, false)
    retention_in_days                     = optional(number, 90)
    sampling_percentage                   = optional(number, 100)

    # --- Privacy / networking / auth ---
    disable_ip_masking                  = optional(bool, false)
    local_authentication_disabled       = optional(bool, false)
    internet_ingestion_enabled          = optional(bool, true)
    internet_query_enabled              = optional(bool, true)
    force_customer_storage_for_profiler = optional(bool, false)

    # --- Linked storage account (profiler) ---
    linked_storage_account = optional(map(object({
      resource_id = optional(string, null)
      key         = optional(string)
    })), {})

    # --- Monitor private link scope ---
    monitor_private_link_scope = optional(map(object({
      resource_id           = optional(string, null)
      name                  = optional(string, null)
      kind                  = optional(string, "Resource")
      subscription_location = optional(string, null)
    })), {})

    # --- Diagnostic settings ---
    diagnostic_settings = optional(map(object({
      name = optional(string, null)
      logs = optional(set(object({
        category       = optional(string, null)
        category_group = optional(string, null)
        enabled        = optional(bool, true)
        retention_policy = optional(object({
          days    = optional(number, 0)
          enabled = optional(bool, false)
        }), {})
      })), [])
      metrics = optional(set(object({
        category = optional(string, null)
        enabled  = optional(bool, true)
        retention_policy = optional(object({
          days    = optional(number, 0)
          enabled = optional(bool, false)
        }), {})
      })), [])
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

    # --- Retry / timeouts ---
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
  }))
  default     = {}
  description = <<-EOT
    A map of Azure Application Insights components to create using the `Azure/avm-res-insights-component/azurerm` AVM module.
    The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.

    - `name` - (Required) The name of the Application Insights component. Changing this forces a new resource to be created.
    - `resource_group_key` - (Optional) **Pattern cross-reference**: the key of a resource group in the `resource_groups` variable (created by the spoke/pattern module). Resolved to the resource group name. At least one of `resource_group_key` or `resource_group_name` must be provided.
    - `resource_group_name` - (Optional) The name of the resource group to deploy the Application Insights component into. Overrides `resource_group_key`. At least one of `resource_group_key` or `resource_group_name` must be provided.
    - `location` - (Optional) Specifies the Azure Region where the Application Insights component should exist. Defaults to `var.location`.
    - `tags` - (Optional) A mapping of tags merged with `var.tags`. Defaults to `{}`.

    - `application_type` - (Optional) The type of the application. Possible values are `web`, `ios`, `java`, `phone`, `MobileCenter`, `Node.JS`, `other`, `store`. Defaults to `web`.

    - `workspace_resource_id` - (Optional) The resource ID of the Log Analytics workspace to send data to. Workspace-based Application Insights is required by Azure. Takes precedence over `workspace_key`.
    - `workspace_key` - (Optional) **Pattern cross-reference**: the key of a Log Analytics workspace in the `log_analytics_workspaces` variable. Resolved to the workspace resource ID. Used when `workspace_resource_id` is not set. If neither is set, the first workspace in `log_analytics_workspaces` is used.

    - `daily_data_cap_in_gb` - (Optional) The daily data cap in GB. `0` means unlimited. Defaults to `100`.
    - `daily_data_cap_notifications_disabled` - (Optional) Disables the daily data cap notifications. Defaults to `false`.
    - `retention_in_days` - (Optional) The retention period in days. `0` means unlimited. Defaults to `90`.
    - `sampling_percentage` - (Optional) The sampling percentage. `100` means all. Defaults to `100`.

    - `disable_ip_masking` - (Optional) Disables IP masking. Defaults to `false`.
    - `local_authentication_disabled` - (Optional) Disables local authentication. Defaults to `false`.
    - `internet_ingestion_enabled` - (Optional) Enables internet ingestion. Defaults to `true`.
    - `internet_query_enabled` - (Optional) Enables internet query. Defaults to `true`.
    - `force_customer_storage_for_profiler` - (Optional) Forces customer storage for the profiler. Defaults to `false`.

    - `linked_storage_account` - (Optional) A map of linked storage account configurations for the Application Insights profiler. Defaults to `{}`.
      - `resource_id` - (Optional) The resource ID of the storage account, used directly. Takes precedence over `key`.
      - `key` - (Optional) **Pattern cross-reference**: the key of a storage account in the `storage_accounts` variable, resolved to its `resource_id`. Used when `resource_id` is not set.

    - `monitor_private_link_scope` - (Optional) A map of monitor private link scopes to connect the Application Insights resource to. Defaults to `{}`.
      - `resource_id` - (Optional) The resource ID of the monitor private link scope.
      - `name` - (Optional) The name of the scoped resource. Defaults to the Application Insights resource name.
      - `kind` - (Optional) The kind of the scoped resource. Possible values are `Resource` or `Metrics`. Defaults to `Resource`.
      - `subscription_location` - (Optional) The location of the subscription. Required for kind `Metrics`.

    - `diagnostic_settings` - (Optional) A map of diagnostic settings to create on the Application Insights component. Defaults to `{}`.
      - `name` - (Optional) The name of the diagnostic setting. One is generated if not set.
      - `logs` - (Optional) A set of log categories or category groups to send to the destination. If both `logs` and `metrics` are omitted or empty, the module defaults to enabling `allLogs`. Defaults to `[]`.
        - `category` - (Optional) The log category to send.
        - `category_group` - (Optional) The log category group to send.
        - `enabled` - (Optional) Whether this log category/group is enabled. Defaults to `true`.
        - `retention_policy` - (Optional) The retention policy for this log category/group.
          - `days` - (Optional) The number of days to retain. `0` means indefinite. Defaults to `0`.
          - `enabled` - (Optional) Whether the retention policy is enabled. Defaults to `false`.
      - `metrics` - (Optional) A set of metric categories to send to the destination. If both `logs` and `metrics` are omitted or empty, the module defaults to enabling `AllMetrics`. At this resource scope, the only supported metric category is `AllMetrics`. Defaults to `[]`.
        - `category` - (Optional) The metric category to send.
        - `enabled` - (Optional) Whether this metric category is enabled. Defaults to `true`.
        - `retention_policy` - (Optional) The retention policy for this metric category.
          - `days` - (Optional) The number of days to retain. `0` means indefinite. Defaults to `0`.
          - `enabled` - (Optional) Whether the retention policy is enabled. Defaults to `false`.
      - `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
      - `workspace_resource_id` - (Optional) The resource ID of the Log Analytics workspace to send logs and metrics to.
      - `workspace_key` - (Optional) **Pattern cross-reference**: the key of a Log Analytics workspace in the `log_analytics_workspaces` variable, resolved to its resource ID. Used when `workspace_resource_id` is not set.
      - `use_default_log_analytics` - (Optional) When `true` (and neither `workspace_resource_id` nor `workspace_key` is set), uses the first workspace in the `log_analytics_workspaces` variable. Defaults to `false`. A workspace is not required — storage account, event hub, or marketplace destinations are also valid.
      - `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
      - `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
      - `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub is selected.
      - `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to send Diagnostic Logs to.

    - `role_assignments` - (Optional) A map of role assignments to create on the Application Insights component. Defaults to `{}`.
      - `role_definition_id_or_name` - (Required) The ID or name of the role definition to assign to the principal.
      - `principal_id` - (Optional) The ID of the principal to assign the role to. Mutually exclusive with `managed_identity_key` and `assign_to_caller`.
      - `managed_identity_key` - (Optional) **Pattern cross-reference**: the key of a managed identity in the `managed_identities` variable, resolved to its principal ID. Sets `principal_type` to `ServicePrincipal`. Mutually exclusive with `principal_id` and `assign_to_caller`.
      - `assign_to_caller` - (Optional) When `true`, automatically uses the object ID of the identity running Terraform as the principal. Mutually exclusive with `principal_id` and `managed_identity_key`. Defaults to `false`.
      - `description` - (Optional) The description of the role assignment.
      - `skip_service_principal_aad_check` - (Optional) Skips the Azure Active Directory check for the service principal in the tenant. Only set to `true` when assigning a role to a service principal. Defaults to `false`.
      - `condition` - (Optional) The condition used to scope the role assignment.
      - `condition_version` - (Optional) The version of the condition syntax. Valid value is `2.0`.
      - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource ID which contains a Managed Identity. Changing this forces a new resource to be created.
      - `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. Changing this forces a new resource to be created.

    - `lock` - (Optional) Controls the Resource Lock configuration for the Application Insights component.
      - `kind` - (Required) The type of lock. Possible values are `CanNotDelete` and `ReadOnly`.
      - `name` - (Optional) The name of the lock. Generated from `kind` if not specified. Changing this forces a new resource to be created.

    - `retry` - (Optional) The retry configuration for the underlying azapi resources.
      - `error_message_regex` - (Optional) A list of regular expressions to match against error messages. If any match, the request is retried. Defaults to `["ScopeLocked"]`.
      - `interval_seconds` - (Optional) The base number of seconds to wait between retries. Defaults to `10` (module default when unset).
      - `max_interval_seconds` - (Optional) The maximum number of seconds to wait between retries. Defaults to `180` (module default when unset).

    - `timeouts` - (Optional) The timeout configuration for the underlying azapi resources.
      - `create` - (Optional) The timeout for create operations, e.g. `"30m"`, `"1h"`.
      - `delete` - (Optional) The timeout for delete operations, e.g. `"30m"`, `"1h"`.
      - `read` - (Optional) The timeout for read operations, e.g. `"30m"`, `"1h"`.
      - `update` - (Optional) The timeout for update operations, e.g. `"30m"`, `"1h"`.

    > **Downstream references:** Other modules reference this resource via the map key, e.g. a web app reading `application_insights.<key>.connection_string` or `application_insights.<key>.instrumentation_key`.

    > **Pattern note:** If `location` is not specified, defaults to `var.location`. Tags in `tags` are merged with `var.tags`.
  EOT
}

variable "location" {
  description = "Default location fallback when an Application Insights component does not set location."
  type        = string
}

variable "resource_groups" {
  description = "Resource groups output map from spoke module. Used to resolve resource_group_key to name."
  type        = any
  default     = {}
}

variable "log_analytics_workspaces" {
  description = "Log Analytics workspaces output map from the spoke module. Used to resolve workspace_key to a workspace resource ID. When a component sets neither workspace_resource_id nor workspace_key, the first workspace in this map is used."
  type        = any
  default     = {}
}

variable "managed_identities" {
  description = "Managed identities output map from the spoke module. Used to resolve role_assignments.managed_identity_key to a principal ID."
  type        = any
  default     = {}
}

variable "storage_accounts" {
  description = "Storage accounts output map from the spoke module. Used to resolve linked_storage_account.key to a storage account resource ID."
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
