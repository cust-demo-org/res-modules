variable "web_sites" {
  type = map(object({
    # --- Standard module fields ---
    name                = string
    resource_group_key  = optional(string)
    resource_group_name = optional(string)
    location            = optional(string)
    tags                = optional(map(string), {})

    # --- Core App Service settings ---
    kind                     = optional(string, "webapp")
    os_type                  = optional(string, "Linux")
    service_plan_resource_id = optional(string)
    service_plan_key         = optional(string)
    enabled                  = optional(bool, true)
    https_only               = optional(bool, true)

    # --- Managed identity (repo pattern: adds user_assigned_keys) ---
    managed_identities = optional(object({
      system_assigned            = optional(bool, false)
      user_assigned_resource_ids = optional(set(string), [])
      user_assigned_keys         = optional(set(string), [])
    }), {})

    # --- Client certificate ---
    client_certificate_enabled         = optional(bool, false)
    client_certificate_mode            = optional(string, "Required")
    client_certificate_exclusion_paths = optional(string)

    # --- Client affinity ---
    client_affinity_enabled              = optional(bool, false)
    client_affinity_partitioning_enabled = optional(bool)
    client_affinity_proxy_enabled        = optional(bool)

    # --- Networking ---
    public_network_access_enabled = optional(bool, false)
    # VNet integration: key-based reference to a pattern-managed subnet, resolved to virtual_network_subnet_id.
    network_configuration = optional(object({
      vnet_key           = optional(string)
      subnet_key         = optional(string)
      subnet_resource_id = optional(string)
    }))
    virtual_network_backup_restore_enabled = optional(bool, false)
    vnet_application_traffic_enabled       = optional(bool, false)
    vnet_content_share_enabled             = optional(bool, false)
    vnet_image_pull_enabled                = optional(bool, false)
    vnet_route_all_traffic                 = optional(bool, false)
    host_names_disabled                    = optional(bool)
    ip_mode                                = optional(string)
    hosting_environment_id                 = optional(string)
    managed_environment_id                 = optional(string)
    workload_profile_name                  = optional(string)

    # --- App settings / connection strings ---
    app_settings = optional(map(string), {})
    # Applied AFTER the AVM module via the config_appsettings submodule (azapi_update_resource merge),
    # so these keys override AVM-preset app settings (e.g. WEBSITE_NODE_DEFAULT_VERSION,
    # FUNCTIONS_WORKER_RUNTIME) that the module's locals would otherwise force, while leaving all
    # other computed settings untouched. Use this for keys that `app_settings` cannot override.
    app_settings_override = optional(map(string), {})
    connection_strings = optional(map(object({
      name  = optional(string)
      type  = optional(string)
      value = optional(string)
    })), {})
    sticky_settings = optional(map(object({
      app_setting_names       = optional(list(string))
      connection_string_names = optional(list(string))
    })), {})

    # --- Application Insights ---
    application_insights_connection_string   = optional(string)
    application_insights_instrumentation_key = optional(string)
    # Key-based reference to an Application Insights component (resolves both the connection string and instrumentation key).
    application_insights = optional(object({
      key = optional(string)
    }))
    # Managed-identity (Entra/AAD) authentication for Application Insights. When true, the instrumentation
    # key is not set and APPLICATIONINSIGHTS_AUTHENTICATION_STRING = "ClientId=<client_id>;Authorization=AAD"
    # is injected directly into app_settings. The client ID is resolved from
    # application_insights_user_assigned_identity_client_id, else from _key via var.managed_identities.
    application_insights_uses_managed_identity            = optional(bool, false)
    application_insights_user_assigned_identity_client_id = optional(string)
    application_insights_user_assigned_identity_key       = optional(string)

    # --- Misc App Service ---
    auto_generated_domain_name_label_scope = optional(string)
    end_to_end_encryption_enabled          = optional(bool)
    hyper_v                                = optional(bool)
    redundancy_mode                        = optional(string)
    scm_site_also_stopped                  = optional(bool)
    ssh_enabled                            = optional(bool)
    all_child_resources_inherit_tags       = optional(bool, true)

    # --- Basic authentication for publish ---
    ftp_publish_basic_authentication_enabled = optional(bool, false)
    scm_publish_basic_authentication_enabled = optional(bool, true)

    # --- Function App settings ---
    functions_extension_version        = optional(string, "~4")
    function_app_uses_fc1              = optional(bool, false)
    builtin_logging_enabled            = optional(bool, true)
    content_share_force_disabled       = optional(bool, false)
    daily_memory_time_quota            = optional(number, 0)
    container_size                     = optional(number)
    instance_memory_in_mb              = optional(number, 2048)
    maximum_instance_count             = optional(number)
    key_vault_reference_identity       = optional(string)
    key_vault_reference_identity_key   = optional(string)
    storage_account_name               = optional(string)
    storage_account_key                = optional(string)
    storage_account_access_key         = optional(string)
    storage_account_required           = optional(bool)
    storage_account_share_name         = optional(string)
    storage_authentication_type        = optional(string)
    storage_container_type             = optional(string)
    storage_container_endpoint         = optional(string)
    storage_user_assigned_identity_id  = optional(string)
    storage_user_assigned_identity_key = optional(string)
    storage_uses_managed_identity      = optional(bool, false)
    fc1_runtime_name                   = optional(string)
    fc1_runtime_version                = optional(string)
    always_ready = optional(map(object({
      name           = optional(string)
      instance_count = optional(number, 0)
    })), {})

    # --- Logic App settings ---
    bundle_version            = optional(string, "[1.*, 2.0.0)")
    use_extension_bundle      = optional(bool, true)
    logic_app_runtime_version = optional(string, "~4")

    # --- Dapr (Container Apps hosted) ---
    dapr_config = optional(object({
      app_id                = optional(string)
      app_port              = optional(number)
      enable_api_logging    = optional(bool)
      enabled               = optional(bool)
      http_max_request_size = optional(number)
      http_read_buffer_size = optional(number)
      log_level             = optional(string)
    }))
    resource_config = optional(object({
      cpu    = optional(number)
      memory = optional(string)
    }))

    # --- DNS configuration ---
    dns_configuration = optional(object({
      dns_alt_server            = optional(string)
      dns_max_cache_timeout     = optional(number)
      dns_retry_attempt_count   = optional(number)
      dns_retry_attempt_timeout = optional(number)
      dns_servers               = optional(list(string))
    }))

    # --- Lock ---
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }))

    # --- Timeouts / retry ---
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
    retry = optional(object({
      error_message_regex = list(string)
      interval_seconds    = optional(number, 10)
      max_retries         = optional(number, 3)
    }))

    # --- Zip deploy ---
    zip_deploy_file          = optional(string)
    zip_deploy_wait_duration = optional(string, "60s")

    # --- Active slot ---
    app_service_active_slot = optional(object({
      slot_key                 = optional(string)
      overwrite_network_config = optional(bool, true)
    }))

    # --- Certificates (Microsoft.Web/certificates) ---
    certificates = optional(map(object({
      name                  = optional(string)
      key_vault_id          = optional(string)
      key_vault_key         = optional(string)
      key_vault_secret_name = optional(string)
      pfx_blob              = optional(string)
      password              = optional(string)
      host_names            = optional(list(string))
      tags                  = optional(map(string))
    })), {})

    # --- Custom domains ---
    custom_domains = optional(map(object({
      hostname        = string
      ssl_state       = optional(string)
      thumbprint      = optional(string)
      certificate_key = optional(string)
    })), {})

    # --- Storage shares to mount ---
    storage_shares_to_mount = optional(map(object({
      access_key   = string
      account_name = string
      mount_path   = string
      name         = string
      share_name   = string
      type         = optional(string, "AzureFiles")
    })), {})

    # --- Backup ---
    backup = optional(map(object({
      enabled             = optional(bool, true)
      name                = optional(string)
      storage_account_url = optional(string)
      schedule = optional(map(object({
        frequency_interval       = optional(number)
        frequency_unit           = optional(string)
        keep_at_least_one_backup = optional(bool)
        retention_period_days    = optional(number)
        start_time               = optional(string)
      })))
    })), {})

    # --- Logs ---
    logs = optional(map(object({
      application_logs = optional(map(object({
        azure_blob_storage = optional(object({
          level             = optional(string, "Off")
          retention_in_days = optional(number, 0)
          sas_url           = string
        }))
        file_system = optional(object({
          level = optional(string, "Off")
        }), {})
      })), {})
      detailed_error_messages = optional(bool, false)
      failed_requests_tracing = optional(bool, false)
      http_logs = optional(map(object({
        azure_blob_storage = optional(object({
          retention_in_days = optional(number, 0)
          sas_url           = string
        }))
        file_system = optional(object({
          retention_in_days = optional(number, 0)
          retention_in_mb   = number
        }))
      })), {})
    })), {})

    # --- Diagnostic settings ---
    diagnostic_settings = optional(map(object({
      name = optional(string, null)
      logs = optional(set(object({
        category       = optional(string, null)
        category_group = optional(string, null)
        enabled        = optional(bool, true)
        retention_policy = optional(object({
          days    = optional(number, 0)
          enabled = optional(bool, false)
        }), {})
      })), [])
      metrics = optional(set(object({
        category = optional(string, null)
        enabled  = optional(bool, true)
        retention_policy = optional(object({
          days    = optional(number, 0)
          enabled = optional(bool, false)
        }), {})
      })), [])
      log_analytics_destination_type           = optional(string, "Dedicated")
      workspace_resource_id                    = optional(string, null)
      workspace_key                            = optional(string, null)
      use_default_log_analytics                = optional(bool, false)
      storage_account_resource_id              = optional(string, null)
      event_hub_authorization_rule_resource_id = optional(string, null)
      event_hub_name                           = optional(string, null)
      marketplace_partner_resource_id          = optional(string, null)
    })), {})

    # --- Role assignments (repo pattern: managed_identity_key / assign_to_caller) ---
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = optional(string)
      managed_identity_key                   = optional(string)
      assign_to_caller                       = optional(bool, false)
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})

    # --- Private endpoints ---
    private_endpoints = optional(map(object({
      name = optional(string, null)
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
      lock = optional(object({
        kind = string
        name = optional(string, null)
      }), null)
      tags                        = optional(map(string), null)
      vnet_key                    = optional(string)
      subnet_key                  = optional(string)
      subnet_resource_id          = optional(string)
      private_dns_zone_group_name = optional(string, "default")
      # Key-based reference: resolve private_dns_zone.keys to DNS zone resource IDs (pattern-managed), merged with resource_ids.
      private_dns_zone = optional(object({
        resource_ids = optional(set(string), [])
        keys         = optional(set(string), [])
      }), {})
      application_security_group_associations = optional(map(string), {})
      private_service_connection_name         = optional(string, null)
      network_interface_name                  = optional(string, null)
      location                                = optional(string, null)
      resource_group_name                     = optional(string, null)
      ip_configurations = optional(map(object({
        name               = string
        private_ip_address = string
        member_name        = optional(string, null)
      })), {})
    })), {})
    private_endpoints_inherit_lock          = optional(bool, true)
    private_endpoints_manage_dns_zone_group = optional(bool, true)

    # --- Auth settings (V1) ---
    auth_settings = optional(object({
      additional_login_parameters    = optional(map(string))
      allowed_external_redirect_urls = optional(list(string))
      default_provider               = optional(string)
      enabled                        = optional(bool, false)
      issuer                         = optional(string)
      runtime_version                = optional(string)
      token_refresh_extension_hours  = optional(number, 72)
      token_store_enabled            = optional(bool, false)
      unauthenticated_client_action  = optional(string)
      active_directory = optional(object({
        client_id                  = optional(string)
        allowed_audiences          = optional(list(string))
        client_secret              = optional(string)
        client_secret_setting_name = optional(string)
      }))
      facebook = optional(object({
        app_id                  = optional(string)
        app_secret              = optional(string)
        app_secret_setting_name = optional(string)
        oauth_scopes            = optional(list(string))
      }))
      github = optional(object({
        client_id                  = optional(string)
        client_secret              = optional(string)
        client_secret_setting_name = optional(string)
        oauth_scopes               = optional(list(string))
      }))
      google = optional(object({
        client_id                  = optional(string)
        client_secret              = optional(string)
        client_secret_setting_name = optional(string)
        oauth_scopes               = optional(list(string))
      }))
      microsoft = optional(object({
        client_id                  = optional(string)
        client_secret              = optional(string)
        client_secret_setting_name = optional(string)
        oauth_scopes               = optional(list(string))
      }))
      twitter = optional(object({
        consumer_key                 = optional(string)
        consumer_secret              = optional(string)
        consumer_secret_setting_name = optional(string)
      }))
    }))

    # --- Auth settings (V2) ---
    auth_settings_v2 = optional(object({
      auth_enabled                           = optional(bool, false)
      config_file_path                       = optional(string)
      excluded_paths                         = optional(list(string))
      forward_proxy_convention               = optional(string, "NoProxy")
      forward_proxy_custom_host_header_name  = optional(string)
      forward_proxy_custom_proto_header_name = optional(string)
      http_route_api_prefix                  = optional(string, "/.auth")
      redirect_to_provider                   = optional(string)
      require_authentication                 = optional(bool, false)
      require_https                          = optional(bool, true)
      runtime_version                        = optional(string, "~1")
      unauthenticated_client_action          = optional(string, "RedirectToLoginPage")
      identity_providers = optional(object({
        apple = optional(object({
          enabled = optional(bool)
          login = optional(object({
            scopes = optional(list(string))
          }))
          registration = optional(object({
            client_id                  = optional(string)
            client_secret_setting_name = optional(string)
          }))
        }))
        azure_active_directory = optional(object({
          enabled             = optional(bool)
          is_auto_provisioned = optional(bool)
          login = optional(object({
            disable_www_authenticate = optional(bool)
            login_parameters         = optional(list(string))
          }))
          registration = optional(object({
            client_id                                          = optional(string)
            client_secret_certificate_issuer                   = optional(string)
            client_secret_certificate_subject_alternative_name = optional(string)
            client_secret_certificate_thumbprint               = optional(string)
            client_secret_setting_name                         = optional(string)
            open_id_issuer                                     = optional(string)
          }))
          validation = optional(object({
            allowed_audiences = optional(list(string))
            default_authorization_policy = optional(object({
              allowed_applications = optional(list(string))
              allowed_principals = optional(object({
                groups     = optional(list(string))
                identities = optional(list(string))
              }))
            }))
            jwt_claim_checks = optional(object({
              allowed_client_applications = optional(list(string))
              allowed_groups              = optional(list(string))
            }))
          }))
        }))
        azure_static_web_apps = optional(object({
          enabled = optional(bool)
          registration = optional(object({
            client_id = optional(string)
          }))
        }))
        custom_open_id_connect_providers = optional(map(object({
          enabled = optional(bool)
          login = optional(object({
            name_claim_type = optional(string)
            scopes          = optional(list(string))
          }))
          registration = optional(object({
            client_id = optional(string)
            client_credential = optional(object({
              method                     = optional(string)
              client_secret_setting_name = optional(string)
            }))
            open_id_connect_configuration = optional(object({
              authorization_endpoint           = optional(string)
              certification_uri                = optional(string)
              issuer                           = optional(string)
              token_endpoint                   = optional(string)
              well_known_open_id_configuration = optional(string)
            }))
          }))
        })))
        facebook = optional(object({
          enabled           = optional(bool)
          graph_api_version = optional(string)
          login = optional(object({
            scopes = optional(list(string))
          }))
          registration = optional(object({
            app_id                  = optional(string)
            app_secret_setting_name = optional(string)
          }))
        }))
        github = optional(object({
          enabled = optional(bool)
          login = optional(object({
            scopes = optional(list(string))
          }))
          registration = optional(object({
            client_id                  = optional(string)
            client_secret_setting_name = optional(string)
          }))
        }))
        google = optional(object({
          enabled = optional(bool)
          login = optional(object({
            scopes = optional(list(string))
          }))
          registration = optional(object({
            client_id                  = optional(string)
            client_secret_setting_name = optional(string)
          }))
          validation = optional(object({
            allowed_audiences = optional(list(string))
          }))
        }))
        legacy_microsoft_account = optional(object({
          enabled = optional(bool)
          login = optional(object({
            scopes = optional(list(string))
          }))
          registration = optional(object({
            client_id                  = optional(string)
            client_secret_setting_name = optional(string)
          }))
          validation = optional(object({
            allowed_audiences = optional(list(string))
          }))
        }))
        twitter = optional(object({
          enabled = optional(bool)
          registration = optional(object({
            consumer_key                 = optional(string)
            consumer_secret_setting_name = optional(string)
          }))
        }))
      }))
      login = optional(object({
        allowed_external_redirect_urls = optional(list(string))
        cookie_expiration = optional(object({
          convention         = optional(string, "FixedTime")
          time_to_expiration = optional(string, "08:00:00")
        }))
        nonce = optional(object({
          nonce_expiration_interval = optional(string, "00:05:00")
          validate_nonce            = optional(bool, true)
        }))
        preserve_url_fragments_for_logins = optional(bool, false)
        routes = optional(object({
          logout_endpoint = optional(string)
        }))
        token_store = optional(object({
          azure_blob_storage = optional(object({
            sas_url_setting_name = optional(string)
          }))
          enabled = optional(bool, false)
          file_system = optional(object({
            directory = optional(string)
          }))
          token_refresh_extension_hours = optional(number, 72)
        }))
      }))
    }))

    # --- Site configuration ---
    site_config = optional(object({
      always_on             = optional(bool, true)
      api_definition_url    = optional(string)
      api_management_api_id = optional(string)
      app_command_line      = optional(string)
      app_scale_limit       = optional(number)
      auto_heal_enabled     = optional(bool)
      auto_heal_rules = optional(object({
        actions = optional(object({
          action_type = string
          custom_action = optional(object({
            exe        = string
            parameters = optional(string)
          }))
          min_process_execution_time = optional(string, "00:00:00")
        }))
        triggers = optional(object({
          private_bytes_in_kb = optional(number)
          requests = optional(object({
            count         = number
            time_interval = string
          }))
          slow_requests = optional(object({
            count         = number
            time_interval = string
            time_taken    = string
            path          = optional(string)
          }))
          slow_requests_with_path = optional(list(object({
            count         = number
            time_interval = string
            time_taken    = string
            path          = optional(string)
          })), [])
          status_codes = optional(list(object({
            count         = number
            time_interval = string
            status        = number
            path          = optional(string)
            sub_status    = optional(number)
            win32_status  = optional(number)
          })), [])
          status_codes_range = optional(list(object({
            count         = number
            time_interval = string
            status_codes  = string
            path          = optional(string)
          })), [])
        }))
      }))
      auto_swap_slot_name                           = optional(string)
      container_registry_managed_identity_client_id = optional(string)
      container_registry_use_managed_identity       = optional(bool)
      default_documents                             = optional(list(string))
      detailed_error_logging_enabled                = optional(bool)
      document_root                                 = optional(string)
      dotnet_framework_version                      = optional(string)
      elastic_instance_minimum                      = optional(number)
      elastic_web_app_scale_limit                   = optional(number)
      experiments = optional(object({
        ramp_up_rules = optional(list(object({
          action_host_name             = optional(string)
          change_decision_callback_url = optional(string)
          change_interval_in_minutes   = optional(number)
          change_step                  = optional(number)
          max_reroute_percentage       = optional(number)
          min_reroute_percentage       = optional(number)
          name                         = optional(string)
          reroute_percentage           = optional(number)
        })), [])
      }))
      ftps_state = optional(string, "FtpsOnly")
      handler_mappings = optional(list(object({
        arguments        = optional(string)
        extension        = optional(string)
        script_processor = optional(string)
      })))
      health_check_path             = optional(string)
      http2_enabled                 = optional(bool, false)
      http20_proxy_flag             = optional(number)
      http_logging_enabled          = optional(bool)
      ip_restriction_default_action = optional(string, "Allow")
      java_container                = optional(string)
      java_container_version        = optional(string)
      java_version                  = optional(string)
      limits = optional(object({
        max_disk_size_in_mb = optional(number)
        max_memory_in_mb    = optional(number)
        max_percentage_cpu  = optional(number)
      }))
      linux_fx_version          = optional(string)
      load_balancing_mode       = optional(string, "LeastRequests")
      local_mysql_enabled       = optional(bool, false)
      logs_directory_size_limit = optional(number)
      managed_pipeline_mode     = optional(string, "Integrated")
      metadata = optional(list(object({
        name  = string
        value = string
      })))
      min_tls_cipher_suite                   = optional(string)
      minimum_tls_version                    = optional(string, "1.3")
      node_version                           = optional(string)
      php_version                            = optional(string)
      powershell_version                     = optional(string)
      pre_warmed_instance_count              = optional(number)
      python_version                         = optional(string)
      remote_debugging_enabled               = optional(bool, false)
      remote_debugging_version               = optional(string)
      request_tracing_enabled                = optional(bool)
      request_tracing_expiration_time        = optional(string)
      runtime_scale_monitoring_enabled       = optional(bool)
      scm_ip_restriction_default_action      = optional(string, "Allow")
      scm_minimum_tls_version                = optional(string, "1.2")
      scm_type                               = optional(string, "None")
      scm_use_main_ip_restriction            = optional(bool, false)
      tracing_options                        = optional(string)
      use_32_bit_worker                      = optional(bool, false)
      vnet_private_ports_count               = optional(number)
      vnet_route_all_enabled                 = optional(bool, false)
      website_time_zone                      = optional(string)
      websockets_enabled                     = optional(bool, false)
      windows_fx_version                     = optional(string)
      worker_count                           = optional(number)
      application_insights_connection_string = optional(string)
      application_insights_key               = optional(string)
      cors = optional(object({
        allowed_origins     = optional(list(string))
        support_credentials = optional(bool, false)
      }))
      ip_restriction = optional(list(object({
        action                    = optional(string, "Allow")
        ip_address                = optional(string)
        name                      = optional(string)
        priority                  = optional(number, 65000)
        service_tag               = optional(string)
        virtual_network_subnet_id = optional(string)
        headers = optional(object({
          x_azure_fdid      = optional(list(string))
          x_fd_health_probe = optional(list(string))
          x_forwarded_for   = optional(list(string))
          x_forwarded_host  = optional(list(string))
        }))
      })), [])
      scm_ip_restriction = optional(list(object({
        action                    = optional(string, "Allow")
        ip_address                = optional(string)
        name                      = optional(string)
        priority                  = optional(number, 65000)
        service_tag               = optional(string)
        virtual_network_subnet_id = optional(string)
        headers = optional(object({
          x_azure_fdid      = optional(list(string))
          x_fd_health_probe = optional(list(string))
          x_forwarded_for   = optional(list(string))
          x_forwarded_host  = optional(list(string))
        }))
      })), [])
      application_stack = optional(object({
        docker = optional(object({
          docker_image_name   = optional(string)
          docker_registry_url = optional(string)
          docker_image_tag    = optional(string, "latest")
        }))
        dotnet = optional(object({
          dotnet_version              = optional(string)
          current_stack               = optional(string)
          use_custom_runtime          = optional(bool, false)
          use_dotnet_isolated_runtime = optional(bool, false)
        }))
        java = optional(object({
          java_version           = optional(string)
          java_container         = optional(string)
          java_container_version = optional(string)
        }))
        node = optional(object({
          node_version = optional(string)
        }))
        php = optional(object({
          php_version = optional(string)
        }))
        python = optional(object({
          python_version = optional(string)
        }))
        powershell = optional(object({
          powershell_version = optional(string)
        }))
      }))
      virtual_application = optional(list(object({
        physical_path   = optional(string, "site\\wwwroot")
        preload_enabled = optional(bool, false)
        virtual_path    = optional(string, "/")
        virtual_directory = optional(list(object({
          physical_path = optional(string)
          virtual_path  = optional(string)
        })), [])
      })), [])
    }), {})

    # --- Deployment slots ---
    deployment_slots = optional(map(object({
      name                                   = optional(string)
      auto_generated_domain_name_label_scope = optional(string)
      client_affinity_enabled                = optional(bool, false)
      client_affinity_partitioning_enabled   = optional(bool)
      client_affinity_proxy_enabled          = optional(bool)
      client_certificate_enabled             = optional(bool, false)
      client_certificate_exclusion_paths     = optional(string, null)
      client_certificate_mode                = optional(string, "Required")
      container_size                         = optional(number)
      dapr_config = optional(object({
        app_id                = optional(string)
        app_port              = optional(number)
        enable_api_logging    = optional(bool)
        enabled               = optional(bool)
        http_max_request_size = optional(number)
        http_read_buffer_size = optional(number)
        log_level             = optional(string)
      }))
      dns_configuration = optional(object({
        dns_alt_server            = optional(string)
        dns_max_cache_timeout     = optional(number)
        dns_retry_attempt_count   = optional(number)
        dns_retry_attempt_timeout = optional(number)
        dns_servers               = optional(list(string))
      }))
      enabled                                  = optional(bool, true)
      end_to_end_encryption_enabled            = optional(bool)
      ftp_publish_basic_authentication_enabled = optional(bool, false)
      hosting_environment_id                   = optional(string)
      host_names_disabled                      = optional(bool)
      https_only                               = optional(bool, true)
      hyper_v                                  = optional(bool)
      ip_mode                                  = optional(string)
      key_vault_reference_identity             = optional(string, null)
      managed_environment_id                   = optional(string)
      managed_identities = optional(object({
        system_assigned            = optional(bool, false)
        user_assigned_resource_ids = optional(set(string), [])
      }), {})
      public_network_access_enabled = optional(bool, false)
      redundancy_mode               = optional(string)
      resource_config = optional(object({
        cpu    = optional(number)
        memory = optional(string)
      }))
      scm_site_also_stopped                          = optional(bool)
      server_farm_id                                 = optional(string, null)
      ssh_enabled                                    = optional(bool)
      storage_account_required                       = optional(bool)
      tags                                           = optional(map(string))
      virtual_network_subnet_id                      = optional(string, null)
      vnet_route_all_traffic                         = optional(bool, false)
      vnet_application_traffic_enabled               = optional(bool, false)
      vnet_backup_restore_enabled                    = optional(bool, false)
      vnet_content_share_enabled                     = optional(bool, false)
      vnet_image_pull_enabled                        = optional(bool, false)
      webdeploy_publish_basic_authentication_enabled = optional(bool, false)
      workload_profile_name                          = optional(string)
      app_settings                                   = optional(map(string), {})
      app_settings_override                          = optional(map(string), {})
      site_config = optional(object({
        always_on             = optional(bool, true)
        api_definition_url    = optional(string)
        api_management_api_id = optional(string)
        app_command_line      = optional(string)
        app_scale_limit       = optional(number)
        auto_heal_enabled     = optional(bool)
        auto_heal_rules = optional(object({
          actions = optional(object({
            action_type = string
            custom_action = optional(object({
              exe        = string
              parameters = optional(string)
            }))
            min_process_execution_time = optional(string, "00:00:00")
          }))
          triggers = optional(object({
            private_bytes_in_kb = optional(number)
            requests = optional(object({
              count         = number
              time_interval = string
            }))
            slow_requests = optional(object({
              count         = number
              time_interval = string
              time_taken    = string
              path          = optional(string)
            }))
            slow_requests_with_path = optional(list(object({
              count         = number
              time_interval = string
              time_taken    = string
              path          = optional(string)
            })), [])
            status_codes = optional(list(object({
              count         = number
              time_interval = string
              status        = number
              path          = optional(string)
              sub_status    = optional(number)
              win32_status  = optional(number)
            })), [])
            status_codes_range = optional(list(object({
              count         = number
              time_interval = string
              status_codes  = string
              path          = optional(string)
            })), [])
          }))
        }))
        auto_swap_slot_name                           = optional(string)
        container_registry_managed_identity_client_id = optional(string)
        container_registry_use_managed_identity       = optional(bool)
        default_documents                             = optional(list(string))
        detailed_error_logging_enabled                = optional(bool)
        document_root                                 = optional(string)
        elastic_instance_minimum                      = optional(number)
        elastic_web_app_scale_limit                   = optional(number)
        ftps_state                                    = optional(string, "FtpsOnly")
        handler_mappings = optional(list(object({
          arguments        = optional(string)
          extension        = optional(string)
          script_processor = optional(string)
        })))
        health_check_path             = optional(string)
        http2_enabled                 = optional(bool, false)
        http_logging_enabled          = optional(bool)
        ip_restriction_default_action = optional(string, "Allow")
        limits = optional(object({
          max_disk_size_in_mb = optional(number)
          max_memory_in_mb    = optional(number)
          max_percentage_cpu  = optional(number)
        }))
        load_balancing_mode       = optional(string, "LeastRequests")
        logs_directory_size_limit = optional(number)
        managed_pipeline_mode     = optional(string, "Integrated")
        metadata = optional(list(object({
          name  = string
          value = string
        })))
        min_tls_cipher_suite                   = optional(string)
        minimum_tls_version                    = optional(string, "1.3")
        pre_warmed_instance_count              = optional(number)
        remote_debugging_enabled               = optional(bool, false)
        remote_debugging_version               = optional(string)
        request_tracing_enabled                = optional(bool)
        request_tracing_expiration_time        = optional(string)
        runtime_scale_monitoring_enabled       = optional(bool)
        scm_ip_restriction_default_action      = optional(string, "Allow")
        scm_minimum_tls_version                = optional(string, "1.2")
        scm_use_main_ip_restriction            = optional(bool, false)
        tracing_options                        = optional(string)
        use_32_bit_worker                      = optional(bool, false)
        vnet_private_ports_count               = optional(number)
        vnet_route_all_enabled                 = optional(bool, false)
        website_time_zone                      = optional(string)
        websockets_enabled                     = optional(bool, false)
        worker_count                           = optional(number)
        application_insights_connection_string = optional(string)
        application_insights_key               = optional(string)
        cors = optional(object({
          allowed_origins     = optional(list(string))
          support_credentials = optional(bool, false)
        }))
        ip_restriction = optional(list(object({
          action                    = optional(string, "Allow")
          ip_address                = optional(string)
          name                      = optional(string)
          priority                  = optional(number, 65000)
          service_tag               = optional(string)
          virtual_network_subnet_id = optional(string)
          headers = optional(object({
            x_azure_fdid      = optional(list(string))
            x_fd_health_probe = optional(list(string))
            x_forwarded_for   = optional(list(string))
            x_forwarded_host  = optional(list(string))
          }))
        })), [])
        scm_ip_restriction = optional(list(object({
          action                    = optional(string, "Allow")
          ip_address                = optional(string)
          name                      = optional(string)
          priority                  = optional(number, 65000)
          service_tag               = optional(string)
          virtual_network_subnet_id = optional(string)
          headers = optional(object({
            x_azure_fdid      = optional(list(string))
            x_fd_health_probe = optional(list(string))
            x_forwarded_for   = optional(list(string))
            x_forwarded_host  = optional(list(string))
          }))
        })), [])
        application_stack = optional(object({
          docker = optional(object({
            docker_image_name   = optional(string)
            docker_registry_url = optional(string)
            docker_image_tag    = optional(string, "latest")
          }))
          dotnet = optional(object({
            dotnet_version              = optional(string)
            current_stack               = optional(string)
            use_custom_runtime          = optional(bool, false)
            use_dotnet_isolated_runtime = optional(bool, false)
          }))
          java = optional(object({
            java_version           = optional(string)
            java_container         = optional(string)
            java_container_version = optional(string)
          }))
          node = optional(object({
            node_version = optional(string)
          }))
          php = optional(object({
            php_version = optional(string)
          }))
          python = optional(object({
            python_version = optional(string)
          }))
          powershell = optional(object({
            powershell_version = optional(string)
          }))
        }))
      }), {})
      lock = optional(object({
        kind = string
        name = optional(string, null)
      }), null)
      private_endpoints = optional(map(object({
        name = optional(string, null)
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
        lock = optional(object({
          kind = string
          name = optional(string, null)
        }), null)
        tags                                    = optional(map(string), null)
        subnet_resource_id                      = string
        private_dns_zone_group_name             = optional(string, "default")
        private_dns_zone_resource_ids           = optional(set(string), [])
        application_security_group_associations = optional(map(string), {})
        private_service_connection_name         = optional(string, null)
        network_interface_name                  = optional(string, null)
        location                                = optional(string, null)
        resource_group_name                     = optional(string, null)
        ip_configurations = optional(map(object({
          name               = string
          private_ip_address = string
          member_name        = optional(string, null)
        })), {})
      })), {})
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
      storage_shares_to_mount = optional(map(object({
        account_name = string
        mount_path   = string
        name         = string
        share_name   = string
        type         = optional(string, "AzureFiles")
      })), {})
      connection_strings = optional(map(object({
        name  = optional(string)
        type  = optional(string)
        value = optional(string)
      })), {})
      zip_deploy_file          = optional(string)
      zip_deploy_wait_duration = optional(string, "60s")
      custom_domains = optional(map(object({
        hostname        = string
        ssl_state       = optional(string)
        thumbprint      = optional(string)
        certificate_key = optional(string)
      })), {})
    })), {})
    deployment_slots_inherit_lock = optional(bool, true)

    # --- Sensitive slot values ---
    slot_sensitive_app_settings                    = optional(map(map(string)), {})
    slots_storage_shares_to_mount_sensitive_values = optional(map(string), {})
  }))
  default     = {}
  description = <<-EOT
    A map of Azure App Services (Web Apps, Function Apps, and Logic Apps) to create by wrapping the `Azure/avm-res-web-site/azurerm` module.
    The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.

    - `name` - (Required) The name of the App Service. Changing this forces a new resource to be created.
    - `resource_group_key` - (Optional) **Pattern cross-reference**: the key of a resource group in the `resource_groups` variable. Resolved to the resource group `resource_id` (passed to the AVM module as `parent_id`). At least one of `resource_group_key` or `resource_group_name` must be provided.
    - `resource_group_name` - (Optional) The name of the resource group. When set, the resource group ID is constructed from the current subscription and this name, overriding `resource_group_key`.
    - `location` - (Optional) The Azure region. Defaults to `var.location`.
    - `tags` - (Optional) A mapping of tags merged with `var.tags`. Defaults to `{}`.

    - `kind` - (Optional) The type of App Service. Possible values are `functionapp`, `webapp`, and `logicapp`. Defaults to `webapp`.
    - `os_type` - (Optional) The operating system type. `Linux` sets `reserved = true` on the ARM resource. Defaults to `Linux`.
    - `service_plan_resource_id` - (Optional) The resource ID of the App Service Plan. Provide this directly or via `service_plan_key`. One of the two is required.
    - `service_plan_key` - (Optional) **Pattern cross-reference**: the key of an App Service Plan in the `service_plans` variable. Resolved to its `resource_id` when `service_plan_resource_id` is not set.
    - `enabled` - (Optional) Is the App Service enabled? Defaults to `true`.
    - `https_only` - (Optional) Should the App Service only be accessible over HTTPS? Defaults to `true`.

    - `managed_identities` - (Optional) Managed identity configuration. Defaults to `{}`.
      - `system_assigned` - (Optional) Whether to enable system-assigned managed identity. Defaults to `false`.
      - `user_assigned_resource_ids` - (Optional) A set of user-assigned managed identity resource IDs to assign directly. Defaults to `[]`.
      - `user_assigned_keys` - (Optional) **Pattern cross-reference**: a set of keys from the `managed_identities` variable. Resolved to UAMI resource IDs and merged with `user_assigned_resource_ids`. Defaults to `[]`.

    - `client_certificate_enabled` - (Optional) Should client certificates be required? Defaults to `false`.
    - `client_certificate_mode` - (Optional) The client certificate mode. Possible values are `Required`, `Optional` and `OptionalInteractiveUser`. Defaults to `Required`.
    - `client_certificate_exclusion_paths` - (Optional) Comma-separated list of paths to exclude from client certificate authentication.
    - `client_affinity_enabled` - (Optional) Should client affinity be enabled? Defaults to `false`.
    - `client_affinity_partitioning_enabled` - (Optional) Should client affinity partitioning be enabled?
    - `client_affinity_proxy_enabled` - (Optional) Should client affinity proxy be enabled?

    - `public_network_access_enabled` - (Optional) Should public network access be enabled? Defaults to `false`.
    - `network_configuration` - (Optional) VNet integration target, resolved to the wrapped module's `virtual_network_subnet_id`. Provide either the key-based references or a direct `subnet_resource_id`.
      - `vnet_key` - (Optional) **Pattern cross-reference**: the key of a virtual network in the `virtual_networks` variable.
      - `subnet_key` - (Optional) **Pattern cross-reference**: the key of a subnet within the VNet identified by `vnet_key`.
      - `subnet_resource_id` - (Optional) The subnet resource ID, used directly. Fallback when `vnet_key`/`subnet_key` are not provided.
    - `virtual_network_backup_restore_enabled` - (Optional) Should VNet backup/restore be enabled? Defaults to `false`.
    - `vnet_application_traffic_enabled` - (Optional) Should application traffic route through the VNet? Defaults to `false`.
    - `vnet_content_share_enabled` - (Optional) Should content share traffic route through the VNet? Defaults to `false`.
    - `vnet_image_pull_enabled` - (Optional) Should image pulls route through the VNet? Defaults to `false`.
    - `vnet_route_all_traffic` - (Optional) Should all outbound traffic route through the VNet? Defaults to `false`.
    - `host_names_disabled` - (Optional) Should the default hostnames be disabled?
    - `ip_mode` - (Optional) The IP mode. Possible values are `IPv4`, `IPv4AndIPv6` and `IPv6`.
    - `hosting_environment_id` - (Optional) The App Service Environment resource ID.
    - `managed_environment_id` - (Optional) The Container Apps managed environment resource ID.
    - `workload_profile_name` - (Optional) The workload profile name.

    - `app_settings` - (Optional) A map of application settings (key/value strings).
    - `app_settings_override` - (Optional) A map of app settings applied AFTER the AVM module via its `config_appsettings` submodule (an `azapi_update_resource` merge). Use this for keys that the AVM module's locals preset and thus override from `app_settings` — e.g. `WEBSITE_NODE_DEFAULT_VERSION`, `FUNCTIONS_WORKER_RUNTIME`. Only the listed keys are changed; all other computed settings are preserved. Note: keys overridden here that the AVM module also manages will show a perpetual diff on the main module (the override re-asserts last on each apply).
    - `connection_strings` - (Optional) A map of connection strings.
      - `name` - (Optional) The name of the connection string.
      - `type` - (Optional) The connection string type.
      - `value` - (Optional) The connection string value.
    - `sticky_settings` - (Optional) Settings that stay with a slot during swaps.
      - `app_setting_names` - (Optional) A list of app setting names to make sticky.
      - `connection_string_names` - (Optional) A list of connection string names to make sticky.

    - `application_insights_connection_string` - (Optional) The Application Insights connection string. Takes precedence over `application_insights.key`.
    - `application_insights_instrumentation_key` - (Optional) The Application Insights instrumentation key. Takes precedence over `application_insights.key`.
    - `application_insights` - (Optional) Key-based reference to an Application Insights component used to resolve the connection string and instrumentation key (for both the top-level fields and `site_config`) when the direct values are not supplied.
      - `key` - (Optional) **Pattern cross-reference**: the key of an Application Insights component in the `application_insights` variable, resolved to its `connection_string` and `instrumentation_key`.
    - `application_insights_uses_managed_identity` - (Optional) When `true`, the Application Insights instrumentation key is not set and `APPLICATIONINSIGHTS_AUTHENTICATION_STRING = "ClientId=<client_id>;Authorization=AAD"` is injected directly into app settings (top-level and each slot), enabling Microsoft Entra (AAD) auth to Application Insights. Defaults to `false`.
    - `application_insights_user_assigned_identity_client_id` - (Optional) The client ID of the user-assigned identity used for Application Insights AAD auth. Takes precedence over `application_insights_user_assigned_identity_key`.
    - `application_insights_user_assigned_identity_key` - (Optional) **Pattern cross-reference**: the key of a managed identity in the `managed_identities` variable, resolved to its `client_id`. Used when `application_insights_user_assigned_identity_client_id` is not set.

    - `auto_generated_domain_name_label_scope` - (Optional) The domain name label scope. Possible values are `NoReuse`, `ResourceGroupReuse`, `SubscriptionReuse` and `TenantReuse`.
    - `end_to_end_encryption_enabled` - (Optional) Should end-to-end encryption be enabled?
    - `hyper_v` - (Optional) Should Hyper-V (Windows Container) be used?
    - `redundancy_mode` - (Optional) The redundancy mode. Possible values are `ActiveActive`, `Failover`, `GeoRedundant`, `Manual` and `None`.
    - `scm_site_also_stopped` - (Optional) Should the SCM site be stopped when the app is stopped?
    - `ssh_enabled` - (Optional) Should SSH be enabled?
    - `all_child_resources_inherit_tags` - (Optional) Should all child resources inherit the app's tags? Defaults to `true`.

    - `ftp_publish_basic_authentication_enabled` - (Optional) Should FTP basic authentication publishing be enabled? Defaults to `false`.
    - `scm_publish_basic_authentication_enabled` - (Optional) Should SCM basic authentication publishing be enabled? Defaults to `true`.

    - `functions_extension_version` - (Optional) The Functions runtime version (e.g. `~4`). Defaults to `~4`.
    - `function_app_uses_fc1` - (Optional) Does the Function App use the Flex Consumption (FC1) plan? Defaults to `false`.
    - `builtin_logging_enabled` - (Optional) Should built-in logging be enabled? Defaults to `true`.
    - `content_share_force_disabled` - (Optional) Should the content share be force-disabled? Defaults to `false`.
    - `daily_memory_time_quota` - (Optional) The daily memory-time quota (GB-seconds). Defaults to `0`.
    - `container_size` - (Optional) The container size for the Function App.
    - `instance_memory_in_mb` - (Optional) The instance memory in MB. Defaults to `2048`.
    - `maximum_instance_count` - (Optional) The maximum instance count.
    - `key_vault_reference_identity` - (Optional) The identity ID used to resolve Key Vault references. Takes precedence over `key_vault_reference_identity_key`.
    - `key_vault_reference_identity_key` - (Optional) **Pattern cross-reference**: the key of a managed identity in the `managed_identities` variable, resolved to its UAMI resource ID. Used when `key_vault_reference_identity` is not set.
    - `storage_account_name` - (Optional) The backing storage account name. Takes precedence over `storage_account_key`.
    - `storage_account_key` - (Optional) **Pattern cross-reference**: the key of a storage account in the `storage_accounts` variable, resolved to its name. Used when `storage_account_name` is not set.
    - `storage_account_access_key` - (Optional) The backing storage account access key.
    - `storage_account_required` - (Optional) Is a storage account required?
    - `storage_account_share_name` - (Optional) The storage account file share name.
    - `storage_authentication_type` - (Optional) The storage authentication type. Possible values are `StorageAccountConnectionString`, `SystemAssignedIdentity` and `UserAssignedIdentity`.
    - `storage_container_type` - (Optional) The storage container type.
    - `storage_container_endpoint` - (Optional) The storage container endpoint.
    - `storage_user_assigned_identity_id` - (Optional) The user-assigned identity ID used for storage access. Takes precedence over `storage_user_assigned_identity_key`.
    - `storage_user_assigned_identity_key` - (Optional) **Pattern cross-reference**: the key of a managed identity in the `managed_identities` variable, resolved to its UAMI resource ID. Used when `storage_user_assigned_identity_id` is not set.
    - `storage_uses_managed_identity` - (Optional) Should the storage account use a managed identity? Defaults to `false`.
    - `fc1_runtime_name` - (Optional) The Flex Consumption runtime name.
    - `fc1_runtime_version` - (Optional) The Flex Consumption runtime version.
    - `always_ready` - (Optional) A map of always-ready instance configurations.
      - `name` - (Optional) The name of the always-ready group.
      - `instance_count` - (Optional) The number of always-ready instances. Defaults to `0`.

    - `bundle_version` - (Optional) The Logic App extension bundle version. Defaults to `[1.*, 2.0.0)`.
    - `use_extension_bundle` - (Optional) Should the extension bundle be used? Defaults to `true`.
    - `logic_app_runtime_version` - (Optional) The Logic App runtime version. Defaults to `~4`.

    - `dapr_config` - (Optional) Dapr configuration (Container Apps hosted).
      - `app_id` - (Optional) The Dapr application ID.
      - `app_port` - (Optional) The Dapr application port.
      - `enable_api_logging` - (Optional) Should Dapr API logging be enabled?
      - `enabled` - (Optional) Should Dapr be enabled?
      - `http_max_request_size` - (Optional) The maximum HTTP request size.
      - `http_read_buffer_size` - (Optional) The HTTP read buffer size.
      - `log_level` - (Optional) The Dapr log level.
    - `resource_config` - (Optional) The container resource configuration.
      - `cpu` - (Optional) The CPU allocation.
      - `memory` - (Optional) The memory allocation.

    - `dns_configuration` - (Optional) DNS configuration for the app.
      - `dns_alt_server` - (Optional) The alternate DNS server.
      - `dns_max_cache_timeout` - (Optional) The maximum DNS cache timeout.
      - `dns_retry_attempt_count` - (Optional) The DNS retry attempt count.
      - `dns_retry_attempt_timeout` - (Optional) The DNS retry attempt timeout.
      - `dns_servers` - (Optional) A list of custom DNS servers.

    - `lock` - (Optional) Controls the Resource Lock configuration for this resource.
      - `kind` - (Required) The type of lock. Possible values are `CanNotDelete` and `ReadOnly`.
      - `name` - (Optional) The name of the lock.
    - `timeouts` - (Optional) The timeout configuration for the resource.
      - `create` - (Optional) The timeout for create operations.
      - `delete` - (Optional) The timeout for delete operations.
      - `read` - (Optional) The timeout for read operations.
      - `update` - (Optional) The timeout for update operations.
    - `retry` - (Optional) The retry configuration.
      - `error_message_regex` - (Required) A list of regular expressions to match against error messages for retry.
      - `interval_seconds` - (Optional) The base number of seconds to wait between retries. Defaults to `10`.
      - `max_retries` - (Optional) The maximum number of retries. Defaults to `3`.

    - `zip_deploy_file` - (Optional) The path to a zip file to deploy.
    - `zip_deploy_wait_duration` - (Optional) The duration to wait after a zip deploy. Defaults to `60s`.

    - `app_service_active_slot` - (Optional) The active deployment slot configuration.
      - `slot_key` - (Optional) The key of the deployment slot to make active.
      - `overwrite_network_config` - (Optional) Should the network configuration be overwritten on swap? Defaults to `true`.

    - `certificates` - (Optional) A map of `Microsoft.Web/certificates` to create. Either Key Vault sourced or `pfx_blob` inline upload.
      - `name` - (Optional) The name of the certificate.
      - `key_vault_id` - (Optional) The Key Vault resource ID. Takes precedence over `key_vault_key`.
      - `key_vault_key` - (Optional) **Pattern cross-reference**: the key of a Key Vault in the `key_vaults` variable, resolved to its resource ID. Used when `key_vault_id` is not set.
      - `key_vault_secret_name` - (Optional) The Key Vault secret name.
      - `pfx_blob` - (Optional) The base64-encoded PFX blob for inline upload.
      - `password` - (Optional) The PFX password.
      - `host_names` - (Optional) A list of host names for the certificate.
      - `tags` - (Optional) A mapping of tags for the certificate.

    - `custom_domains` - (Optional) A map of custom domain bindings. The module only creates the hostname binding; DNS records must exist beforehand.
      - `hostname` - (Required) The hostname to bind.
      - `ssl_state` - (Optional) The SSL state.
      - `thumbprint` - (Optional) The certificate thumbprint.
      - `certificate_key` - (Optional) The key of a certificate in `certificates`.

    - `storage_shares_to_mount` - (Optional) A map of storage shares to mount.
      - `access_key` - (Required) The storage account access key.
      - `account_name` - (Required) The storage account name.
      - `mount_path` - (Required) The mount path.
      - `name` - (Required) The name of the mount.
      - `share_name` - (Required) The file share name.
      - `type` - (Optional) The mount type. Defaults to `AzureFiles`.

    - `backup` - (Optional) A map of backup configurations.
      - `enabled` - (Optional) Is the backup enabled? Defaults to `true`.
      - `name` - (Optional) The name of the backup.
      - `storage_account_url` - (Optional) The SAS URL of the storage account for backups.
      - `schedule` - (Optional) The backup schedule.
        - `frequency_interval` - (Optional) How often the backup runs (in `frequency_unit`).
        - `frequency_unit` - (Optional) The frequency unit (`Day` or `Hour`).
        - `keep_at_least_one_backup` - (Optional) Should at least one backup always be retained?
        - `retention_period_days` - (Optional) The backup retention period in days.
        - `start_time` - (Optional) When the schedule should start.

    - `logs` - (Optional) A map of logging configurations (`application_logs`, `detailed_error_messages`, `failed_requests_tracing`, `http_logs`). See the `Azure/avm-res-web-site/azurerm` documentation for the full nested shape.

    - `diagnostic_settings` - (Optional) A map of diagnostic settings to create on this resource.
      - `name` - (Optional) The name of the diagnostic setting. One will be generated if not set.
      - `logs` - (Optional) A set of log categories/category groups to send (`category`, `category_group`, `enabled`, `retention_policy`).
      - `metrics` - (Optional) A set of metric categories to send (`category`, `enabled`, `retention_policy`).
      - `log_analytics_destination_type` - (Optional) The destination type. Possible values are `Dedicated` and `AzureDiagnostics`.
      - `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
      - `workspace_key` - (Optional) **Pattern cross-reference**: the key of a Log Analytics workspace in the `log_analytics_workspaces` variable, resolved to its resource ID. Used when `workspace_resource_id` is not set.
      - `use_default_log_analytics` - (Optional) When `true` (and neither `workspace_resource_id` nor `workspace_key` is set), uses the first workspace in the `log_analytics_workspaces` variable. Defaults to `false`. A workspace is not required — storage account, event hub, or marketplace destinations are also valid.
      - `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
      - `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
      - `event_hub_name` - (Optional) The name of the event hub.
      - `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic Logs.

    - `role_assignments` - (Optional) A map of role assignments to create on this resource.
      - `role_definition_id_or_name` - (Required) The ID or name of the role definition to assign to the principal.
      - `principal_id` - (Optional) The ID of the principal to assign the role to. Mutually exclusive with `managed_identity_key` and `assign_to_caller`.
      - `managed_identity_key` - (Optional) **Pattern cross-reference**: the key of a managed identity in the `managed_identities` variable, resolved to its principal ID. Sets `principal_type` to `ServicePrincipal`. Mutually exclusive with `principal_id` and `assign_to_caller`.
      - `assign_to_caller` - (Optional) When `true`, uses the object ID of the identity running Terraform as the principal. Mutually exclusive with `principal_id` and `managed_identity_key`. Defaults to `false`.
      - `description` - (Optional) The description of the role assignment.
      - `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to `false`.
      - `condition` - (Optional) The condition which will be used to scope the role assignment.
      - `condition_version` - (Optional) The version of the condition syntax.
      - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. This field is only used in cross-tenant scenario.
      - `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`.

    - `private_endpoints` - (Optional) A map of private endpoints to create on this resource.
      - `name` - (Optional) The name of the private endpoint.
      - `role_assignments` - (Optional) Role assignments to create on the private endpoint (same shape as the top-level `role_assignments`).
      - `lock` - (Optional) The lock configuration for the private endpoint.
      - `tags` - (Optional) A mapping of tags for the private endpoint.
      - `vnet_key` - (Optional) **Pattern cross-reference**: the key of a virtual network in the `virtual_networks` variable.
      - `subnet_key` - (Optional) **Pattern cross-reference**: the key of a subnet within the VNet identified by `vnet_key`.
      - `subnet_resource_id` - (Optional) The resource ID of the subnet for the private endpoint, used directly. Fallback when `vnet_key`/`subnet_key` are not provided.
      - `private_dns_zone_group_name` - (Optional) The name of the private DNS zone group. Defaults to `default`.
      - `private_dns_zone` - (Optional) Private DNS zones to associate with the endpoint, resolved to the wrapped module's `private_dns_zone_resource_ids`.
        - `resource_ids` - (Optional) A set of private DNS zone resource IDs, used directly.
        - `keys` - (Optional) **Pattern cross-reference**: a set of keys from the `private_dns_zones` variable, each resolved to a DNS zone resource ID and merged with `resource_ids`.
      - `application_security_group_associations` - (Optional) A map of application security group associations.
      - `private_service_connection_name` - (Optional) The name of the private service connection.
      - `network_interface_name` - (Optional) The name of the network interface.
      - `location` - (Optional) The location of the private endpoint.
      - `resource_group_name` - (Optional) The resource group of the private endpoint.
      - `ip_configurations` - (Optional) A map of IP configurations for the private endpoint.
    - `private_endpoints_inherit_lock` - (Optional) Should private endpoints inherit the resource lock? Defaults to `true`.
    - `private_endpoints_manage_dns_zone_group` - (Optional) Should the module manage the private DNS zone group? Defaults to `true`.

    - `auth_settings` - (Optional) The V1 authentication settings. See the `Azure/avm-res-web-site/azurerm` documentation for the full nested provider shapes.
    - `auth_settings_v2` - (Optional) The V2 authentication settings. See the `Azure/avm-res-web-site/azurerm` documentation for the full nested provider shapes.

    - `site_config` - (Optional) The site configuration, exposing the full ARM `siteConfig` surface (application stack, IP restrictions, CORS, auto-heal, TLS, logging, etc.). See the `Azure/avm-res-web-site/azurerm` documentation for the full nested shape.

    - `deployment_slots` - (Optional) A map of deployment slots. Each slot mirrors the App Service surface, including its own `site_config`, `managed_identities`, `private_endpoints`, `role_assignments`, `custom_domains`, etc. See the `Azure/avm-res-web-site/azurerm` documentation for the full nested shape.
      - `app_settings_override` - (Optional) Per-slot equivalent of the top-level `app_settings_override`. Applied AFTER the AVM module via the `config_appsettings` submodule (`is_slot = true`) to override AVM-preset slot app settings.
      - Application Insights managed-identity auth is inherited from the top-level `application_insights_uses_managed_identity` / `application_insights_user_assigned_identity_client_id` / `application_insights_user_assigned_identity_key` settings (there is no per-slot override): when enabled, each slot's instrumentation key is nulled and `APPLICATIONINSIGHTS_AUTHENTICATION_STRING` is injected into the slot's app settings.
    - `deployment_slots_inherit_lock` - (Optional) Should deployment slots inherit the resource lock? Defaults to `true`.

    - `slot_sensitive_app_settings` - (Optional) A map of slot key to sensitive app settings.
    - `slots_storage_shares_to_mount_sensitive_values` - (Optional) A map of storage share access keys for slots.

    > **Downstream references:** Other modules may reference this resource via the map key:
    > - `web_sites.<site_key>` → key from this map (exposed in the module output).

    > **Pattern note:** If `location` is not specified, defaults to `var.location`. Tags in `tags` are merged with `var.tags`. Every field maps directly to the corresponding `Azure/avm-res-web-site/azurerm` input.
  EOT
}

variable "location" {
  description = "Default location fallback when an App Service does not set location."
  type        = string
}

variable "resource_groups" {
  description = "Resource groups output map from spoke module. Used to resolve resource_group_key to the resource group resource_id (passed as parent_id)."
  type        = any
  default     = {}
}

variable "managed_identities" {
  description = "Managed identities output map from spoke module. Used to resolve user_assigned_keys to UAMI resource IDs, role_assignments.managed_identity_key to a principal ID, and key_vault_reference_identity_key / storage_user_assigned_identity_key to UAMI resource IDs."
  type        = any
  default     = {}
}

variable "virtual_networks" {
  description = "Virtual networks output map from spoke module. Used to resolve network_configuration.vnet_key/subnet_key and private_endpoints[*].vnet_key/subnet_key to a subnet resource ID."
  type        = any
  default     = {}
}

variable "log_analytics_workspaces" {
  description = "Log Analytics workspaces output map from the spoke module. Used to resolve a diagnostic setting's workspace_key to a workspace resource ID. When a diagnostic setting sets use_default_log_analytics = true (and no workspace_resource_id/workspace_key), the first workspace in this map is used."
  type        = any
  default     = {}
}

variable "service_plans" {
  description = "App Service Plans output map. Used to resolve service_plan_key to an App Service Plan resource_id."
  type        = any
  default     = {}
}

variable "application_insights" {
  description = "Application Insights output map (e.g. from the application_insights module). Used to resolve application_insights.key to a component connection string and instrumentation key."
  type        = any
  default     = {}
}

variable "key_vaults" {
  description = "Key Vaults output map from the spoke module. Used to resolve certificates[*].key_vault_key to a Key Vault resource ID."
  type        = any
  default     = {}
}

variable "storage_accounts" {
  description = "Storage accounts output map from the spoke module. Used to resolve storage_account_key to a storage account name."
  type        = any
  default     = {}
}

variable "private_dns_zones" {
  description = "Map of private DNS zone keys to their resource IDs (e.g. the spoke module's combined_private_dns_zones_resource_ids output). Used to resolve private_endpoints[*].private_dns_zone.keys to DNS zone resource IDs."
  type        = any
  default     = {}
}

variable "tags" {
  description = "Default tags to merge with per-resource tags."
  type        = map(string)
  default     = {}
}

variable "enable_telemetry" {
  description = "Controls whether telemetry is enabled for the wrapped AVM module. See <https://aka.ms/avm/telemetryinfo>."
  type        = bool
  default     = true
}
