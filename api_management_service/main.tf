data "azurerm_client_config" "current" {}

module "api_management_service" {
  source  = "Azure/avm-res-apimanagement-service/azurerm"
  version = "0.9.0"

  for_each = var.api_management_services

  enable_telemetry = var.enable_telemetry

  name                = each.value.name
  resource_group_name = coalesce(each.value.resource_group_name, var.resource_groups[each.value.resource_group_key].name)
  location            = coalesce(each.value.location, var.location)

  publisher_email = each.value.publisher_email
  publisher_name  = each.value.publisher_name
  sku_name        = each.value.sku_name

  min_api_version           = each.value.min_api_version
  notification_sender_email = each.value.notification_sender_email
  virtual_network_type      = each.value.virtual_network_type

  # Key-based reference: resolve VNet injection subnet as virtual_network_vnet_key/virtual_network_subnet_key
  # (pattern-managed subnet in var.virtual_networks) -> direct virtual_network_subnet_id fallback.
  virtual_network_subnet_id = try(
    var.virtual_networks[each.value.virtual_network_vnet_key].subnets[each.value.virtual_network_subnet_key].resource_id,
    each.value.virtual_network_subnet_id
  )

  # Key-based reference: resolve public_ip_address_key (pattern-managed public IP in var.public_ips)
  # -> direct public_ip_address_id fallback.
  public_ip_address_id = try(coalesce(
    each.value.public_ip_address_id,
    try(var.public_ips[each.value.public_ip_address_key].resource_id, null)
  ), null)

  public_network_access_enabled           = each.value.public_network_access_enabled
  gateway_disabled                        = each.value.gateway_disabled
  client_certificate_enabled              = each.value.client_certificate_enabled
  zones                                   = each.value.zones
  private_endpoints_manage_dns_zone_group = each.value.private_endpoints_manage_dns_zone_group

  # Key-based reference: resolve user_assigned_keys to UAMI resource IDs, merge with direct resource IDs.
  managed_identities = {
    system_assigned = each.value.managed_identities.system_assigned
    user_assigned_resource_ids = setunion(
      each.value.managed_identities.user_assigned_resource_ids,
      toset([for key in each.value.managed_identities.user_assigned_keys : var.managed_identities[key].resource_id])
    )
  }

  protocols     = each.value.protocols
  security      = each.value.security
  policy        = each.value.policy
  sign_in       = each.value.sign_in
  sign_up       = each.value.sign_up
  delegation    = each.value.delegation
  tenant_access = each.value.tenant_access
  lock          = each.value.lock

  # Key-based reference: resolve each additional location's public IP as public_ip_address_key
  # (pattern-managed public IP in var.public_ips) -> direct public_ip_address_id, and its VNet
  # configuration subnet as vnet_key/subnet_key (pattern-managed subnet in var.virtual_networks) ->
  # direct subnet_id. The extra public_ip_address_key / vnet_key / subnet_key fields are dropped on
  # assignment to the AVM type.
  additional_location = each.value.additional_location == null ? null : [
    for loc in each.value.additional_location : merge(loc, {
      public_ip_address_id = try(coalesce(
        loc.public_ip_address_id,
        try(var.public_ips[loc.public_ip_address_key].resource_id, null)
      ), null)
      virtual_network_configuration = loc.virtual_network_configuration == null ? null : {
        subnet_id = try(
          var.virtual_networks[loc.virtual_network_configuration.vnet_key].subnets[loc.virtual_network_configuration.subnet_key].resource_id,
          loc.virtual_network_configuration.subnet_id
        )
      }
    })
  ]

  certificate            = each.value.certificate
  hostname_configuration = each.value.hostname_configuration

  # Role assignments: resolve the principal as assign_to_caller (Terraform runner) -> managed_identity_key
  # (pattern-managed UAMI principal) -> explicit principal_id. The extra managed_identity_key /
  # assign_to_caller fields are dropped on assignment to the AVM type.
  role_assignments = {
    for ra_key, ra in each.value.role_assignments : ra_key => merge(ra, {
      principal_id   = ra.assign_to_caller ? data.azurerm_client_config.current.object_id : ra.managed_identity_key != null ? var.managed_identities[ra.managed_identity_key].principal_id : ra.principal_id
      principal_type = ra.managed_identity_key != null ? "ServicePrincipal" : ra.principal_type
    })
  }

  # Diagnostic settings: resolve the destination workspace as workspace_resource_id -> workspace_key lookup
  # -> (when use_default_log_analytics is set) the first workspace in var.log_analytics_workspaces ->
  # otherwise null. The extra workspace_key / use_default_log_analytics fields are dropped on assignment to
  # the AVM type.
  diagnostic_settings = {
    for dk, dv in each.value.diagnostic_settings : dk => merge(dv, {
      workspace_resource_id = try(coalesce(
        dv.workspace_resource_id,
        try(var.log_analytics_workspaces[dv.workspace_key].resource_id, null),
        dv.use_default_log_analytics ? try(values(var.log_analytics_workspaces)[0].resource_id, null) : null
      ), null)
    })
  }

  # Private endpoints: resolve each endpoint's subnet as vnet_key/subnet_key (pattern-managed subnet in
  # var.virtual_networks) -> direct subnet_resource_id fallback, and resolve private_dns_zone.keys
  # (pattern-managed zones in var.private_dns_zones) merged with private_dns_zone.resource_ids. The extra
  # vnet_key / subnet_key / private_dns_zone fields are dropped on assignment to the AVM type.
  private_endpoints = {
    for pk, pe in each.value.private_endpoints : pk => merge(pe, {
      subnet_resource_id = try(
        var.virtual_networks[pe.vnet_key].subnets[pe.subnet_key].resource_id,
        pe.subnet_resource_id
      )
      private_dns_zone_resource_ids = setunion(
        coalesce(try(pe.private_dns_zone.resource_ids, null), toset([])),
        toset([for k in coalesce(try(pe.private_dns_zone.keys, null), toset([])) : tostring(try(var.private_dns_zones[k].resource_id, var.private_dns_zones[k]))])
      )
    })
  }

  subscriptions    = each.value.subscriptions
  named_values     = each.value.named_values
  products         = each.value.products
  api_version_sets = each.value.api_version_sets
  backends         = each.value.backends
  apis             = each.value.apis

  tags = merge(var.tags, each.value.tags)
}
