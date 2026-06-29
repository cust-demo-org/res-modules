data "azurerm_client_config" "current" {}

module "public_ip" {
  source  = "Azure/avm-res-network-publicipaddress/azurerm"
  version = "0.2.1"

  for_each = var.public_ips

  enable_telemetry = var.enable_telemetry

  name                = each.value.name
  resource_group_name = coalesce(each.value.resource_group_name, var.resource_groups[each.value.resource_group_key].name)
  location            = coalesce(each.value.location, var.location)
  tags                = merge(var.tags, each.value.tags)

  # Core settings
  allocation_method       = each.value.allocation_method
  sku                     = each.value.sku
  sku_tier                = each.value.sku_tier
  ip_version              = each.value.ip_version
  zones                   = each.value.zones
  idle_timeout_in_minutes = each.value.idle_timeout_in_minutes
  ip_tags                 = each.value.ip_tags

  # DNS / FQDN
  domain_name_label = each.value.domain_name_label
  reverse_fqdn      = each.value.reverse_fqdn

  # Edge zone / prefix
  edge_zone           = each.value.edge_zone
  public_ip_prefix_id = each.value.public_ip_prefix_id

  # DDoS protection
  ddos_protection_mode    = each.value.ddos_protection_mode
  ddos_protection_plan_id = each.value.ddos_protection_plan_id

  # Diagnostic settings: resolve each setting's destination workspace (direct ID,
  # workspace_key lookup, or — when use_default_log_analytics is set — the first
  # workspace in var.log_analytics_workspaces).
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

  # Lock
  lock = each.value.lock
}
