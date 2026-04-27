variable "load_balancers" {
  type = map(object({
    name                = string
    resource_group_key  = optional(string)
    resource_group_name = optional(string)
    location            = optional(string)
    sku                 = optional(string, "Standard")
    sku_tier            = optional(string, "Regional")
    edge_zone           = optional(string)
    enable_telemetry    = optional(bool)
    tags                = optional(map(string), {})
    frontend_subnet = optional(object({
      vnet_key    = optional(string)
      subnet_key  = optional(string)
      resource_id = optional(string)
    }))
    frontend_ip_configurations = map(object({
      name                                               = optional(string)
      frontend_private_ip_address                        = optional(string)
      frontend_private_ip_address_version                = optional(string)
      frontend_private_ip_address_allocation             = optional(string, "Dynamic")
      frontend_private_ip_subnet_resource_id             = optional(string)
      gateway_load_balancer_frontend_ip_configuration_id = optional(string)
      public_ip_address_resource_name                    = optional(string)
      public_ip_address_resource_id                      = optional(string)
      public_ip_prefix_resource_id                       = optional(string)
      create_public_ip_address                           = optional(bool, false)
      new_public_ip_resource_group_name                  = optional(string)
      new_public_ip_location                             = optional(string)
      inherit_lock                                       = optional(bool, true)
      lock_type_if_not_inherited                         = optional(string)
      inherit_tags                                       = optional(bool, true)
      edge_zone                                          = optional(string)
      zones                                              = optional(list(string), ["1", "2", "3"])
      tags                                               = optional(map(any), {})
      role_assignments = optional(map(object({
        role_definition_id_or_name             = string
        principal_id                           = optional(string)
        managed_identity_key                   = optional(string)
        assign_to_caller                       = optional(bool, false)
        description                            = optional(string)
        skip_service_principal_aad_check       = optional(bool, false)
        condition                              = optional(string)
        condition_version                      = optional(string)
        delegated_managed_identity_resource_id = optional(string)
        principal_type                         = optional(string)
      })), {})
      diagnostic_settings = optional(map(object({
        name                                     = optional(string, null)
        log_categories                           = optional(set(string), [])
        log_groups                               = optional(set(string), ["allLogs"])
        metric_categories                        = optional(set(string), ["AllMetrics"])
        log_analytics_destination_type           = optional(string, "Dedicated")
        workspace_resource_id                    = optional(string, null)
        storage_account_resource_id              = optional(string, null)
        event_hub_authorization_rule_resource_id = optional(string, null)
        event_hub_name                           = optional(string, null)
        marketplace_partner_resource_id          = optional(string, null)
        use_default_log_analytics                = optional(bool, true)
      })), {})
    }))
    backend_address_pools = optional(map(object({
      name = optional(string)
      virtual_network = optional(object({
        key         = optional(string)
        resource_id = optional(string)
      }))
      tunnel_interfaces = optional(map(object({
        identifier = optional(number)
        type       = optional(string)
        protocol   = optional(string)
        port       = optional(number)
      })), {})
    })), {})
    backend_address_pool_addresses = optional(map(object({
      name                             = optional(string)
      backend_address_pool_object_name = optional(string)
      ip_address                       = optional(string)
      virtual_network_resource_id      = optional(string)
    })), {})
    backend_address_pool_configuration = optional(string)
    backend_address_pool_network_interfaces = optional(map(object({
      backend_address_pool_object_name = optional(string)
      ip_configuration_name            = optional(string)
      network_interface_resource_id    = optional(string)
    })), {})
    lb_probes = optional(map(object({
      name                            = optional(string)
      protocol                        = optional(string, "Tcp")
      port                            = optional(number, 80)
      interval_in_seconds             = optional(number, 15)
      probe_threshold                 = optional(number, 1)
      request_path                    = optional(string)
      number_of_probes_before_removal = optional(number, 2)
    })), {})
    lb_rules = optional(map(object({
      name                              = optional(string)
      frontend_ip_configuration_name    = optional(string)
      protocol                          = optional(string, "Tcp")
      frontend_port                     = optional(number, 3389)
      backend_port                      = optional(number, 3389)
      backend_address_pool_resource_ids = optional(list(string))
      backend_address_pool_object_names = optional(list(string))
      probe_resource_id                 = optional(string)
      probe_object_name                 = optional(string)
      enable_floating_ip                = optional(bool, false)
      idle_timeout_in_minutes           = optional(number, 4)
      load_distribution                 = optional(string, "Default")
      disable_outbound_snat             = optional(bool, false)
      enable_tcp_reset                  = optional(bool, false)
    })), {})
    lb_nat_rules = optional(map(object({
      name                             = optional(string)
      frontend_ip_configuration_name   = optional(string)
      protocol                         = optional(string)
      frontend_port                    = optional(number)
      backend_port                     = optional(number)
      frontend_port_start              = optional(number)
      frontend_port_end                = optional(number)
      backend_address_pool_resource_id = optional(string)
      backend_address_pool_object_name = optional(string)
      idle_timeout_in_minutes          = optional(number, 4)
      enable_floating_ip               = optional(bool, false)
      enable_tcp_reset                 = optional(bool, false)
    })), {})
    lb_nat_pools = optional(map(object({
      name                           = optional(string)
      frontend_ip_configuration_name = optional(string)
      protocol                       = optional(string, "Tcp")
      frontend_port_start            = optional(number, 3000)
      frontend_port_end              = optional(number, 3389)
      backend_port                   = optional(number, 3389)
      idle_timeout_in_minutes        = optional(number, 4)
      enable_floating_ip             = optional(bool, false)
      enable_tcp_reset               = optional(bool, false)
    })), {})
    lb_outbound_rules = optional(map(object({
      name = optional(string)
      frontend_ip_configurations = optional(list(object({
        name = optional(string)
      })))
      backend_address_pool_resource_id   = optional(string)
      backend_address_pool_object_name   = optional(string)
      protocol                           = optional(string, "Tcp")
      enable_tcp_reset                   = optional(bool, false)
      number_of_allocated_outbound_ports = optional(number, 1024)
      idle_timeout_in_minutes            = optional(number, 4)
    })), {})
    diagnostic_settings = optional(map(object({
      name                                     = optional(string, null)
      log_categories                           = optional(set(string), [])
      log_groups                               = optional(set(string), ["allLogs"])
      metric_categories                        = optional(set(string), ["AllMetrics"])
      log_analytics_destination_type           = optional(string, "Dedicated")
      workspace_resource_id                    = optional(string, null)
      storage_account_resource_id              = optional(string, null)
      event_hub_authorization_rule_resource_id = optional(string, null)
      event_hub_name                           = optional(string, null)
      marketplace_partner_resource_id          = optional(string, null)
      use_default_log_analytics                = optional(bool, true)
    })), {})
    lock = optional(object({
      kind = string
      name = optional(string)
    }))
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = optional(string)
      managed_identity_key                   = optional(string)
      assign_to_caller                       = optional(bool, false)
      description                            = optional(string)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string)
      condition_version                      = optional(string)
      delegated_managed_identity_resource_id = optional(string)
      principal_type                         = optional(string)
    })), {})
    public_ip_address_configuration = optional(object({
      resource_group_name              = optional(string)
      allocation_method                = optional(string, "Static")
      ddos_protection_mode             = optional(string, "VirtualNetworkInherited")
      ddos_protection_plan_resource_id = optional(string)
      domain_name_label                = optional(string)
      idle_timeout_in_minutes          = optional(number, 4)
      ip_tags                          = optional(map(string))
      ip_version                       = optional(string, "IPv4")
      public_ip_prefix_resource_id     = optional(string)
      reverse_fqdn                     = optional(string)
      sku                              = optional(string, "Standard")
      sku_tier                         = optional(string, "Regional")
      tags                             = optional(map(any), {})
    }), {})
  }))
  default     = {}
  description = <<-EOT
    A map of Azure Load Balancers to create. Each load balancer is deployed using the AVM `Azure/avm-res-network-loadbalancer/azurerm` module (v0.5.0).
    The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.

    - `name` - (Required) The name of the load balancer. Changing this forces a new resource to be created.
    - `resource_group_key` - (Required) **Pattern cross-reference**: the key of a resource group in the `resource_groups` variable (created by `spoke_network_and_share_services_pattern`). Resolved to the resource group name. At least one of `resource_group_key` or `resource_group_name` must be provided.
    - `resource_group_name` - (Optional) The name of the resource group to deploy the load balancer into. Overrides `resource_group_key`. At least one of `resource_group_key` or `resource_group_name` must be provided.
    - `location` - (Optional) The Azure region where the load balancer should be deployed. Defaults to `var.location`.
    - `sku` - (Optional) The SKU of the Load Balancer. Accepted values are `Standard` and `Gateway`. Defaults to `Standard`.
    - `sku_tier` - (Optional) The SKU tier. Possible values are `Global` and `Regional`. Defaults to `Regional`. Changing this forces a new resource to be created.
    - `edge_zone` - (Optional) Specifies the Edge Zone within the Azure Region where this Load Balancer should exist. Changing this forces new resources to be created.
    - `enable_telemetry` - (Optional) Override telemetry setting for this Load Balancer. Defaults to `var.enable_telemetry`.
    - `tags` - (Optional) Tags merged with `var.tags`. Defaults to `{}`.
    - `frontend_subnet` - (Optional) Subnet configuration for all frontend IP configurations in private mode. Provide either key-based references (`vnet_key`/`subnet_key`) or a direct `resource_id`, not both.
      - `vnet_key` - (Optional) **Pattern cross-reference**: the key of a virtual network in the `virtual_networks` variable. Used with `subnet_key`.
      - `subnet_key` - (Optional) **Pattern cross-reference**: the key of a subnet within the virtual network identified by `vnet_key`.
      - `resource_id` - (Optional) The subnet resource ID to use directly.
    - `frontend_ip_configurations` - (Required) A map of frontend IP configurations. You need at least one to deploy a load balancer.
      - `name` - (Optional) The name of the frontend IP configuration. Changing this forces a new resource to be created.
      - `frontend_private_ip_address` - (Optional) The private IP address to assign to the Load Balancer. The last one and first four IPs in any range are reserved and cannot be manually assigned.
      - `frontend_private_ip_address_version` - (Optional) The version of IP. Possible values are `IPv4` or `IPv6`.
      - `frontend_private_ip_address_allocation` - (Optional) The allocation method. Possible values are `Dynamic` or `Static`. Defaults to `Dynamic`.
      - `frontend_private_ip_subnet_resource_id` - (Optional) The ID of the subnet for this specific frontend IP. Overrides `frontend_subnet`.
      - `create_public_ip_address` - (Optional) Whether to create a new public IP. Defaults to `false`.
      - `public_ip_address_resource_name` - (Optional) Name of a new public IP to create and associate.
      - `public_ip_address_resource_id` - (Optional) The ID of an existing public IP to associate.
      - `public_ip_prefix_resource_id` - (Optional) The ID of a public IP prefix to associate.
      - `gateway_load_balancer_frontend_ip_configuration_id` - (Optional) The ID of a Gateway SKU Load Balancer Frontend IP Configuration.
      - `new_public_ip_resource_group_name` - (Optional) The resource group name for the new public IP. Defaults to the Load Balancer's resource group.
      - `new_public_ip_location` - (Optional) The location for the new public IP. Defaults to the Load Balancer's location.
      - `inherit_lock` - (Optional) Whether the public IP inherits the lock from the Load Balancer. Defaults to `true`.
      - `lock_type_if_not_inherited` - (Optional) The lock type if lock is not inherited. Possible values are `CanNotDelete` and `ReadOnly`.
      - `inherit_tags` - (Optional) Whether the public IP inherits tags from the Load Balancer. Defaults to `true`.
      - `edge_zone` - (Optional) The Edge Zone for the public IP. Changing this forces a new resource.
      - `zones` - (Optional) Availability zones for the public IP. Defaults to `["1", "2", "3"]`.
      - `tags` - (Optional) Tags for this frontend IP configuration. Defaults to `{}`.
      - `role_assignments` - (Optional) A map of role assignments on this frontend IP configuration. Defaults to `{}`.
        - `role_definition_id_or_name` - (Required) The ID or name of the role definition to assign to the principal.
        - `principal_id` - (Optional) The ID of the principal to assign the role to. Mutually exclusive with `managed_identity_key` and `assign_to_caller`.
        - `managed_identity_key` - (Optional) **Pattern cross-reference**: key of a managed identity in `var.managed_identities`. Resolved to the principal ID. Mutually exclusive with `principal_id`.
        - `assign_to_caller` - (Optional) If `true`, assigns the role to the current Terraform caller. Defaults to `false`. Mutually exclusive with `principal_id` and `managed_identity_key`.
        - `description` - (Optional) The description of the role assignment.
        - `skip_service_principal_aad_check` - (Optional) If true, skips the Azure Active Directory check for the service principal. Defaults to `false`.
        - `condition` - (Optional) The condition which will be used to scope the role assignment.
        - `condition_version` - (Optional) The version of the condition syntax. Valid values are `"2.0"`.
        - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Used in cross-tenant scenarios.
        - `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`.
      - `diagnostic_settings` - (Optional) A map of diagnostic settings. Defaults to `{}`.
        - `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
        - `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
        - `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
        - `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
        - `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
        - `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
        - `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
        - `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
        - `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
        - `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic Logs.
        - `use_default_log_analytics` - (Optional) When `true`, automatically sets the `workspace_resource_id` to the Log Analytics workspace created by this pattern. Defaults to `true`.
    - `backend_address_pools` - (Optional) A map of backend address pools. Defaults to `{}`.
      - `name` - (Optional) The name of the backend address pool.
      - `virtual_network` - (Optional) The virtual network for this backend pool. Provide either `key` or `resource_id`, not both.
        - `key` - (Optional) **Pattern cross-reference**: key of a virtual network in the `virtual_networks` variable. Resolved to the VNet resource ID.
        - `resource_id` - (Optional) The VNet resource ID to use directly.
      - `tunnel_interfaces` - (Optional) A map of tunnel interfaces for Gateway Load Balancer. Defaults to `{}`.
        - `identifier` - (Optional) The unique identifier of this Gateway Load Balancer Tunnel Interface.
        - `type` - (Optional) The traffic type. Possible values are `Internal` and `External`.
        - `protocol` - (Optional) The protocol. Possible values are `Native` and `VXLAN`.
        - `port` - (Optional) The port number that this tunnel interface is connected to.
    - `backend_address_pool_addresses` - (Optional) A map of backend address pool addresses. Defaults to `{}`.
      - `name` - (Optional) The name of the backend address pool address.
      - `backend_address_pool_object_name` - (Optional) The name of the backend address pool to add this address to.
      - `ip_address` - (Optional) The static IP Address of the backend address pool member.
      - `virtual_network_resource_id` - (Optional) The ID of the Virtual Network within which the backend address pool member exists.
    - `backend_address_pool_configuration` - (Optional) The backend address pool configuration. Can be `NicBased` (default if not present).
    - `backend_address_pool_network_interfaces` - (Optional) A map of NIC-based backend address pool associations. Defaults to `{}`.
      - `backend_address_pool_object_name` - (Optional) The name of the backend address pool.
      - `ip_configuration_name` - (Optional) The name of the IP configuration on the NIC.
      - `network_interface_resource_id` - (Optional) The resource ID of the Network Interface.
    - `lb_probes` - (Optional) A map of health probes. Defaults to `{}`.
      - `name` - (Optional) The name of the probe. Changing this forces a new probe to be created.
      - `protocol` - (Optional) The protocol. Possible values are `Http`, `Https`, or `Tcp`. If TCP is specified, a received ACK is required for the probe to be successful. If HTTP is specified, a 200 OK response from the specified URI is required. Defaults to `Tcp`.
      - `port` - (Optional) The port on which the probe queries the backend endpoint (1–65535). Defaults to `80`.
      - `interval_in_seconds` - (Optional) The interval, in seconds, between probes to the backend endpoint. Minimum value is `5`. Defaults to `15`.
      - `probe_threshold` - (Optional) The number of consecutive successful or failed probes that allow or deny traffic (1–100). Defaults to `1`.
      - `request_path` - (Optional) The URI used for requesting health status from the backend endpoint. Required if protocol is `Http` or `Https`. Otherwise, it is not allowed.
      - `number_of_probes_before_removal` - (Optional) The number of failed probe attempts after which the backend endpoint is removed from rotation. Defaults to `2`.
    - `lb_rules` - (Optional) A map of load balancing rules. Defaults to `{}`.
      - `name` - (Optional) The name of the rule. Changing this forces a new resource.
      - `frontend_ip_configuration_name` - (Optional) The frontend IP configuration name the rule is associated with.
      - `protocol` - (Optional) The transport protocol. Possible values are `All`, `Tcp`, or `Udp`. For HA ports, set `protocol = All`, `frontend_port = 0`, `backend_port = 0`. Defaults to `Tcp`.
      - `frontend_port` - (Optional) The external port (0–65534). Defaults to `3389`.
      - `backend_port` - (Optional) The internal port (0–65535). Defaults to `3389`.
      - `backend_address_pool_object_names` - (Optional) List of backend pool object names. Multiple pools only valid for Gateway SKU.
      - `backend_address_pool_resource_ids` - (Optional) List of backend pool resource IDs. Multiple pools only valid for Gateway SKU.
      - `probe_object_name` - (Optional) The health probe object name used by this rule.
      - `probe_resource_id` - (Optional) The health probe resource ID used by this rule.
      - `enable_floating_ip` - (Optional) Enable floating IP (Direct Server Return). Required for SQL AlwaysOn. Defaults to `false`.
      - `idle_timeout_in_minutes` - (Optional) TCP idle timeout (4–30 min). Defaults to `4`.
      - `load_distribution` - (Optional) Distribution type: `Default` (5-tuple hash), `SourceIP` (2-tuple), or `SourceIPProtocol` (3-tuple). Defaults to `Default`.
      - `disable_outbound_snat` - (Optional) Disable outbound SNAT. Set to `true` when the same frontend IP is referenced by an outbound rule. Defaults to `false`.
      - `enable_tcp_reset` - (Optional) Enable TCP Reset. Defaults to `false`.
    - `lb_nat_rules` - (Optional) A map of inbound NAT rules. Defaults to `{}`.
      - `name` - (Optional) The name of the NAT rule. Changing this forces a new resource.
      - `frontend_ip_configuration_name` - (Optional) The name of the frontend IP configuration exposing this rule.
      - `protocol` - (Optional) The transport protocol. Possible values are `All`, `Tcp`, or `Udp`.
      - `frontend_port` - (Optional) The port for the external endpoint (1–65534). Leave null or 0 if protocol is `All`.
      - `backend_port` - (Optional) The port used for internal connections (1–65535). Leave null or 0 if protocol is `All`.
      - `frontend_port_start` - (Optional) The port range start for the external endpoint. Used together with `backend_address_pool_resource_id`/`backend_address_pool_object_name` and `frontend_port_end`.
      - `frontend_port_end` - (Optional) The port range end for the external endpoint.
      - `backend_address_pool_resource_id` - (Optional) The ID of the backend address pool this NAT rule references.
      - `backend_address_pool_object_name` - (Optional) The name of the backend address pool this NAT rule references.
      - `idle_timeout_in_minutes` - (Optional) TCP idle timeout (4–30 min). Defaults to `4`.
      - `enable_floating_ip` - (Optional) Enable floating IP (Direct Server Return). Required to configure a SQL AlwaysOn Availability Group. Defaults to `false`.
      - `enable_tcp_reset` - (Optional) Enable TCP Reset. Defaults to `false`.
    - `lb_nat_pools` - (Optional) A map of inbound NAT pools (deprecated in favor of NAT rules with port ranges). Defaults to `{}`.
      - `name` - (Optional) The name of the NAT pool. Changing this forces a new resource.
      - `frontend_ip_configuration_name` - (Optional) The name of the frontend IP configuration.
      - `protocol` - (Optional) The transport protocol. Possible values are `All`, `Tcp`, or `Udp`. Defaults to `Tcp`.
      - `frontend_port_start` - (Optional) First port in the external port range. Defaults to `3000`.
      - `frontend_port_end` - (Optional) Last port in the external port range. Defaults to `3389`.
      - `backend_port` - (Optional) The port used for internal connections. Defaults to `3389`.
      - `idle_timeout_in_minutes` - (Optional) TCP idle timeout (4–30 min). Defaults to `4`.
      - `enable_floating_ip` - (Optional) Enable floating IP. Defaults to `false`.
      - `enable_tcp_reset` - (Optional) Enable TCP Reset. Defaults to `false`.
    - `lb_outbound_rules` - (Optional) A map of outbound rules. Defaults to `{}`.
      - `name` - (Optional) The name of the outbound rule. Changing this forces a new resource.
      - `frontend_ip_configurations` - (Optional) A list of frontend IP configuration objects.
        - `name` - (Optional) The name of the frontend IP configuration.
      - `backend_address_pool_resource_id` - (Optional) An ID referencing a Backend Address Pool.
      - `backend_address_pool_object_name` - (Optional) A name referencing a Backend Address Pool.
      - `protocol` - (Optional) The transport protocol. Possible values are `All`, `Tcp`, or `Udp`. Defaults to `Tcp`.
      - `enable_tcp_reset` - (Optional) Enable TCP Reset. Defaults to `false`.
      - `number_of_allocated_outbound_ports` - (Optional) The number of outbound ports to allocate. Defaults to `1024`.
      - `idle_timeout_in_minutes` - (Optional) TCP idle timeout (4–30 min). Defaults to `4`.
    - `diagnostic_settings` - (Optional) A map of diagnostic settings. Defaults to `{}`.
      - `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
      - `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
      - `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
      - `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
      - `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
      - `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
      - `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
      - `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
      - `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
      - `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic Logs.
      - `use_default_log_analytics` - (Optional) When `true`, automatically sets the `workspace_resource_id` to the Log Analytics workspace created by this pattern. Defaults to `true`.
    - `lock` - (Optional) Resource lock configuration for the Load Balancer.
      - `kind` - (Required) The type of lock. Possible values are `CanNotDelete` and `ReadOnly`.
      - `name` - (Optional) The name of the lock.
    - `role_assignments` - (Optional) A map of role assignments on the Load Balancer. Defaults to `{}`.
      - `role_definition_id_or_name` - (Required) The ID or name of the role definition to assign to the principal.
      - `principal_id` - (Optional) The ID of the principal to assign the role to. Mutually exclusive with `managed_identity_key` and `assign_to_caller`.
      - `managed_identity_key` - (Optional) **Pattern cross-reference**: key of a managed identity in `var.managed_identities`. Resolved to the principal ID. Mutually exclusive with `principal_id`.
      - `assign_to_caller` - (Optional) If `true`, assigns the role to the current Terraform caller. Defaults to `false`. Mutually exclusive with `principal_id` and `managed_identity_key`.
      - `description` - (Optional) The description of the role assignment.
      - `skip_service_principal_aad_check` - (Optional) If true, skips the Azure Active Directory check for the service principal. Defaults to `false`.
      - `condition` - (Optional) The condition which will be used to scope the role assignment.
      - `condition_version` - (Optional) The version of the condition syntax. Valid values are `"2.0"`.
      - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Used in cross-tenant scenarios.
      - `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`.
    - `public_ip_address_configuration` - (Optional) Common configuration applied to all public IPs created by this Load Balancer. Defaults to `{}`.
      - `resource_group_name` - (Optional) The resource group for the public IP resources.
      - `allocation_method` - (Optional) The allocation method. Possible values are `Static` or `Dynamic`. Defaults to `Static`.
      - `ddos_protection_mode` - (Optional) The DDoS protection mode. Defaults to `VirtualNetworkInherited`.
      - `ddos_protection_plan_resource_id` - (Optional) The ID of the DDoS protection plan.
      - `domain_name_label` - (Optional) Label for the Domain Name.
      - `idle_timeout_in_minutes` - (Optional) TCP idle timeout (4–30 min). Defaults to `4`.
      - `ip_tags` - (Optional) A mapping of IP tags.
      - `ip_version` - (Optional) `IPv4` or `IPv6`. Defaults to `IPv4`.
      - `public_ip_prefix_resource_id` - (Optional) The ID of a public IP prefix.
      - `reverse_fqdn` - (Optional) A fully qualified domain name that resolves to this public IP.
      - `sku` - (Optional) `Basic` or `Standard`. Defaults to `Standard`.
      - `sku_tier` - (Optional) `Regional` or `Global`. Defaults to `Regional`.
      - `tags` - (Optional) Tags for all public IP resources.

    > **Pattern note:** If `location` is not specified, defaults to `var.location`. Tags in `tags` are merged with `var.tags`.
  EOT
}

variable "location" {
  description = "Default location fallback when a load balancer object does not set location."
  type        = string
}

variable "resource_groups" {
  description = "Resource groups map (must include name). Used when a load balancer provides resource_group_key instead of resource_group_name."
  type        = any
}

variable "enable_telemetry" {
  description = "Default telemetry flag fallback when a load balancer object does not set enable_telemetry."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Object level tags to be appended to the default tags."
  type        = map(string)
  default     = {}
}

variable "lock" {
  description = "Default lock fallback when a load balancer object does not set lock."
  type = object({
    kind = string
    name = optional(string, null)
  })
  default = null
}

variable "default_log_analytics_workspace_resource_id" {
  description = "Default Log Analytics Workspace resource ID for diagnostic settings when not specified at the Data Factory object level."
  type        = string
  default     = null
}

variable "virtual_networks" {
  description = "Virtual networks output map from spoke module. Used to resolve vnet_key/subnet_key references in frontend_subnet and backend_address_pools."
  type        = any
  default     = {}
}

variable "managed_identities" {
  description = "Managed identities output map from spoke module. Used to resolve role assignment principal IDs."
  type        = any
  default     = {}
}