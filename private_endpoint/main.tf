data "azurerm_client_config" "current" {}

module "private_endpoint" {
  source  = "Azure/avm-res-network-privateendpoint/azurerm"
  version = "0.2.0"

  for_each = var.private_endpoints

  name                = each.value.name
  location            = coalesce(each.value.location, var.location)
  resource_group_name = coalesce(each.value.resource_group_name, var.resource_groups[each.value.resource_group_key].name)
  enable_telemetry    = coalesce(each.value.enable_telemetry, var.enable_telemetry)
  tags                = merge(var.tags, each.value.tags)

  network_interface_name = each.value.network_interface_name

  # Key-based reference: resolve vnet_key/subnet_key to subnet resource ID
  subnet_resource_id = (
    each.value.network_configuration.subnet_resource_id != null
    ? each.value.network_configuration.subnet_resource_id
    : var.virtual_networks[each.value.network_configuration.vnet_key].subnets[each.value.network_configuration.subnet_key].resource_id
  )

  private_connection_resource_id = each.value.private_connection_resource_id

  subresource_names               = each.value.subresource_names
  private_service_connection_name = each.value.private_service_connection_name
  private_dns_zone_group_name     = each.value.private_dns_zone_group_name

  # Key-based reference: resolve private_dns_zone_keys to resource IDs
  private_dns_zone_resource_ids = try(
    [for key in each.value.private_dns_zone_keys : var.private_dns_zone_resource_ids[key]],
    coalesce(each.value.private_dns_zone_resource_ids, [])
  )

  ip_configurations                          = each.value.ip_configurations
  application_security_group_association_ids = each.value.application_security_group_association_ids

  lock = try(each.value.lock, var.lock)
  role_assignments = {
    for key, ra in each.value.role_assignments : key => {
      role_definition_id_or_name          = ra.role_definition_id_or_name
      principal_id                        = ra.assign_to_caller ? data.azurerm_client_config.current.object_id : ra.managed_identity_key != null ? var.managed_identities[ra.managed_identity_key].principal_id : ra.principal_id
      description                         = ra.description
      skip_service_principal_aad_check    = ra.skip_service_principal_aad_check
      condition                           = ra.condition
      condition_version                   = ra.condition_version
      delegated_managed_identity_resource = ra.delegated_managed_identity_resource_id
      principal_type                      = ra.managed_identity_key != null ? "ServicePrincipal" : ra.principal_type
    }
  }
}