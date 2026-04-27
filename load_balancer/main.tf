data "azurerm_client_config" "current" {}

module "load_balancer" {
  source  = "Azure/avm-res-network-loadbalancer/azurerm"
  version = "0.5.0"

  for_each = var.load_balancers

  name                = each.value.name
  location            = coalesce(each.value.location, var.location)
  resource_group_name = coalesce(each.value.resource_group_name, var.resource_groups[each.value.resource_group_key].name)
  enable_telemetry    = coalesce(each.value.enable_telemetry, var.enable_telemetry)
  tags                = merge(var.tags, each.value.tags)
  sku                 = each.value.sku
  sku_tier            = each.value.sku_tier
  edge_zone           = each.value.edge_zone

  # Key-based reference: resolve vnet_key/subnet_key to subnet resource ID
  frontend_subnet_resource_id = try(
    var.virtual_networks[each.value.frontend_subnet.vnet_key].subnets[each.value.frontend_subnet.subnet_key].resource_id,
    each.value.frontend_subnet.resource_id
  )

  frontend_ip_configurations = {
    for fip_key, fip in each.value.frontend_ip_configurations : fip_key => {
      name                                               = fip.name
      frontend_private_ip_address                        = fip.frontend_private_ip_address
      frontend_private_ip_address_version                = fip.frontend_private_ip_address_version
      frontend_private_ip_address_allocation             = fip.frontend_private_ip_address_allocation
      frontend_private_ip_subnet_resource_id             = fip.frontend_private_ip_subnet_resource_id
      gateway_load_balancer_frontend_ip_configuration_id = fip.gateway_load_balancer_frontend_ip_configuration_id
      public_ip_address_resource_name                    = fip.public_ip_address_resource_name
      public_ip_address_resource_id                      = fip.public_ip_address_resource_id
      public_ip_prefix_resource_id                       = fip.public_ip_prefix_resource_id
      create_public_ip_address                           = fip.create_public_ip_address
      new_public_ip_resource_group_name                  = fip.new_public_ip_resource_group_name
      new_public_ip_location                             = fip.new_public_ip_location
      inherit_lock                                       = fip.inherit_lock
      lock_type_if_not_inherited                         = fip.lock_type_if_not_inherited
      inherit_tags                                       = fip.inherit_tags
      edge_zone                                          = fip.edge_zone
      zones                                              = fip.zones
      tags                                               = fip.tags
      role_assignments = {
        for ra_key, ra in fip.role_assignments : ra_key => {
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
      diagnostic_settings = {
        for dk, dv in fip.diagnostic_settings : dk => {
          name                                     = dv.name
          log_categories                           = dv.log_categories
          log_groups                               = dv.log_groups
          metric_categories                        = dv.metric_categories
          log_analytics_destination_type           = dv.log_analytics_destination_type
          workspace_resource_id                    = dv.use_default_log_analytics ? var.default_log_analytics_workspace_resource_id : dv.workspace_resource_id
          storage_account_resource_id              = dv.storage_account_resource_id
          event_hub_authorization_rule_resource_id = dv.event_hub_authorization_rule_resource_id
          event_hub_name                           = dv.event_hub_name
          marketplace_partner_resource_id          = dv.marketplace_partner_resource_id
        }
      }
    }
  }

  # Key-based reference: resolve virtual_network.key to VNet resource ID
  backend_address_pools = {
    for k, v in each.value.backend_address_pools : k => {
      name = v.name
      virtual_network_resource_id = v.virtual_network != null ? try(
        var.virtual_networks[v.virtual_network.key].resource_id,
        v.virtual_network.resource_id
      ) : null
      tunnel_interfaces = v.tunnel_interfaces
    }
  }

  backend_address_pool_addresses          = each.value.backend_address_pool_addresses
  backend_address_pool_configuration      = each.value.backend_address_pool_configuration
  backend_address_pool_network_interfaces = each.value.backend_address_pool_network_interfaces

  lb_probes         = each.value.lb_probes
  lb_rules          = each.value.lb_rules
  lb_nat_rules      = each.value.lb_nat_rules
  lb_nat_pools      = each.value.lb_nat_pools
  lb_outbound_rules = each.value.lb_outbound_rules

  diagnostic_settings = {
    for dk, dv in each.value.diagnostic_settings : dk => {
      name                                     = dv.name
      log_categories                           = dv.log_categories
      log_groups                               = dv.log_groups
      metric_categories                        = dv.metric_categories
      log_analytics_destination_type           = dv.log_analytics_destination_type
      workspace_resource_id                    = dv.use_default_log_analytics ? var.default_log_analytics_workspace_resource_id : dv.workspace_resource_id
      storage_account_resource_id              = dv.storage_account_resource_id
      event_hub_authorization_rule_resource_id = dv.event_hub_authorization_rule_resource_id
      event_hub_name                           = dv.event_hub_name
      marketplace_partner_resource_id          = dv.marketplace_partner_resource_id
    }
  }
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
  public_ip_address_configuration = each.value.public_ip_address_configuration
}
