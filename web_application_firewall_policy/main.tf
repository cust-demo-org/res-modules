data "azurerm_client_config" "current" {}

module "web_application_firewall_policy" {
  source  = "Azure/avm-res-network-applicationgatewaywebapplicationfirewallpolicy/azurerm"
  version = "0.2.0"

  for_each = var.web_application_firewall_policies

  enable_telemetry = var.enable_telemetry

  name                = each.value.name
  resource_group_name = coalesce(each.value.resource_group_name, var.resource_groups[each.value.resource_group_key].name)
  location            = coalesce(each.value.location, var.location)
  tags                = merge(var.tags, each.value.tags)

  # WAF policy configuration
  policy_settings = each.value.policy_settings
  managed_rules   = each.value.managed_rules
  custom_rules    = each.value.custom_rules

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

  # Lock / timeouts
  lock     = each.value.lock
  timeouts = each.value.timeouts
}
