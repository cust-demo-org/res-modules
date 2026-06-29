variable "application_gateways" {
  type = map(object({
    # --- Standard module fields ---
    name                = string
    resource_group_key  = optional(string)
    resource_group_name = optional(string)
    location            = optional(string)
    tags                = optional(map(string), {})

    # --- Managed identity (repo pattern: adds user_assigned_keys) ---
    managed_identities = optional(object({
      system_assigned            = optional(bool, false)
      user_assigned_resource_ids = optional(set(string), [])
      user_assigned_keys         = optional(set(string), [])
    }), {})

    # --- SKU / scaling ---
    sku = optional(object({
      name     = string
      tier     = string
      capacity = optional(number, 2)
    }), { name = "Standard_v2", tier = "Standard_v2", capacity = 2 })
    autoscale_configuration = optional(object({
      min_capacity = optional(number, 1)
      max_capacity = optional(number, 2)
    }))
    zones = optional(set(string), ["1", "2", "3"])

    # --- Core toggles ---
    http2_enable                       = optional(bool, true)
    fips_enabled                       = optional(bool)
    enable_telemetry                   = optional(bool, true)
    force_firewall_policy_association  = optional(bool, true)
    app_gateway_waf_policy_resource_id = optional(string)
    app_gateway_waf_policy_key         = optional(string)
    global = optional(object({
      request_buffering_enabled  = bool
      response_buffering_enabled = bool
    }))

    # --- Gateway IP configuration (subnet binding) ---
    gateway_ip_configuration = object({
      name       = optional(string)
      vnet_key   = optional(string)
      subnet_key = optional(string)
      subnet_id  = optional(string)
    })

    # --- Frontend IP configuration ---
    frontend_ip_configuration_public_name = optional(string)
    frontend_ip_configuration_private = optional(object({
      name                            = optional(string)
      private_ip_address              = optional(string)
      private_ip_address_allocation   = optional(string)
      private_link_configuration_name = optional(string)
    }), {})
    public_ip_address_configuration = optional(object({
      resource_group_name              = optional(string)
      location                         = optional(string)
      create_public_ip_enabled         = optional(bool, true)
      public_ip_name                   = optional(string)
      public_ip_resource_id            = optional(string)
      public_ip_key                    = optional(string)
      allocation_method                = optional(string, "Static")
      ddos_protection_mode             = optional(string, "VirtualNetworkInherited")
      ddos_protection_plan_resource_id = optional(string)
      domain_name_label                = optional(string)
      idle_timeout_in_minutes          = optional(number, 4)
      ip_version                       = optional(string, "IPv4")
      public_ip_prefix_resource_id     = optional(string)
      reverse_fqdn                     = optional(string)
      sku                              = optional(string, "Standard")
      sku_tier                         = optional(string, "Regional")
      tags                             = optional(map(any), {})
      zones                            = optional(list(string))
    }), {})

    # --- Frontend ports ---
    frontend_ports = map(object({
      name = string
      port = number
    }))

    # --- Backend address pools ---
    backend_address_pools = map(object({
      name         = string
      fqdns        = optional(set(string))
      ip_addresses = optional(set(string))
    }))

    # --- Backend HTTP settings ---
    backend_http_settings = map(object({
      cookie_based_affinity                = optional(string, "Disabled")
      dedicated_backend_connection_enabled = optional(bool, false)
      name                                 = string
      port                                 = number
      protocol                             = string
      affinity_cookie_name                 = optional(string)
      host_name                            = optional(string)
      path                                 = optional(string)
      pick_host_name_from_backend_address  = optional(bool)
      probe_name                           = optional(string)
      request_timeout                      = optional(number)
      trusted_root_certificate_names       = optional(list(string))
      authentication_certificate = optional(list(object({
        name = string
      })))
      connection_draining = optional(object({
        drain_timeout_sec          = number
        enable_connection_draining = bool
      }))
    }))

    # --- HTTP listeners ---
    http_listeners = map(object({
      name                           = string
      frontend_port_name             = string
      frontend_ip_configuration_name = optional(string)
      firewall_policy_id             = optional(string)
      require_sni                    = optional(bool)
      host_name                      = optional(string)
      host_names                     = optional(list(string))
      ssl_certificate_name           = optional(string)
      ssl_profile_name               = optional(string)
      custom_error_configuration = optional(list(object({
        status_code           = string
        custom_error_page_url = string
      })))
    }))

    # --- Request routing rules ---
    request_routing_rules = map(object({
      name                        = string
      rule_type                   = string
      http_listener_name          = string
      backend_address_pool_name   = string
      priority                    = number
      url_path_map_name           = optional(string)
      backend_http_settings_name  = string
      redirect_configuration_name = optional(string)
      rewrite_rule_set_name       = optional(string)
    }))

    # --- URL path maps ---
    url_path_map_configurations = optional(map(object({
      name                                = string
      default_redirect_configuration_name = optional(string)
      default_rewrite_rule_set_name       = optional(string)
      default_backend_http_settings_name  = optional(string)
      default_backend_address_pool_name   = optional(string)
      path_rules = map(object({
        name                        = string
        paths                       = list(string)
        backend_address_pool_name   = optional(string)
        backend_http_settings_name  = optional(string)
        redirect_configuration_name = optional(string)
        rewrite_rule_set_name       = optional(string)
        firewall_policy_id          = optional(string)
      }))
    })))

    # --- Health probes ---
    probe_configurations = optional(map(object({
      name                                      = string
      host                                      = optional(string)
      interval                                  = number
      timeout                                   = number
      unhealthy_threshold                       = number
      protocol                                  = string
      port                                      = optional(number)
      path                                      = string
      pick_host_name_from_backend_http_settings = optional(bool)
      minimum_servers                           = optional(number)
      match = optional(object({
        body        = optional(string)
        status_code = optional(list(string))
      }))
    })))

    # --- Redirect configurations ---
    redirect_configuration = optional(map(object({
      include_path         = optional(bool)
      include_query_string = optional(bool)
      name                 = string
      redirect_type        = string
      target_listener_name = optional(string)
      target_url           = optional(string)
    })))

    # --- Rewrite rule sets ---
    rewrite_rule_set = optional(map(object({
      name = string
      rewrite_rules = optional(map(object({
        name          = string
        rule_sequence = number
        conditions = optional(map(object({
          ignore_case = optional(bool)
          negate      = optional(bool)
          pattern     = string
          variable    = string
        })))
        request_header_configurations = optional(map(object({
          header_name  = string
          header_value = string
        })))
        response_header_configurations = optional(map(object({
          header_name  = string
          header_value = string
        })))
        url = optional(object({
          components   = optional(string)
          path         = optional(string)
          query_string = optional(string)
          reroute      = optional(bool)
        }))
      })))
    })))

    # --- Custom error configuration ---
    custom_error_configuration = optional(map(object({
      custom_error_page_url = string
      status_code           = string
    })))

    # --- SSL / TLS ---
    ssl_certificates = optional(map(object({
      name                = string
      data                = optional(string)
      password            = optional(string)
      key_vault_secret_id = optional(string)
    })))
    ssl_policy = optional(object({
      cipher_suites        = optional(list(string))
      disabled_protocols   = optional(list(string))
      min_protocol_version = optional(string, "TLSv1_2")
      policy_name          = optional(string)
      policy_type          = optional(string)
    }))
    ssl_profile = optional(map(object({
      name                                 = string
      trusted_client_certificate_names     = optional(list(string))
      verify_client_cert_issuer_dn         = optional(bool, false)
      verify_client_certificate_revocation = optional(string, "OCSP")
      ssl_policy = optional(object({
        cipher_suites        = optional(list(string))
        disabled_protocols   = optional(list(string))
        min_protocol_version = optional(string, "TLSv1_2")
        policy_name          = optional(string)
        policy_type          = optional(string)
      }))
    })))

    # --- Certificates ---
    authentication_certificate = optional(map(object({
      data = string
      name = string
    })))
    trusted_client_certificate = optional(map(object({
      data = string
      name = string
    })))
    trusted_root_certificate = optional(map(object({
      data                = optional(string)
      key_vault_secret_id = optional(string)
      name                = string
    })))

    # --- Private link ---
    private_link_configuration = optional(set(object({
      name = string
      ip_configuration = list(object({
        name                          = string
        primary                       = bool
        private_ip_address            = optional(string)
        private_ip_address_allocation = string
        vnet_key                      = optional(string)
        subnet_key                    = optional(string)
        subnet_id                     = optional(string)
      }))
    })))

    # --- WAF (in-gateway configuration; only valid for WAF SKUs) ---
    waf_configuration = optional(object({
      enabled                  = bool
      file_upload_limit_mb     = optional(number)
      firewall_mode            = string
      max_request_body_size_kb = optional(number)
      request_body_check       = optional(bool)
      rule_set_type            = optional(string)
      rule_set_version         = string
      disabled_rule_group = optional(list(object({
        rule_group_name = string
        rules           = optional(list(number))
      })))
      exclusion = optional(list(object({
        match_variable          = string
        selector                = optional(string)
        selector_match_operator = optional(string)
      })))
    }))

    # --- Diagnostic settings ---
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
    })), {})

    # --- Role assignments ---
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})

    # --- Lock ---
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }))

    # --- Timeouts ---
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  }))

  description = <<-EOT
    Map of Application Gateways to create. The map key is arbitrary and is used by `for_each` and for downstream cross-references.

    Each object supports the following fields (mapped 1:1 to the `Azure/avm-res-network-applicationgateway/azurerm` module inputs unless noted):

    - `name` - (Required) The name of the Application Gateway. 1-80 chars, alphanumeric start, alphanumeric/underscore end.
    - `resource_group_key` - (Optional) **Pattern cross-reference**: the key of a resource group in the `resource_groups` variable, resolved to the resource group name. At least one of `resource_group_key` or `resource_group_name` must be provided.
    - `resource_group_name` - (Optional) The name of the resource group to deploy into. Overrides `resource_group_key`.
    - `location` - (Optional) Azure region. Defaults to `var.location` when not set.
    - `tags` - (Optional) A mapping of tags merged with `var.tags`. Defaults to `{}`.

    - `managed_identities` - (Optional) Managed identity configuration. Defaults to `{}`.
      - `system_assigned` - (Optional) Enable the system-assigned identity. Defaults to `false`.
      - `user_assigned_resource_ids` - (Optional) A set of user-assigned identity resource IDs. Defaults to `[]`.
      - `user_assigned_keys` - (Optional) **Pattern cross-reference**: the keys of managed identities in the `managed_identities` variable, resolved to UAMI resource IDs and merged with `user_assigned_resource_ids`. Defaults to `[]`.

    - `sku` - (Optional) The SKU configuration. Defaults to name/tier `Standard_v2` with capacity `2`.
      - `name` - (Required) The name of the SKU. Possible values are `Standard_v2` or `WAF_v2`.
      - `tier` - (Required) The tier of the SKU. Possible values are `Standard_v2` or `WAF_v2`.
      - `capacity` - (Optional) The capacity (1-125). Optional when `autoscale_configuration` is set.
    - `autoscale_configuration` - (Optional) Autoscale configuration.
      - `min_capacity` - (Optional) Minimum capacity (0-100). Defaults to `1`.
      - `max_capacity` - (Optional) Maximum capacity (2-125). Defaults to `2`.
    - `zones` - (Optional) A list of Availability Zones to place the gateway in. Defaults to `["1","2","3"]`.

    - `http2_enable` - (Optional) Enable HTTP/2. Defaults to `true`.
    - `fips_enabled` - (Optional) Is FIPS enabled on the Application Gateway?
    - `enable_telemetry` - (Optional) Controls AVM module telemetry. See <https://aka.ms/avm/telemetryinfo>. Defaults to `true`.
    - `force_firewall_policy_association` - (Optional) Associate the firewall policy with the gateway. Defaults to `true`.
    - `app_gateway_waf_policy_resource_id` - (Optional) The resource ID of the Web Application Firewall Policy. Takes precedence over `app_gateway_waf_policy_key`.
    - `app_gateway_waf_policy_key` - (Optional) **Pattern cross-reference**: the key of a WAF policy in the `web_application_firewall_policies` variable, resolved to its `resource_id`. Used when `app_gateway_waf_policy_resource_id` is not set.
    - `global` - (Optional) Global request/response buffering configuration.
      - `request_buffering_enabled` - (Required) Whether request buffering is enabled.
      - `response_buffering_enabled` - (Required) Whether response buffering is enabled.

    - `gateway_ip_configuration` - (Required) The Gateway IP configuration.
      - `name` - (Optional) The name of the Gateway IP Configuration.
      - `vnet_key` - (Optional) Key into `var.virtual_networks` to resolve the gateway subnet. Used with `subnet_key`. **Pattern cross-reference.**
      - `subnet_key` - (Optional) Subnet key within `var.virtual_networks[vnet_key].subnets` to resolve the gateway subnet resource ID. **Pattern cross-reference.**
      - `subnet_id` - (Optional) Direct resource ID of the Subnet the gateway connects to. Used as a fallback when `vnet_key`/`subnet_key` are not set. One of (`vnet_key` + `subnet_key`) or `subnet_id` is required.

    - `frontend_ip_configuration_public_name` - (Optional) Name of the public frontend IP configuration; inferred from the gateway name when null.
    - `frontend_ip_configuration_private` - (Optional) The private frontend IP configuration. Defaults to `{}`.
      - `name` - (Optional) The name of the private frontend IP configuration.
      - `private_ip_address` - (Optional) The private IP address.
      - `private_ip_address_allocation` - (Optional) The allocation method. Possible values are `Dynamic` or `Static`.
      - `private_link_configuration_name` - (Optional) The name of the associated private link configuration.
    - `public_ip_address_configuration` - (Optional) The public IP configuration. Defaults to `{}`.
      - `resource_group_name` - (Optional) The resource group for the public IP.
      - `location` - (Optional) The location for the public IP.
      - `create_public_ip_enabled` - (Optional) Whether to create the public IP. Defaults to `true`.
      - `public_ip_name` - (Optional) The name of the public IP.
      - `public_ip_resource_id` - (Optional) The resource ID of an existing public IP.
      - `public_ip_key` - (Optional) Key into `var.public_ips` to resolve an existing public IP resource ID. Takes precedence over `public_ip_resource_id` when set. **Pattern cross-reference.**
      - `allocation_method` - (Optional) The allocation method. Defaults to `Static`.
      - `ddos_protection_mode` - (Optional) The DDoS protection mode. Defaults to `VirtualNetworkInherited`.
      - `ddos_protection_plan_resource_id` - (Optional) The resource ID of the DDoS protection plan.
      - `domain_name_label` - (Optional) The domain name label.
      - `idle_timeout_in_minutes` - (Optional) The idle timeout in minutes (4-30). Defaults to `4`.
      - `ip_version` - (Optional) The IP version. Defaults to `IPv4`.
      - `public_ip_prefix_resource_id` - (Optional) The resource ID of the public IP prefix.
      - `reverse_fqdn` - (Optional) The reverse FQDN.
      - `sku` - (Optional) The public IP SKU. Defaults to `Standard`.
      - `sku_tier` - (Optional) The public IP SKU tier. Defaults to `Regional`.
      - `tags` - (Optional) A mapping of tags for the public IP. Defaults to `{}`.
      - `zones` - (Optional) Availability Zones for the public IP.

    - `frontend_ports` - (Required) A map of frontend ports.
      - `name` - (Required) The name of the frontend port.
      - `port` - (Required) The port number.

    - `backend_address_pools` - (Required) A map of backend address pools.
      - `name` - (Required) The name of the backend address pool.
      - `fqdns` - (Optional) A set of FQDNs in the pool.
      - `ip_addresses` - (Optional) A set of IP addresses in the pool.

    - `backend_http_settings` - (Required) A map of backend HTTP settings collections.
      - `name` - (Required) The name of the settings collection.
      - `port` - (Required) The port for the settings collection.
      - `protocol` - (Required) The protocol. Possible values are `Http` or `Https`.
      - `cookie_based_affinity` - (Optional) Cookie-based affinity. Possible values are `Enabled` or `Disabled`. Defaults to `Disabled`.
      - `dedicated_backend_connection_enabled` - (Optional) Whether a dedicated backend connection is enabled. Defaults to `false`.
      - `affinity_cookie_name` - (Optional) The name of the affinity cookie.
      - `host_name` - (Optional) The host header to send to the backend.
      - `path` - (Optional) The path used as a prefix for all HTTP requests.
      - `pick_host_name_from_backend_address` - (Optional) Whether to pick the host header from the backend host name.
      - `probe_name` - (Optional) The associated HTTP probe name.
      - `request_timeout` - (Optional) The request timeout in seconds (1-86400). Defaults to `30`.
      - `trusted_root_certificate_names` - (Optional) A list of trusted root certificate names.
      - `authentication_certificate` - (Optional) A list of authentication certificates.
        - `name` - (Required) The name of the authentication certificate.
      - `connection_draining` - (Optional) Connection draining configuration.
        - `drain_timeout_sec` - (Required) The drain timeout in seconds (1-3600).
        - `enable_connection_draining` - (Required) Whether connection draining is enabled.

    - `http_listeners` - (Required) A map of HTTP listeners.
      - `name` - (Required) The name of the listener.
      - `frontend_port_name` - (Required) The associated frontend port name.
      - `frontend_ip_configuration_name` - (Optional) The associated frontend IP configuration name.
      - `firewall_policy_id` - (Optional) The WAF policy ID for this listener.
      - `require_sni` - (Optional) Whether to require Server Name Indication.
      - `host_name` - (Optional) The hostname for the listener.
      - `host_names` - (Optional) The hostnames for multi-site listeners.
      - `ssl_certificate_name` - (Optional) The associated SSL certificate name.
      - `ssl_profile_name` - (Optional) The associated SSL profile name.
      - `custom_error_configuration` - (Optional) A list of custom error configurations.
        - `status_code` - (Required) The status code. Possible values are `HttpStatus403` or `HttpStatus502`.
        - `custom_error_page_url` - (Required) The URL of the custom error page.

    - `request_routing_rules` - (Required) A map of request routing rules.
      - `name` - (Required) The name of the rule.
      - `rule_type` - (Required) The rule type. Possible values are `Basic` or `PathBasedRouting`.
      - `http_listener_name` - (Required) The associated HTTP listener name.
      - `backend_address_pool_name` - (Required) The associated backend address pool name.
      - `backend_http_settings_name` - (Required) The associated backend HTTP settings name.
      - `priority` - (Required) The rule priority (1-20000, 1 highest).
      - `url_path_map_name` - (Optional) The associated URL path map name.
      - `redirect_configuration_name` - (Optional) The associated redirect configuration name.
      - `rewrite_rule_set_name` - (Optional) The associated rewrite rule set name (v2 SKU only).

    - `url_path_map_configurations` - (Optional) A map of URL path maps.
      - `name` - (Required) The name of the URL path map.
      - `default_redirect_configuration_name` - (Optional) The default redirect configuration name.
      - `default_rewrite_rule_set_name` - (Optional) The default rewrite rule set name.
      - `default_backend_http_settings_name` - (Optional) The default backend HTTP settings name.
      - `default_backend_address_pool_name` - (Optional) The default backend address pool name.
      - `path_rules` - (Required) A map of path rules.
        - `name` - (Required) The name of the path rule.
        - `paths` - (Required) A list of paths to match.
        - `backend_address_pool_name` - (Optional) The associated backend address pool name.
        - `backend_http_settings_name` - (Optional) The associated backend HTTP settings name.
        - `redirect_configuration_name` - (Optional) The associated redirect configuration name.
        - `rewrite_rule_set_name` - (Optional) The associated rewrite rule set name.
        - `firewall_policy_id` - (Optional) The associated WAF policy ID.

    - `probe_configurations` - (Optional) A map of health probes.
      - `name` - (Required) The name of the probe.
      - `interval` - (Required) The probe interval in seconds.
      - `timeout` - (Required) The probe timeout in seconds.
      - `unhealthy_threshold` - (Required) The unhealthy threshold count.
      - `protocol` - (Required) The protocol. Possible values are `Http` or `Https`.
      - `path` - (Required) The probe path.
      - `host` - (Optional) The host to send the probe to.
      - `port` - (Optional) The port used for the probe.
      - `pick_host_name_from_backend_http_settings` - (Optional) Whether to pick the host name from the backend HTTP settings.
      - `minimum_servers` - (Optional) The minimum number of servers that are always marked healthy.
      - `match` - (Optional) The probe match configuration.
        - `body` - (Optional) The body that must be contained in the response.
        - `status_code` - (Optional) A list of allowed status codes.

    - `redirect_configuration` - (Optional) A map of redirect configurations.
      - `name` - (Required) The unique name of the redirect configuration.
      - `redirect_type` - (Required) The redirect type. Possible values are `Permanent`, `Temporary`, `Found` or `SeeOther`.
      - `include_path` - (Optional) Whether to include the path in the redirect.
      - `include_query_string` - (Optional) Whether to include the query string in the redirect.
      - `target_listener_name` - (Optional) The name of the target listener.
      - `target_url` - (Optional) The target URL.

    - `rewrite_rule_set` - (Optional) A map of rewrite rule sets.
      - `name` - (Required) The unique name of the rewrite rule set.
      - `rewrite_rules` - (Optional) A map of rewrite rules.
        - `name` - (Required) The name of the rewrite rule.
        - `rule_sequence` - (Required) The rule sequence (lower is applied first).
        - `conditions` - (Optional) The match conditions for the rule.
        - `request_header_configurations` - (Optional) Request header rewrite configurations.
        - `response_header_configurations` - (Optional) Response header rewrite configurations.
        - `url` - (Optional) The URL rewrite configuration.

    - `custom_error_configuration` - (Optional) A map of custom error configurations.
      - `custom_error_page_url` - (Required) The URL of the custom error page.
      - `status_code` - (Required) The status code. Possible values are `HttpStatus403` or `HttpStatus502`.

    - `ssl_certificates` - (Optional) A map of SSL certificates.
      - `name` - (Required) The name of the SSL certificate.
      - `data` - (Optional) The base64-encoded PFX certificate data.
      - `password` - (Optional) The password for the PFX certificate.
      - `key_vault_secret_id` - (Optional) The Key Vault secret ID of the certificate.
    - `ssl_policy` - (Optional) The SSL policy configuration.
      - `cipher_suites` - (Optional) A list of cipher suites.
      - `disabled_protocols` - (Optional) A list of disabled protocols.
      - `min_protocol_version` - (Optional) The minimum TLS protocol version. Defaults to `TLSv1_2`.
      - `policy_name` - (Optional) The predefined policy name.
      - `policy_type` - (Optional) The policy type. Possible values are `Predefined`, `Custom` or `CustomV2`.
    - `ssl_profile` - (Optional) A map of SSL profiles.
      - `name` - (Required) The name of the SSL profile.
      - `trusted_client_certificate_names` - (Optional) A list of trusted client certificate names.
      - `verify_client_cert_issuer_dn` - (Optional) Whether to verify the client certificate issuer DN. Defaults to `false`.
      - `verify_client_certificate_revocation` - (Optional) The client certificate revocation check. Defaults to `OCSP`.
      - `ssl_policy` - (Optional) The SSL policy for this profile (same fields as the top-level `ssl_policy`).

    - `authentication_certificate` - (Optional) A map of authentication certificates.
      - `data` - (Required) The base64-encoded certificate data.
      - `name` - (Required) The name of the authentication certificate.
    - `trusted_client_certificate` - (Optional) A map of trusted client certificates.
      - `data` - (Required) The base64-encoded certificate data.
      - `name` - (Required) The name of the trusted client certificate.
    - `trusted_root_certificate` - (Optional) A map of trusted root certificates.
      - `name` - (Required) The name of the trusted root certificate.
      - `data` - (Optional) The base64-encoded certificate data.
      - `key_vault_secret_id` - (Optional) The Key Vault secret ID of the certificate.

    - `private_link_configuration` - (Optional) A set of private link configurations.
      - `name` - (Required) The name of the private link configuration.
      - `ip_configuration` - (Required) A list of IP configurations.
        - `name` - (Required) The name of the IP configuration.
        - `primary` - (Required) Whether this is the primary IP configuration.
        - `private_ip_address_allocation` - (Required) The allocation method. Possible values are `Dynamic` or `Static`.
        - `vnet_key` - (Optional) Key into `var.virtual_networks` to resolve the subnet. Used with `subnet_key`. **Pattern cross-reference.**
        - `subnet_key` - (Optional) Subnet key within `var.virtual_networks[vnet_key].subnets` to resolve the subnet resource ID. **Pattern cross-reference.**
        - `subnet_id` - (Optional) Direct resource ID of the subnet. Used as a fallback when `vnet_key`/`subnet_key` are not set.
        - `private_ip_address` - (Optional) The private IP address.

    - `waf_configuration` - (Optional) The WAF configuration. Only valid for WAF SKUs.
      - `enabled` - (Required) Whether the WAF is enabled.
      - `firewall_mode` - (Required) The firewall mode. Possible values are `Detection` or `Prevention`.
      - `rule_set_version` - (Required) The rule set version (e.g. `3.2`).
      - `file_upload_limit_mb` - (Optional) The file upload limit in MB.
      - `max_request_body_size_kb` - (Optional) The maximum request body size in KB.
      - `request_body_check` - (Optional) Whether to check the request body.
      - `rule_set_type` - (Optional) The rule set type.
      - `disabled_rule_group` - (Optional) A list of disabled rule groups.
        - `rule_group_name` - (Required) The name of the rule group.
        - `rules` - (Optional) A list of rules to disable within the group.
      - `exclusion` - (Optional) A list of exclusions.
        - `match_variable` - (Required) The match variable.
        - `selector` - (Optional) The selector.
        - `selector_match_operator` - (Optional) The selector match operator.

    - `diagnostic_settings` - (Optional) A map of diagnostic settings to create on this resource. Defaults to `{}`.
      - `name` - (Optional) The name of the diagnostic setting. One will be generated if not set.
      - `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
      - `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
      - `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
      - `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
      - `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
      - `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
      - `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
      - `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
      - `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic Logs.

    - `role_assignments` - (Optional) A map of role assignments to create on this resource. Defaults to `{}`.
      - `role_definition_id_or_name` - (Required) The ID or name of the role definition to assign to the principal.
      - `principal_id` - (Required) The ID of the principal to assign the role to.
      - `description` - (Optional) The description of the role assignment.
      - `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to `false`.
      - `condition` - (Optional) The condition which will be used to scope the role assignment.
      - `condition_version` - (Optional) The version of the condition syntax. Valid values are `2.0`.
      - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. This field is only used in cross-tenant scenario.
      - `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`.

    - `lock` - (Optional) Controls the Resource Lock configuration for this resource.
      - `kind` - (Required) The type of lock. Possible values are `CanNotDelete` and `ReadOnly`.
      - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value.

    - `timeouts` - (Optional) The timeout configuration for the resource.
      - `create` - (Optional) The timeout for create operations.
      - `delete` - (Optional) The timeout for delete operations.
      - `read` - (Optional) The timeout for read operations.
      - `update` - (Optional) The timeout for update operations.

    > **Downstream references:** Other modules reference an Application Gateway by its map key via `var.application_gateways[<key>]` (the raw AVM module object, exposing `resource_id`, `application_gateway_id`, `application_gateway_name`, `public_ip_id`, etc.).
    > **Pattern note:** If `location` is not specified, defaults to `var.location`. Tags in `tags` are merged with `var.tags`. The gateway subnet (`gateway_ip_configuration` and `private_link_configuration[].ip_configuration[]`) and an existing public IP (`public_ip_address_configuration.public_ip_key`) are resolved by key against `var.virtual_networks` / `var.public_ips`, falling back to the direct `subnet_id` / `public_ip_resource_id`. Certificate and WAF policy IDs are passed as direct resource IDs.
  EOT
}

variable "location" {
  description = "Default location fallback when an Application Gateway does not set location."
  type        = string
}

variable "resource_groups" {
  description = "Resource groups output map from spoke module. Used to resolve resource_group_key to the resource group name."
  type        = any
  default     = {}
}

variable "managed_identities" {
  description = "Managed identities output map from spoke module. Used to resolve user_assigned_keys to UAMI resource IDs."
  type        = any
  default     = {}
}

variable "virtual_networks" {
  description = "Virtual networks output map from the connectivity/spoke pattern module. Used to resolve vnet_key + subnet_key to a subnet resource ID."
  type        = any
  default     = {}
}

variable "public_ips" {
  description = "Public IPs output map from the connectivity/spoke pattern module. Used to resolve public_ip_key to a public IP resource ID."
  type        = any
  default     = {}
}

variable "web_application_firewall_policies" {
  description = "Web Application Firewall policies output map from the web_application_firewall_policy module. Used to resolve app_gateway_waf_policy_key to a WAF policy resource ID."
  type        = any
  default     = {}
}

variable "tags" {
  description = "Default tags to merge with per-resource tags."
  type        = map(string)
  default     = {}
}
