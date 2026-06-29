data "azurerm_client_config" "current" {}

module "app_service_plan" {
  source  = "Azure/avm-res-web-serverfarm/azurerm"
  version = "2.0.6"

  for_each = var.app_service_plans

  enable_telemetry = var.enable_telemetry

  name      = each.value.name
  parent_id = each.value.resource_group_name != null ? "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${each.value.resource_group_name}" : var.resource_groups[each.value.resource_group_key].resource_id
  location  = coalesce(each.value.location, var.location)
  tags      = merge(var.tags, each.value.tags)

  # Core settings
  os_type                         = each.value.os_type
  sku_name                        = each.value.sku_name
  worker_count                    = each.value.worker_count
  maximum_elastic_worker_count    = each.value.maximum_elastic_worker_count
  per_site_scaling_enabled        = each.value.per_site_scaling_enabled
  premium_plan_auto_scale_enabled = each.value.premium_plan_auto_scale_enabled
  zone_balancing_enabled          = each.value.zone_balancing_enabled
  app_service_environment_id      = each.value.app_service_environment_id
  server_farm_resource_type       = each.value.server_farm_resource_type

  # Key-based reference: resolve network_configuration.vnet_key/subnet_key to a subnet
  # resource ID, falling back to the direct network_configuration.subnet_resource_id.
  virtual_network_subnet_id = each.value.network_configuration != null ? try(
    var.virtual_networks[each.value.network_configuration.vnet_key].subnets[each.value.network_configuration.subnet_key].resource_id,
    each.value.network_configuration.subnet_resource_id
  ) : null

  # Key-based reference: resolve user_assigned_keys to UAMI resource IDs, merge with direct resource IDs.
  managed_identities = {
    system_assigned = each.value.managed_identities.system_assigned
    user_assigned_resource_ids = setunion(
      each.value.managed_identities.user_assigned_resource_ids,
      toset([for key in each.value.managed_identities.user_assigned_keys : var.managed_identities[key].resource_id])
    )
  }

  # Windows Managed Instance settings
  rdp_enabled           = each.value.rdp_enabled
  plan_default_identity = each.value.plan_default_identity
  install_scripts       = each.value.install_scripts
  registry_adapters     = each.value.registry_adapters
  storage_mounts        = each.value.storage_mounts

  # Lock / retry / timeouts
  lock     = each.value.lock
  retry    = each.value.retry
  timeouts = each.value.timeouts

  # Diagnostic settings: pass the standard AVM interface fields through. The
  # destination workspace is resolved as workspace_resource_id → workspace_key
  # lookup → (when use_default_log_analytics is set) the first workspace in
  # var.log_analytics_workspaces → otherwise null (a workspace is not required).
  diagnostic_settings = {
    for dk, dv in each.value.diagnostic_settings : dk => {
      name                           = dv.name
      log_categories                 = dv.log_categories
      log_groups                     = dv.log_groups
      metric_categories              = dv.metric_categories
      log_analytics_destination_type = dv.log_analytics_destination_type
      workspace_resource_id = try(coalesce(
        dv.workspace_resource_id,
        try(var.log_analytics_workspaces[dv.workspace_key].resource_id, null),
        dv.use_default_log_analytics ? try(values(var.log_analytics_workspaces)[0].resource_id, null) : null
      ), null)
      storage_account_resource_id              = dv.storage_account_resource_id
      event_hub_authorization_rule_resource_id = dv.event_hub_authorization_rule_resource_id
      event_hub_name                           = dv.event_hub_name
      marketplace_partner_resource_id          = dv.marketplace_partner_resource_id
    }
  }

  # Role assignments: resolve the principal as assign_to_caller (Terraform runner) →
  # managed_identity_key (pattern-managed UAMI principal) → explicit principal_id.
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
}
