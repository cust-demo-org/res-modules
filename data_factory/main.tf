data "azurerm_client_config" "current" {}

module "data_factory" {
  source  = "Azure/avm-res-datafactory-factory/azurerm"
  version = "0.1.0"

  for_each = var.data_factories

  name                = each.value.name
  location            = coalesce(each.value.location, var.location)
  resource_group_name = coalesce(each.value.resource_group_name, var.resource_groups[each.value.resource_group_key].name)
  enable_telemetry    = coalesce(each.value.enable_telemetry, var.enable_telemetry)
  tags                = merge(var.tags, each.value.tags)

  public_network_enabled          = each.value.public_network_enabled
  managed_virtual_network_enabled = each.value.managed_virtual_network_enabled

  # Resolve customer_managed_key object into the flat fields expected by the AVM data factory module
  # customer_managed_key_id expects a Key Vault Key URI, with optional key_version appended
  customer_managed_key_id = each.value.customer_managed_key != null ? (
    each.value.customer_managed_key.key_vault_key != null && each.value.customer_managed_key.key_key != null
    ? (each.value.customer_managed_key.key_version != null
      ? "https://${var.key_vaults[each.value.customer_managed_key.key_vault_key].name}.vault.azure.net/keys/${var.key_vaults[each.value.customer_managed_key.key_vault_key].keys[each.value.customer_managed_key.key_key].name}/${each.value.customer_managed_key.key_version}"
    : "https://${var.key_vaults[each.value.customer_managed_key.key_vault_key].name}.vault.azure.net/keys/${var.key_vaults[each.value.customer_managed_key.key_vault_key].keys[each.value.customer_managed_key.key_key].name}")
    : (each.value.customer_managed_key.key_version != null
      ? "https://${basename(each.value.customer_managed_key.key_vault_resource_id)}.vault.azure.net/keys/${each.value.customer_managed_key.key_name}/${each.value.customer_managed_key.key_version}"
    : "https://${basename(each.value.customer_managed_key.key_vault_resource_id)}.vault.azure.net/keys/${each.value.customer_managed_key.key_name}")
  ) : null
  customer_managed_key_identity_id = each.value.customer_managed_key != null ? (
    each.value.customer_managed_key.user_assigned_identity != null ? (
      each.value.customer_managed_key.user_assigned_identity.key != null
      ? var.managed_identities[each.value.customer_managed_key.user_assigned_identity.key].resource_id
      : each.value.customer_managed_key.user_assigned_identity.resource_id
    ) : null
  ) : null

  purview_id                              = each.value.purview_id
  private_endpoints_manage_dns_zone_group = each.value.private_endpoints_manage_dns_zone_group

  managed_identities = each.value.managed_identities != null ? {
    system_assigned = each.value.managed_identities.system_assigned
    user_assigned_resource_ids = try(
      toset([for key in each.value.managed_identities.user_assigned_managed_identity_keys : var.managed_identities[key].resource_id]),
      coalesce(each.value.managed_identities.user_assigned_resource_ids, toset([]))
    )
    } : {
    system_assigned            = false
    user_assigned_resource_ids = toset([])
  }

  # Key-based reference: resolve vnet_key/subnet_key in private endpoints to subnet resource IDs
  # resolve private_dns_zone.keys in private endpoints to private dns zone resource IDs
  # resolve managed_identity_key in private endpoint role assignments to principal IDs
  private_endpoints = {
    for pe_k, pe in each.value.private_endpoints : pe_k => {
      name = pe.name
      role_assignments = {
        for ra_key, ra in pe.role_assignments : ra_key => {
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
      lock = try(coalesce(pe.lock, var.lock), null)
      tags = merge(var.tags, pe.tags)
      subnet_resource_id = (
        pe.network_configuration.subnet_resource_id != null
        ? pe.network_configuration.subnet_resource_id
        : var.virtual_networks[pe.network_configuration.vnet_key].subnets[pe.network_configuration.subnet_key].resource_id
      )
      private_dns_zone_resource_ids = setunion(
        coalesce(try(pe.private_dns_zone.resource_ids, null), toset([])),
        toset([for k in coalesce(try(pe.private_dns_zone.keys, null), toset([])) : var.private_dns_zone_resource_ids[k]])
      )
      private_dns_zone_group_name             = pe.private_dns_zone_group_name
      application_security_group_associations = pe.application_security_group_associations
      private_service_connection_name         = pe.private_service_connection_name
      network_interface_name                  = pe.network_interface_name
      location                                = pe.location
      resource_group_name                     = pe.resource_group_name
      ip_configurations                       = pe.ip_configurations
    }
  }

  github_configuration = each.value.github_configuration
  vsts_configuration   = each.value.vsts_configuration
  global_parameters    = each.value.global_parameters
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

  # Key-based reference: resolve identity_key to identity_id, auto-calculate name if not provided
  credential_user_managed_identity = {
    for k, v in each.value.credential_user_managed_identity : k => {
      name = coalesce(
        v.name,
        v.identity_key != null ? var.managed_identities[v.identity_key].name : basename(v.identity_id)
      )
      identity_id = (
        v.identity_key != null
        ? var.managed_identities[v.identity_key].resource_id
        : v.identity_id
      )
      annotations = v.annotations
      description = v.description
    }
  }
  credential_service_principal = each.value.credential_service_principal

  integration_runtime_self_hosted = each.value.integration_runtime_self_hosted

  # Key-based reference: resolve key_vault_key to key_vault_id in linked_service_key_vault
  linked_service_key_vault = {
    for k, v in each.value.linked_service_key_vault : k => merge(
      v,
      {
        key_vault_id = try(
          var.key_vaults[v.key_vault_key].resource_id,
          v.key_vault_id
        )
      }
    )
  }

  linked_service_azure_blob_storage     = each.value.linked_service_azure_blob_storage
  linked_service_azure_file_storage     = each.value.linked_service_azure_file_storage
  linked_service_azure_sql_database     = each.value.linked_service_azure_sql_database
  linked_service_data_lake_storage_gen2 = each.value.linked_service_data_lake_storage_gen2
  linked_service_databricks             = each.value.linked_service_databricks
}