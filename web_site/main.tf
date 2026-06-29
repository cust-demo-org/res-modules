data "azurerm_client_config" "current" {}

locals {
  # Application Insights managed-identity (AAD) auth: resolve the client ID (direct or via key).
  web_site_app_insights_mi_client_ids = {
    for k, v in var.web_sites : k => (
      v.application_insights_user_assigned_identity_client_id != null ? v.application_insights_user_assigned_identity_client_id : try(var.managed_identities[v.application_insights_user_assigned_identity_key].client_id, null)
    )
  }

  # Resolve the AI connection string / instrumentation key per site (direct → site_config → component ref).
  web_site_app_insights_connection_strings = {
    for k, v in var.web_sites : k => try(coalesce(
      v.application_insights_connection_string,
      v.site_config.application_insights_connection_string,
      try(var.application_insights[v.application_insights.key].connection_string, null)
    ), null)
  }
  web_site_app_insights_instrumentation_keys = {
    for k, v in var.web_sites : k => try(coalesce(
      v.application_insights_instrumentation_key,
      v.site_config.application_insights_key,
      try(var.application_insights[v.application_insights.key].instrumentation_key, null)
    ), null)
  }

  # All Application Insights app settings injected directly into app_settings (parent + slots) rather than
  # via the AVM site_config / top-level AI inputs: connection string (always when resolved), instrumentation
  # key (when NOT using managed identity), and the AAD auth string (when using managed identity).
  web_site_app_insights_app_settings = {
    for k, v in var.web_sites : k => merge(
      local.web_site_app_insights_connection_strings[k] != null ? { APPLICATIONINSIGHTS_CONNECTION_STRING = local.web_site_app_insights_connection_strings[k] } : {},
      (!v.application_insights_uses_managed_identity && local.web_site_app_insights_instrumentation_keys[k] != null) ? { APPINSIGHTS_INSTRUMENTATIONKEY = local.web_site_app_insights_instrumentation_keys[k] } : {},
      (v.application_insights_uses_managed_identity && local.web_site_app_insights_mi_client_ids[k] != null) ? { APPLICATIONINSIGHTS_AUTHENTICATION_STRING = "ClientId=${local.web_site_app_insights_mi_client_ids[k]};Authorization=AAD" } : {},
    )
  }

  # Per-slot Application Insights app settings. Slots inherit the site-level settings, so each slot key
  # ("<site_key>|<slot_key>") maps to its parent site's AI app settings. Used by module web_site below.
  web_site_slot_ai_app_settings = merge([
    for site_key, site in var.web_sites : {
      for slot_key, slot in site.deployment_slots :
      "${site_key}|${slot_key}" => local.web_site_app_insights_app_settings[site_key]
    }
  ]...)
}

module "web_site" {
  source  = "Azure/avm-res-web-site/azurerm"
  version = "0.22.0"

  for_each = var.web_sites

  enable_telemetry = var.enable_telemetry

  name      = each.value.name
  parent_id = each.value.resource_group_name != null ? "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${each.value.resource_group_name}" : var.resource_groups[each.value.resource_group_key].resource_id
  location  = coalesce(each.value.location, var.location)
  tags      = merge(var.tags, each.value.tags)

  # Key-based reference: resolve service_plan_key to a resource ID, falling back to the direct ID.
  service_plan_resource_id = each.value.service_plan_resource_id != null ? each.value.service_plan_resource_id : var.service_plans[each.value.service_plan_key].resource_id

  # Core settings
  kind       = each.value.kind
  os_type    = each.value.os_type
  enabled    = each.value.enabled
  https_only = each.value.https_only

  # Key-based reference: resolve user_assigned_keys to UAMI resource IDs, merge with direct resource IDs.
  managed_identities = {
    system_assigned = each.value.managed_identities.system_assigned
    user_assigned_resource_ids = setunion(
      each.value.managed_identities.user_assigned_resource_ids,
      toset([for key in each.value.managed_identities.user_assigned_keys : var.managed_identities[key].resource_id])
    )
  }

  # Client certificate
  client_certificate_enabled         = each.value.client_certificate_enabled
  client_certificate_mode            = each.value.client_certificate_mode
  client_certificate_exclusion_paths = each.value.client_certificate_exclusion_paths

