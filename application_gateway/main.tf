module "application_gateway" {
  source  = "Azure/avm-res-network-applicationgateway/azurerm"
  version = "0.5.2"

  for_each = var.application_gateways

  enable_telemetry = each.value.enable_telemetry

  name                = each.value.name
  resource_group_name = coalesce(each.value.resource_group_name, var.resource_groups[each.value.resource_group_key].name)
  location            = coalesce(each.value.location, var.location)
  tags                = merge(var.tags, each.value.tags)

  # Key-based reference: resolve user_assigned_keys to UAMI resource IDs, merge with direct resource IDs.
  managed_identities = {
    system_assigned = each.value.managed_identities.system_assigned
    user_assigned_resource_ids = setunion(
      each.value.managed_identities.user_assigned_resource_ids,
      toset([for key in each.value.managed_identities.user_assigned_keys : var.managed_identities[key].resource_id])
    )
  }

  # SKU / scaling
  sku                     = each.value.sku
  autoscale_configuration = each.value.autoscale_configuration
  zones                   = each.value.zones

  # Core toggles
  http2_enable                      = each.value.http2_enable
  fips_enabled                      = each.value.fips_enabled
  force_firewall_policy_association = each.value.force_firewall_policy_association
  # WAF policy: resolve app_gateway_waf_policy_key against var.web_application_firewall_policies -> direct resource ID fallback.
  app_gateway_waf_policy_resource_id = try(coalesce(
    each.value.app_gateway_waf_policy_resource_id,
    try(var.web_application_firewall_policies[each.value.app_gateway_waf_policy_key].resource_id, null)
  ), null)
  global = each.value.global

  # Gateway IP configuration (subnet binding): resolve vnet_key/subnet_key against
  # var.virtual_networks -> direct subnet_id fallback.
  gateway_ip_configuration = {
    name = each.value.gateway_ip_configuration.name
    subnet_id = try(
      var.virtual_networks[each.value.gateway_ip_configuration.vnet_key].subnets[each.value.gateway_ip_configuration.subnet_key].resource_id,
      each.value.gateway_ip_configuration.subnet_id
    )
  }

  # Frontend IP configuration
  frontend_ip_configuration_public_name = each.value.frontend_ip_configuration_public_name
  frontend_ip_configuration_private     = each.value.frontend_ip_configuration_private
  # Public IP: resolve public_ip_key against var.public_ips -> direct public_ip_resource_id fallback.
  # The extra public_ip_key field is dropped on assignment to the AVM object type.
  public_ip_address_configuration = merge(each.value.public_ip_address_configuration, {
    public_ip_resource_id = try(
      var.public_ips[each.value.public_ip_address_configuration.public_ip_key].resource_id,
      each.value.public_ip_address_configuration.public_ip_resource_id
    )
  })

  # Frontend ports / backend pools / backend settings
  frontend_ports        = each.value.frontend_ports
  backend_address_pools = each.value.backend_address_pools
  backend_http_settings = each.value.backend_http_settings

  # Listeners / routing
  http_listeners              = each.value.http_listeners
  request_routing_rules       = each.value.request_routing_rules
  url_path_map_configurations = each.value.url_path_map_configurations

  # Probes / redirects / rewrites / custom errors
  probe_configurations       = each.value.probe_configurations
  redirect_configuration     = each.value.redirect_configuration
  rewrite_rule_set           = each.value.rewrite_rule_set
  custom_error_configuration = each.value.custom_error_configuration

  # SSL / TLS
  ssl_certificates = each.value.ssl_certificates
  ssl_policy       = each.value.ssl_policy
  ssl_profile      = each.value.ssl_profile

  # Certificates
  authentication_certificate = each.value.authentication_certificate
  trusted_client_certificate = each.value.trusted_client_certificate
  trusted_root_certificate   = each.value.trusted_root_certificate

  # Private link: resolve each ip_configuration's subnet as vnet_key/subnet_key against
  # var.virtual_networks -> direct subnet_id fallback. The extra vnet_key / subnet_key fields
  # are dropped on assignment to the AVM type.
  private_link_configuration = each.value.private_link_configuration == null ? null : toset([
    for plc in each.value.private_link_configuration : merge(plc, {
      ip_configuration = [
        for ipc in plc.ip_configuration : merge(ipc, {
          subnet_id = try(
            var.virtual_networks[ipc.vnet_key].subnets[ipc.subnet_key].resource_id,
            ipc.subnet_id
          )
        })
      ]
    })
  ])

  # WAF (in-gateway configuration)
  waf_configuration = each.value.waf_configuration

  # Diagnostic settings / role assignments
  diagnostic_settings = each.value.diagnostic_settings
  role_assignments    = each.value.role_assignments

  # Lock / timeouts
  lock     = each.value.lock
  timeouts = each.value.timeouts
}
