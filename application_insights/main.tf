data "azurerm_client_config" "current" {}

module "application_insights" {
  source  = "Azure/avm-res-insights-component/azurerm"
  version = "0.4.0"

  for_each = var.application_insights

  enable_telemetry = var.enable_telemetry

  name                = each.value.name
  resource_group_name = coalesce(each.value.resource_group_name, var.resource_groups[each.value.resource_group_key].name)
  location            = coalesce(each.value.location, var.location)
  tags                = merge(var.tags, each.value.tags)

  # Core settings
  application_type = each.value.application_type

  # Workspace-based Application Insights: prefer the direct workspace ID, then the
  # workspace_key lookup, finally falling back to the first workspace in the map.
  workspace_id = coalesce(
    each.value.workspace_resource_id,
    try(var.log_analytics_workspaces[each.value.workspace_key].resource_id, null),
    try(values(var.log_analytics_workspaces)[0].resource_id, null)
  )

  # Data cap / retention / sampling
  daily_data_cap_in_gb                  = each.value.daily_data_cap_in_gb
  daily_data_cap_notifications_disabled = each.value.daily_data_cap_notifications_disabled
  retention_in_days                     = each.value.retention_in_days
  sampling_percentage                   = each.value.sampling_percentage

  # Privacy / networking / auth
  disable_ip_masking                  = each.value.disable_ip_masking
  local_authentication_disabled       = each.value.local_authentication_disabled
  internet_ingestion_enabled          = each.value.internet_ingestion_enabled
  internet_query_enabled              = each.value.internet_query_enabled
  force_customer_storage_for_profiler = each.value.force_customer_storage_for_profiler

  # Linked storage account (profiler): resolve key to a storage account resource ID, falling back to the direct ID.
  linked_storage_account = {
    for k, v in each.value.linked_storage_account : k => {
      resource_id = coalesce(v.resource_id, try(var.storage_accounts[v.key].resource_id, null))
    }
  }

  # Monitor private link scope
  monitor_private_link_scope = each.value.monitor_private_link_scope

  # Diagnostic settings: resolve each setting's destination workspace (direct ID, workspace_key, or default workspace).
  diagnostic_settings = {
    for dk, dv in each.value.diagnostic_settings : dk => {
      name                           = dv.name
      logs                           = dv.logs
      metrics                        = dv.metrics
      log_analytics_destination_type = dv.log_analytics_destination_type
      workspace_resource_id = coalesce(
        dv.workspace_resource_id,
        try(var.log_analytics_workspaces[dv.workspace_key].resource_id, null),
        dv.use_default_log_analytics ? try(values(var.log_analytics_workspaces)[0].resource_id, null) : null
      )
      storage_account_resource_id              = dv.storage_account_resource_id
      event_hub_authorization_rule_resource_id = dv.event_hub_authorization_rule_resource_id
      event_hub_name                           = dv.event_hub_name
      marketplace_partner_resource_id          = dv.marketplace_partner_resource_id
    }
  }

  # Role assignments: resolve the principal (caller, managed_identity_key, or explicit principal_id).
  role_assignments = {
    for ra_key, ra in each.value.role_assignments : ra_key => {
      role_definition_id_or_name             = ra.role_definition_id_or_name
      principal_id                           = ra.assign_to_caller ? data.azurerm_client_config.current.object_id : ra.managed_identity_key != null ? var.managed_identities[ra.managed_identity_key].principal_id : ra.principal_id
      description                            = ra.description
      skip_service_principal_aad_check       = ra.skip_service_principal_aad_check
      condition                              = ra.condition
      condition_version                      = ra.condition_version
      delegated_managed_identity_resource_id = ra.delegated_managed_identity_resource_id
      principal_type                         = ra.managed_identity_key != null ? "ServicePrincipal" : ra.principal_type
    }
  }

  # Lock
  lock = each.value.lock

  # Retry / timeouts
  retry    = each.value.retry
  timeouts = each.value.timeouts
}