  # Client affinity
  client_affinity_enabled              = each.value.client_affinity_enabled
  client_affinity_partitioning_enabled = each.value.client_affinity_partitioning_enabled
  client_affinity_proxy_enabled        = each.value.client_affinity_proxy_enabled

  # Networking
  public_network_access_enabled = each.value.public_network_access_enabled
  # Key-based reference: resolve network_configuration.vnet_key/subnet_key to a subnet
  # resource ID, falling back to the direct network_configuration.subnet_resource_id.
  virtual_network_subnet_id = each.value.network_configuration != null ? try(
    var.virtual_networks[each.value.network_configuration.vnet_key].subnets[each.value.network_configuration.subnet_key].resource_id,
    each.value.network_configuration.subnet_resource_id
  ) : null
  virtual_network_backup_restore_enabled = each.value.virtual_network_backup_restore_enabled
  vnet_application_traffic_enabled       = each.value.vnet_application_traffic_enabled
  vnet_content_share_enabled             = each.value.vnet_content_share_enabled
  vnet_image_pull_enabled                = each.value.vnet_image_pull_enabled
  vnet_route_all_traffic                 = each.value.vnet_route_all_traffic
  host_names_disabled                    = each.value.host_names_disabled
  ip_mode                                = each.value.ip_mode
  hosting_environment_id                 = each.value.hosting_environment_id
  managed_environment_id                 = each.value.managed_environment_id
  workload_profile_name                  = each.value.workload_profile_name

  # App settings: inject the Application Insights settings (connection string + instrumentation key, or the
  # AAD auth string when using managed identity) directly into app_settings rather than via the AVM
  # site_config / top-level AI inputs. These are not AVM-preset keys, so they survive the module's merge.
  app_settings       = merge(each.value.app_settings, local.web_site_app_insights_app_settings[each.key])
  connection_strings = each.value.connection_strings
  sticky_settings    = each.value.sticky_settings

  # Application Insights: injected via app_settings (above) instead of these inputs, so leave the AVM's
  # top-level AI inputs unset to avoid the module adding duplicate AI app settings.
  application_insights_connection_string = null
  application_insights_key               = null

  # Misc
  auto_generated_domain_name_label_scope = each.value.auto_generated_domain_name_label_scope
  end_to_end_encryption_enabled          = each.value.end_to_end_encryption_enabled
  hyper_v                                = each.value.hyper_v
  redundancy_mode                        = each.value.redundancy_mode
  scm_site_also_stopped                  = each.value.scm_site_also_stopped
  ssh_enabled                            = each.value.ssh_enabled
  all_child_resources_inherit_tags       = each.value.all_child_resources_inherit_tags

  # Publish basic auth
  ftp_publish_basic_authentication_enabled = each.value.ftp_publish_basic_authentication_enabled
  scm_publish_basic_authentication_enabled = each.value.scm_publish_basic_authentication_enabled

  # Function App
  functions_extension_version  = each.value.functions_extension_version
  function_app_uses_fc1        = each.value.function_app_uses_fc1
  builtin_logging_enabled      = each.value.builtin_logging_enabled
  content_share_force_disabled = each.value.content_share_force_disabled
  daily_memory_time_quota      = each.value.daily_memory_time_quota
  container_size               = each.value.container_size
  instance_memory_in_mb        = each.value.instance_memory_in_mb
  maximum_instance_count       = each.value.maximum_instance_count
  key_vault_reference_identity = each.value.key_vault_reference_identity != null ? each.value.key_vault_reference_identity : try(var.managed_identities[each.value.key_vault_reference_identity_key].resource_id, null)
  storage_account_name         = each.value.storage_account_name != null ? each.value.storage_account_name : try(var.storage_accounts[each.value.storage_account_key].name, null)
  # Logic Apps still need a real storage access key for WEBSITE_CONTENTAZUREFILECONNECTIONSTRING (the
  # content file share cannot use managed identity — only keys). When a key isn't provided directly,
  # resolve it from the referenced storage account (var.storage_accounts[...].primary_access_key) for
  # logic apps; for other kinds, managed-identity storage clears the key (""), else null.
  storage_account_access_key = (
    each.value.storage_account_access_key != null && each.value.storage_account_access_key != "" ?
    each.value.storage_account_access_key :
    each.value.kind == "logicapp" ? try(var.storage_accounts[each.value.storage_account_key].primary_access_key, null) : null
  )
  storage_account_required          = each.value.storage_account_required
  storage_account_share_name        = each.value.storage_account_share_name
  storage_authentication_type       = each.value.storage_authentication_type
  storage_container_type            = each.value.storage_container_type
  storage_container_endpoint        = each.value.storage_container_endpoint
  storage_user_assigned_identity_id = each.value.storage_user_assigned_identity_id != null ? each.value.storage_user_assigned_identity_id : try(var.managed_identities[each.value.storage_user_assigned_identity_key].resource_id, null)
  storage_uses_managed_identity     = each.value.storage_uses_managed_identity
  fc1_runtime_name                  = each.value.fc1_runtime_name
  fc1_runtime_version               = each.value.fc1_runtime_version
  always_ready                      = each.value.always_ready

