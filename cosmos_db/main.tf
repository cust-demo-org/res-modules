data "azurerm_client_config" "current" {}

resource "random_string" "cosmos_db_suffix" {
  for_each = { for k, v in var.cosmos_db : k => v.name_random_suffix_configuration if v.name_random_suffix_configuration != null }

  length  = each.value.length
  special = false
  upper   = false
}

module "cosmos_db" {
  source  = "Azure/avm-res-documentdb-databaseaccount/azurerm"
  version = "0.10.0"

  for_each = var.cosmos_db

  enable_telemetry    = var.enable_telemetry
  name                = each.value.name_random_suffix_configuration != null ? (each.value.name_random_suffix_configuration.append_with_hyphen ? "${each.value.name}-${random_string.cosmos_db_suffix[each.key].result}" : "${each.value.name}${random_string.cosmos_db_suffix[each.key].result}") : each.value.name
  location            = coalesce(each.value.location, var.location)
  resource_group_name = coalesce(each.value.resource_group_name, var.resource_groups[each.value.resource_group_key].name)
  tags                = merge(var.tags, each.value.tags)

  # Account behaviour
  access_key_metadata_writes_enabled    = each.value.access_key_metadata_writes_enabled
  analytical_storage_enabled            = each.value.analytical_storage_enabled
  automatic_failover_enabled            = each.value.automatic_failover_enabled
  free_tier_enabled                     = each.value.free_tier_enabled
  local_authentication_disabled         = each.value.local_authentication_disabled
  minimal_tls_version                   = each.value.minimal_tls_version
  mongo_server_version                  = each.value.mongo_server_version
  multiple_write_locations_enabled      = each.value.multiple_write_locations_enabled
  partition_merge_enabled               = each.value.partition_merge_enabled
  public_network_access_enabled         = each.value.public_network_access_enabled
  network_acl_bypass_for_azure_services = each.value.network_acl_bypass_for_azure_services
  network_acl_bypass_resource_ids       = each.value.network_acl_bypass_resource_ids
  ip_range_filter                       = each.value.ip_range_filter

  consistency_policy        = each.value.consistency_policy
  analytical_storage_config = each.value.analytical_storage_config
  capacity                  = each.value.capacity
  backup                    = each.value.backup
  cors_rule                 = each.value.cors_rule
  # Resolve each geo-location's region, falling back to var.location when not set.
  geo_locations = each.value.geo_locations == null ? null : [
    for geo in each.value.geo_locations : {
      location          = coalesce(geo.location, var.location)
      failover_priority = geo.failover_priority
      zone_redundant    = geo.zone_redundant
    }
  ]
  capabilities = each.value.capabilities

  # Key-based reference: resolve each rule's subnet as vnet_key/subnet_key (pattern-managed subnet
  # in var.virtual_networks) -> direct subnet_id fallback.
  virtual_network_rules = [
    for rule in each.value.virtual_network_rules : {
      subnet_id = try(var.virtual_networks[rule.vnet_key].subnets[rule.subnet_key].resource_id, rule.subnet_id)
    }
  ]

  sql_dedicated_gateway = each.value.sql_dedicated_gateway

  # Encryption & identity
  lock = each.value.lock

  # Key-based reference: resolve customer_managed_key's Key Vault as key_vault_key (pattern-managed vault
  # in var.key_vaults) -> direct key_vault_resource_id, the key name as key_key (resolved from the key's
  # versionless_id in that vault's keys map, since the spoke output exposes versionless_id not name) ->
  # direct key_name, and the user-assigned identity as key (pattern-managed UAMI in var.managed_identities)
  # -> direct resource_id.
  customer_managed_key = each.value.customer_managed_key == null ? null : {
    key_name = (
      each.value.customer_managed_key.key_key != null
      ? reverse(split("/", var.key_vaults[each.value.customer_managed_key.key_vault_key].keys[each.value.customer_managed_key.key_key].versionless_id))[0]
      : each.value.customer_managed_key.key_name
    )
    key_version           = each.value.customer_managed_key.key_version
    key_vault_resource_id = coalesce(each.value.customer_managed_key.key_vault_resource_id, try(var.key_vaults[each.value.customer_managed_key.key_vault_key].resource_id, null))
    user_assigned_identity = each.value.customer_managed_key.user_assigned_identity == null ? null : {
      resource_id = coalesce(each.value.customer_managed_key.user_assigned_identity.resource_id, try(var.managed_identities[each.value.customer_managed_key.user_assigned_identity.key].resource_id, null))
    }
  }

  # Key-based reference: resolve user_assigned_keys to UAMI resource IDs, merge with direct resource IDs.
  managed_identities = {
    system_assigned = each.value.managed_identities.system_assigned
    user_assigned_resource_ids = setunion(
      each.value.managed_identities.user_assigned_resource_ids,
      toset([for key in each.value.managed_identities.user_assigned_keys : var.managed_identities[key].resource_id])
    )
  }

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

  # Private networking
  private_endpoints_manage_dns_zone_group = each.value.private_endpoints_manage_dns_zone_group

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

  # Data plane
  sql_databases     = each.value.sql_databases
  mongo_databases   = each.value.mongo_databases
  gremlin_databases = each.value.gremlin_databases
}
