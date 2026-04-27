module "virtual_machine" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.20.0"

  for_each = var.virtual_machines

  name                = each.value.name
  location            = coalesce(each.value.location, var.location)
  resource_group_name = coalesce(each.value.resource_group_name, var.resource_groups[each.value.resource_group_key].name)
  zone                = each.value.zone
  enable_telemetry    = coalesce(each.value.enable_telemetry, var.enable_telemetry)
  tags                = merge(var.tags, each.value.tags)

  os_type                    = each.value.os_type
  sku_size                   = each.value.sku_size
  source_image_reference     = each.value.source_image_reference
  source_image_resource_id   = each.value.source_image_resource_id
  encryption_at_host_enabled = each.value.encryption_at_host_enabled

  # Key-based references in network interfaces:
  #   - subnet.vnet_key/subnet_key → resolved to private_ip_subnet_resource_id via virtual_networks output
  #   - load_balancer_key + backend_pool_name → resolved to LB backend pool resource ID via load_balancers output
  network_interfaces = {
    for nic_key, nic in each.value.network_interfaces : nic_key => merge(
      {
        name = nic.name
        ip_configurations = {
          for ipconfig_key, ipconfig in nic.ip_configurations : ipconfig_key => merge(
            ipconfig,
            {
              private_ip_subnet_resource_id = try(
                var.virtual_networks[ipconfig.subnet.vnet_key].subnets[ipconfig.subnet.subnet_key].resource_id,
                ipconfig.subnet.resource_id
              )
              load_balancer_backend_pools = {
                for lb_pool_key, lb_pool in ipconfig.load_balancer_backend_pools : lb_pool_key => {
                  load_balancer_backend_pool_resource_id = try(
                    var.load_balancers[lb_pool.load_balancer_key].azurerm_lb_backend_address_pool[lb_pool.backend_pool_key].id,
                    lb_pool.load_balancer_backend_pool_resource_id
                  )
                }
              }
            }
          )
        }
      },
      {
        accelerated_networking_enabled = nic.accelerated_networking_enabled
        application_security_groups    = nic.application_security_groups
        diagnostic_settings = nic.diagnostic_settings != null ? {
          for dk, dv in nic.diagnostic_settings : dk => {
            name                                     = dv.name
            event_hub_authorization_rule_resource_id = dv.event_hub_authorization_rule_resource_id
            event_hub_name                           = dv.event_hub_name
            log_analytics_destination_type           = dv.log_analytics_destination_type
            log_categories_and_groups                = dv.log_categories_and_groups
            marketplace_partner_resource_id          = dv.marketplace_partner_resource_id
            metric_categories                        = dv.metric_categories
            storage_account_resource_id              = dv.storage_account_resource_id
            workspace_resource_id                    = dv.use_default_log_analytics ? var.default_log_analytics_workspace_resource_id : dv.workspace_resource_id
          }
        } : null
        dns_servers             = nic.dns_servers
        inherit_tags            = nic.inherit_tags
        internal_dns_name_label = nic.internal_dns_name_label
        ip_forwarding_enabled   = nic.ip_forwarding_enabled
        lock_level              = nic.lock_level
        lock_name               = nic.lock_name
        network_security_groups = nic.network_security_groups
        resource_group_name     = nic.resource_group_name
        role_assignments = nic.role_assignments != null ? {
          for ra_key, ra in nic.role_assignments : ra_key => {
            role_definition_id_or_name             = ra.role_definition_id_or_name
            principal_id                           = ra.assign_to_caller ? data.azurerm_client_config.current.object_id : ra.managed_identity_key != null ? var.managed_identities[ra.managed_identity_key].principal_id : ra.principal_id
            description                            = ra.description
            skip_service_principal_aad_check       = ra.skip_service_principal_aad_check
            condition                              = ra.condition
            condition_version                      = ra.condition_version
            delegated_managed_identity_resource_id = ra.delegated_managed_identity_resource_id
            principal_type                         = ra.managed_identity_key != null ? "ServicePrincipal" : ra.principal_type
            assign_to_child_public_ip_addresses    = ra.assign_to_child_public_ip_addresses
          }
        } : null
        tags = nic.tags
      }
    )
  }

  # Key-based reference: resolve disk_encryption_set.key to DES resource ID
  os_disk = merge(
    each.value.os_disk,
    {
      disk_encryption_set_id = try(
        var.disk_encryption_sets[each.value.os_disk.disk_encryption_set.key].id,
        each.value.os_disk.disk_encryption_set.resource_id
      )
    }
  )

  # Key-based reference: resolve disk_encryption_set.key in each data disk to DES resource ID
  data_disk_managed_disks = {
    for k, v in each.value.data_disk_managed_disks : k => merge(
      v,
      {
        disk_encryption_set_resource_id = try(
          var.disk_encryption_sets[v.disk_encryption_set.key].id,
          v.disk_encryption_set.resource_id
        )
      }
    )
  }

  # Key-based references: resolve recovery_services_vault.key to RSV resource ID
  azure_backup_configurations = {
    for k, v in each.value.azure_backup_configurations : k => {
      recovery_vault_resource_id = try(
        var.recovery_services_vaults[v.recovery_services_vault.key].resource_id,
        v.recovery_services_vault.resource_id
      )
      backup_policy_resource_id = v.backup_policy_resource_id
      exclude_disk_luns         = v.exclude_disk_luns
      include_disk_luns         = v.include_disk_luns
    }
  }

  # Key-based reference: resolve key_vault_key to Key Vault resource ID for credential storage
  account_credentials = {
    admin_credentials                = each.value.account_credentials.admin_credentials
    password_authentication_disabled = each.value.account_credentials.password_authentication_disabled
    key_vault_configuration = each.value.account_credentials.key_vault_configuration != null ? merge(
      each.value.account_credentials.key_vault_configuration,
      {
        resource_id = try(
          var.key_vaults[each.value.account_credentials.key_vault_configuration.key_vault_key].resource_id,
          each.value.account_credentials.key_vault_configuration.resource_id
        )
      }
    ) : null
  }
  # Key-based reference: resolve managed_identity_keys to UAMI resource IDs
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

  computer_name                          = each.value.computer_name
  custom_data                            = each.value.custom_data
  user_data                              = each.value.user_data
  boot_diagnostics                       = each.value.boot_diagnostics
  boot_diagnostics_storage_account_uri   = each.value.boot_diagnostics_storage_account_uri
  allow_extension_operations             = each.value.allow_extension_operations
  availability_set_resource_id           = each.value.availability_set_resource_id
  capacity_reservation_group_resource_id = each.value.capacity_reservation_group_resource_id
  dedicated_host_resource_id             = each.value.dedicated_host_resource_id
  dedicated_host_group_resource_id       = each.value.dedicated_host_group_resource_id
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
  disk_controller_type                  = each.value.disk_controller_type
  edge_zone                             = each.value.edge_zone
  enable_automatic_updates              = each.value.enable_automatic_updates
  eviction_policy                       = each.value.eviction_policy
  extensions                            = each.value.extensions
  extensions_time_budget                = each.value.extensions_time_budget
  gallery_applications                  = each.value.gallery_applications
  hotpatching_enabled                   = each.value.hotpatching_enabled
  license_type                          = each.value.license_type
  lock                                  = try(coalesce(each.value.lock, var.lock), null)
  max_bid_price                         = each.value.max_bid_price
  patch_assessment_mode                 = each.value.patch_assessment_mode
  patch_mode                            = each.value.patch_mode
  plan                                  = each.value.plan
  platform_fault_domain                 = each.value.platform_fault_domain
  priority                              = each.value.priority
  provision_vm_agent                    = each.value.provision_vm_agent
  proximity_placement_group_resource_id = each.value.proximity_placement_group_resource_id
  role_assignments = {
    for key, ra in each.value.role_assignments : key => {
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
  role_assignments_system_managed_identity               = each.value.role_assignments_system_managed_identity
  secrets                                                = each.value.secrets
  secure_boot_enabled                                    = each.value.secure_boot_enabled
  shutdown_schedules                                     = each.value.shutdown_schedules
  timezone                                               = each.value.timezone
  virtual_machine_scale_set_resource_id                  = each.value.virtual_machine_scale_set_resource_id
  vtpm_enabled                                           = each.value.vtpm_enabled
  bypass_platform_safety_checks_on_user_schedule_enabled = each.value.bypass_platform_safety_checks_on_user_schedule_enabled
  reboot_setting                                         = each.value.reboot_setting
  data_disk_existing_disks                               = each.value.data_disk_existing_disks
  additional_unattend_contents                           = each.value.additional_unattend_contents
  winrm_listeners                                        = each.value.winrm_listeners
  termination_notification                               = each.value.termination_notification
  vm_additional_capabilities                             = each.value.vm_additional_capabilities
  maintenance_configuration_resource_ids                 = each.value.maintenance_configuration_resource_ids
  public_ip_configuration_details                        = each.value.public_ip_configuration_details
  run_commands                                           = each.value.run_commands
  run_commands_secrets                                   = each.value.run_commands_secrets
}