  # Logic App
  bundle_version            = each.value.bundle_version
  use_extension_bundle      = each.value.use_extension_bundle
  logic_app_runtime_version = each.value.logic_app_runtime_version

  # Dapr / resource config
  dapr_config     = each.value.dapr_config
  resource_config = each.value.resource_config

  # DNS
  dns_configuration = each.value.dns_configuration

  # Lock / timeouts / retry
  lock     = each.value.lock
  timeouts = each.value.timeouts
  retry    = each.value.retry

  # Zip deploy
  zip_deploy_file          = each.value.zip_deploy_file
  zip_deploy_wait_duration = each.value.zip_deploy_wait_duration

  # Active slot
  app_service_active_slot = each.value.app_service_active_slot

  # Certificates: resolve each certificate's Key Vault as key_vault_key (pattern-managed
  # vault in var.key_vaults) → direct key_vault_id fallback. The extra key_vault_key field
  # is dropped on assignment to the AVM type.
  certificates = {
    for ck, cert in each.value.certificates : ck => merge(cert, {
      key_vault_id = cert.key_vault_id != null ? cert.key_vault_id : try(var.key_vaults[cert.key_vault_key].resource_id, null)
    })
  }

  # Custom domains
  custom_domains = each.value.custom_domains

  # Storage shares
  storage_shares_to_mount = each.value.storage_shares_to_mount

  # Backup
  backup = each.value.backup

  # Logs
  logs = each.value.logs

  # Diagnostic settings: resolve the destination workspace as workspace_resource_id →
  # workspace_key lookup → (when use_default_log_analytics is set) the first workspace in
  # var.log_analytics_workspaces → otherwise null (a workspace is not required). All other
  # AVM diagnostic-setting fields (logs/metrics/etc.) pass through unchanged; the extra
  # workspace_key / use_default_log_analytics fields are dropped on assignment to the AVM type.
  diagnostic_settings = {
    for dk, dv in each.value.diagnostic_settings : dk => merge(dv, {
      workspace_resource_id = try(coalesce(
        dv.workspace_resource_id,
        try(var.log_analytics_workspaces[dv.workspace_key].resource_id, null),
        dv.use_default_log_analytics ? try(values(var.log_analytics_workspaces)[0].resource_id, null) : null
      ), null)
    })
  }

  # Role assignments: resolve the principal as assign_to_caller (Terraform runner) →
  # managed_identity_key (pattern-managed UAMI principal) → explicit principal_id.
  role_assignments = {
    for ra_key, ra in each.value.role_assignments : ra_key => merge(ra, {
      principal_id   = ra.assign_to_caller ? data.azurerm_client_config.current.object_id : ra.managed_identity_key != null ? var.managed_identities[ra.managed_identity_key].principal_id : ra.principal_id
      principal_type = ra.managed_identity_key != null ? "ServicePrincipal" : ra.principal_type
    })
  }

  # Private endpoints: resolve each endpoint's subnet as vnet_key/subnet_key (pattern-managed
  # subnet in var.virtual_networks) → direct subnet_resource_id fallback, and resolve
  # private_dns_zone.keys (pattern-managed zones in var.private_dns_zones) merged with
  # private_dns_zone.resource_ids. The extra vnet_key / subnet_key / private_dns_zone fields
  # are dropped on assignment to the AVM type.
  private_endpoints = {
    for pk, pe in each.value.private_endpoints : pk => merge(pe, {
      subnet_resource_id = try(
        var.virtual_networks[pe.vnet_key].subnets[pe.subnet_key].resource_id,
        pe.subnet_resource_id
      )
      private_dns_zone_resource_ids = setunion(
        coalesce(try(pe.private_dns_zone.resource_ids, null), toset([])),
        toset([for k in coalesce(try(pe.private_dns_zone.keys, null), toset([])) : try(var.private_dns_zones[k].resource_id, var.private_dns_zones[k].id, var.private_dns_zones[k])])
      )
    })
  }
  private_endpoints_inherit_lock          = each.value.private_endpoints_inherit_lock
  private_endpoints_manage_dns_zone_group = each.value.private_endpoints_manage_dns_zone_group

  # Auth settings
  auth_settings    = each.value.auth_settings
  auth_settings_v2 = each.value.auth_settings_v2

  # Site configuration: null the AI connection string / instrumentation key here — they are injected into
  # app_settings instead (see app_settings above) so the AVM does not also add them.
  site_config = each.value.site_config

  # Deployment slots: inherit the site-level Application Insights settings — inject them into each slot's
  # app_settings and null the slot's site_config AI fields (so the AVM does not also add them). Non-AVM
  # slot fields are dropped on assignment.
  deployment_slots = {
    for sk, slot in each.value.deployment_slots : sk => merge(slot, {
      app_settings = merge(slot.app_settings, local.web_site_slot_ai_app_settings["${each.key}|${sk}"])
    })
  }
  deployment_slots_inherit_lock = each.value.deployment_slots_inherit_lock

  # Sensitive slot values
  slot_sensitive_app_settings                    = each.value.slot_sensitive_app_settings
  slots_storage_shares_to_mount_sensitive_values = each.value.slots_storage_shares_to_mount_sensitive_values
}

locals {
  # Resolve the storage account name and the user-assigned identity resource ID per site, mirroring
  # the resolution used on the main module (direct value → key lookup).
  web_site_storage_account_names = {
    for k, v in var.web_sites : k => (
      v.storage_account_name != null ? v.storage_account_name : try(var.storage_accounts[v.storage_account_key].name, null)
    )
  }
  web_site_storage_managed_identity_resource_ids = {
    for k, v in var.web_sites : k => (
      v.storage_user_assigned_identity_id != null ? v.storage_user_assigned_identity_id : try(var.managed_identities[v.storage_user_assigned_identity_key].resource_id, null)
    )
  }

  # When storage_uses_managed_identity is true, the AVM module does not configure identity-based
  # AzureWebJobsStorage correctly (logic apps hardcode a connection string; function apps only set
  # __accountName). Build the identity-based settings here and apply them via the config_appsettings
  # override below: set the blob/queue/table service URIs + credential, plus the UAMI resource ID when
  # a user-assigned identity is referenced (omitted for system-assigned). The plain AzureWebJobsStorage
  # key is removed entirely in web_site_effective_app_settings below (an empty value still errors).
  web_site_storage_managed_identity_app_settings = {
    for k, v in var.web_sites : k => (
      v.storage_uses_managed_identity && local.web_site_storage_account_names[k] != null ? merge(
        {
          AzureWebJobsStorage__blobServiceUri  = "https://${local.web_site_storage_account_names[k]}.blob.core.windows.net"
          AzureWebJobsStorage__queueServiceUri = "https://${local.web_site_storage_account_names[k]}.queue.core.windows.net"
          AzureWebJobsStorage__tableServiceUri = "https://${local.web_site_storage_account_names[k]}.table.core.windows.net"
          AzureWebJobsStorage__credential      = "managedidentity"
        },
        local.web_site_storage_managed_identity_resource_ids[k] != null ? {
          AzureWebJobsStorage__managedIdentityResourceId = local.web_site_storage_managed_identity_resource_ids[k]
        } : {}
      ) : {}
    )
  }



  # Sites needing a post-module app settings override: an explicit app_settings_override or managed-identity
  # storage (which requires removing the preset AzureWebJobsStorage — not possible via app_settings). This
  # predicate is plan-known (depends only on var.web_sites), so it is safe for for_each.
  web_site_needs_app_settings_override = toset([
    for k, v in var.web_sites : k
    if length(v.app_settings_override) > 0
    || (v.storage_uses_managed_identity && (v.storage_account_name != null || v.storage_account_key != null))
  ])

  # Effective FULL app settings to write via config_appsettings. The submodule's azapi_update_resource
  # REPLACES the appsettings collection (appsettings can't be read back via a plain GET), so we must
  # supply the COMPLETE desired set. We read the settings the main module wrote
  # (data.azapi_resource_action.web_site_app_settings) and merge our additions on top so nothing is
  # wiped: current AVM-computed settings → managed-identity storage settings → app_settings_override.
  # When managed-identity storage is used, the plain AzureWebJobsStorage key is dropped entirely (an
  # empty value still errors — it must be absent); the AzureWebJobsStorage__* settings replace it.
  web_site_effective_app_settings = {
    for k in local.web_site_needs_app_settings_override : k => {
      for kk, vv in merge(
        try(data.azapi_resource_action.web_site_app_settings[k].output.properties, {}),
        local.web_site_storage_managed_identity_app_settings[k],
        var.web_sites[k].app_settings_override,
      ) : kk => vv
      if !(var.web_sites[k].storage_uses_managed_identity && kk == "AzureWebJobsStorage")
    }
  }
}

# Read the app settings the main module wrote, so the override can carry them over instead of wiping
# them (azapi_update_resource replaces the whole collection). depends_on defers the list action until
# after the main module has configured the site's appsettings.
data "azapi_resource_action" "web_site_app_settings" {
  for_each = local.web_site_needs_app_settings_override

  type                   = "Microsoft.Web/sites@2025-03-01"
  resource_id            = module.web_site[each.key].resource_id
  action                 = "config/appsettings/list"
  method                 = "POST"
  response_export_values = ["properties"]

  depends_on = [module.web_site]
}

# Apply per-site app setting overrides AFTER the main module. The config_appsettings submodule
# REPLACES the site's appsettings, so we pass the FULL effective set (current settings read back +
# managed-identity storage settings + app_settings_override) — carrying existing settings over while
# overriding only the needed keys. depends_on ensures this runs after the main module's appsettings.
module "web_site_config_appsettings_override" {
  source  = "Azure/avm-res-web-site/azurerm//modules/config_appsettings"
  version = "0.22.0"

  for_each = local.web_site_needs_app_settings_override

  parent_id    = module.web_site[each.key].resource_id
  app_settings = local.web_site_effective_app_settings[each.key]
  retry        = var.web_sites[each.key].retry

  depends_on = [module.web_site]
}

# Flatten all (site, slot) pairs once to derive the set of slots that need a config_appsettings
# override (explicit app_settings_override only).
locals {
  web_site_slots_flat = merge([
    for site_key, site in var.web_sites : {
      for slot_key, slot in site.deployment_slots :
      "${site_key}|${slot_key}" => { site_key = site_key, slot_key = slot_key, slot = slot }
    }
  ]...)

  # Slots needing a post-module app settings override: an explicit app_settings_override only. (The AI
  # managed-identity auth string is injected directly into the slot's app_settings, so it does not
  # require this override.)
  web_site_slot_app_settings_overrides = {
    for fk, f in local.web_site_slots_flat : fk => {
      site_key  = f.site_key
      slot_key  = f.slot_key
      overrides = f.slot.app_settings_override
    }
    if length(f.slot.app_settings_override) > 0
  }
}

# Read each slot's current app settings so the slot override carries them over instead of wiping.
data "azapi_resource_action" "web_site_slot_app_settings" {
  for_each = local.web_site_slot_app_settings_overrides

  type                   = "Microsoft.Web/sites/slots@2025-03-01"
  resource_id            = module.web_site[each.value.site_key].deployment_slots[each.value.slot_key].id
  action                 = "config/appsettings/list"
  method                 = "POST"
  response_export_values = ["properties"]

  depends_on = [module.web_site]
}

# Same override mechanism for deployment slots. parent_id is the slot resource ID (from the main
# module's deployment_slots output) and is_slot = true. The submodule REPLACES, so we pass the full
# set: current slot settings read back + the slot's app_settings_override.
module "web_site_slot_config_appsettings_override" {
  source  = "Azure/avm-res-web-site/azurerm//modules/config_appsettings"
  version = "0.22.0"

  for_each = local.web_site_slot_app_settings_overrides

  parent_id = module.web_site[each.value.site_key].deployment_slots[each.value.slot_key].id
  app_settings = merge(
    try(data.azapi_resource_action.web_site_slot_app_settings[each.key].output.properties, {}),
    each.value.overrides,
  )
  is_slot = true
  retry   = var.web_sites[each.value.site_key].retry

  depends_on = [module.web_site]
}