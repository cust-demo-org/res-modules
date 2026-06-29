variable "cosmos_db" {
  type = map(object({
    name = string
    name_random_suffix_configuration = optional(object({
      length             = number
      append_with_hyphen = optional(bool, true)
    }))
    resource_group_key  = optional(string)
    resource_group_name = optional(string)
    location            = optional(string)
    tags                = optional(map(string), {})

    # ---- Account behaviour ----------------------------------------------------
    access_key_metadata_writes_enabled    = optional(bool, false)
    analytical_storage_enabled            = optional(bool, false)
    automatic_failover_enabled            = optional(bool, true)
    free_tier_enabled                     = optional(bool, false)
    local_authentication_disabled         = optional(bool, true)
    minimal_tls_version                   = optional(string, "Tls12")
    mongo_server_version                  = optional(string, "3.6")
    multiple_write_locations_enabled      = optional(bool, false)
    partition_merge_enabled               = optional(bool, false)
    public_network_access_enabled         = optional(bool, false)
    network_acl_bypass_for_azure_services = optional(bool, false)
    network_acl_bypass_resource_ids       = optional(set(string), [])
    ip_range_filter                       = optional(set(string), [])

    consistency_policy = optional(object({
      consistency_level       = optional(string, "BoundedStaleness")
      max_interval_in_seconds = optional(number, 5)
      max_staleness_prefix    = optional(number, 100)
    }), {})

    analytical_storage_config = optional(object({
      schema_type = string
    }))

    capacity = optional(object({
      total_throughput_limit = optional(number, -1)
    }), {})

    backup = optional(object({
      type                = optional(string, "Continuous")
      tier                = optional(string, "Continuous30Days")
      interval_in_minutes = optional(number, 240)
      retention_in_hours  = optional(number, 8)
      storage_redundancy  = optional(string, "Geo")
    }), {})

    cors_rule = optional(object({
      allowed_headers    = set(string)
      allowed_methods    = set(string)
      allowed_origins    = set(string)
      exposed_headers    = set(string)
      max_age_in_seconds = optional(number, null)
    }))

    geo_locations = optional(set(object({
      location          = optional(string)
      failover_priority = number
      zone_redundant    = optional(bool, true)
    })))

    capabilities = optional(set(object({
      name = string
    })), [])

    virtual_network_rules = optional(set(object({
      subnet_id  = optional(string)
      vnet_key   = optional(string)
      subnet_key = optional(string)
    })), [])

    sql_dedicated_gateway = optional(object({
      instance_size  = string
      instance_count = optional(number, 1)
    }))

    # ---- Encryption & identity ------------------------------------------------
    customer_managed_key = optional(object({
      key_name              = optional(string)
      key_key               = optional(string)
      key_vault_resource_id = optional(string)
      key_vault_key         = optional(string)
      key_version           = optional(string, null)
      user_assigned_identity = optional(object({
        resource_id = optional(string)
        key         = optional(string)
      }), null)
    }))

    managed_identities = optional(object({
      system_assigned            = optional(bool, false)
      user_assigned_resource_ids = optional(set(string), [])
      user_assigned_keys         = optional(set(string), [])
    }), {})

    lock = optional(object({
      kind = string
      name = optional(string, null)
    }))

    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = optional(string)
      managed_identity_key                   = optional(string)
      assign_to_caller                       = optional(bool, false)
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
    })), {})

    diagnostic_settings = optional(map(object({
      name                                     = optional(string, null)
      log_categories                           = optional(set(string), [])
      log_groups                               = optional(set(string), ["allLogs"])
      metric_categories                        = optional(set(string), ["AllMetrics"])
      log_analytics_destination_type           = optional(string, "Dedicated")
      workspace_resource_id                    = optional(string, null)
      workspace_key                            = optional(string, null)
      use_default_log_analytics                = optional(bool, false)
      storage_account_resource_id              = optional(string, null)
      event_hub_authorization_rule_resource_id = optional(string, null)
      event_hub_name                           = optional(string, null)
      marketplace_partner_resource_id          = optional(string, null)
    })), {})

    # ---- Private networking ---------------------------------------------------
    private_endpoints_manage_dns_zone_group = optional(bool, true)

    private_endpoints = optional(map(object({
      subnet_resource_id          = optional(string)
      vnet_key                    = optional(string)
      subnet_key                  = optional(string)
      subresource_name            = string
      name                        = optional(string, null)
      private_dns_zone_group_name = optional(string, "default")
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
      })), {})

      tags = optional(map(string), null)

      lock = optional(object({
        kind = string
        name = optional(string, null)
      }), null)

      role_assignments = optional(map(object({
        role_definition_id_or_name             = string
        principal_id                           = string
        description                            = optional(string, null)
        skip_service_principal_aad_check       = optional(bool, false)
        delegated_managed_identity_resource_id = optional(string, null)
        principal_type                         = optional(string, null)
        condition                              = optional(string, null)
        condition_version                      = optional(string, null)
      })), {})
    })), {})

    # ---- Data plane: SQL ------------------------------------------------------
    sql_databases = optional(map(object({
      name       = string
      throughput = optional(number, null)
      autoscale_settings = optional(object({
        max_throughput = number
      }), null)

      containers = optional(map(object({
        partition_key_paths    = list(string)
        name                   = string
        partition_key_version  = optional(number, 2)
        throughput             = optional(number, null)
        default_ttl            = optional(number, null)
        analytical_storage_ttl = optional(number, null)

        unique_keys = optional(list(object({
          paths = set(string)
        })), [])

        autoscale_settings = optional(object({
          max_throughput = number
        }), null)

        functions = optional(map(object({
          body = string
          name = string
        })), {})

        stored_procedures = optional(map(object({
          body = string
          name = string
        })), {})

        triggers = optional(map(object({
          body      = string
          type      = string
          operation = string
          name      = string
        })), {})

        conflict_resolution_policy = optional(object({
          mode                          = string
          conflict_resolution_path      = optional(string, null)
          conflict_resolution_procedure = optional(string, null)
        }), null)

        indexing_policy = optional(object({
          indexing_mode = string
          included_paths = optional(set(object({
            path = string
          })), [])
          excluded_paths = optional(set(object({
            path = string
          })), [])
          composite_indexes = optional(set(object({
            indexes = set(object({
              path  = string
              order = string
            }))
          })), [])
          spatial_indexes = optional(set(object({
            path = string
          })), [])
        }), null)
      })), {})
    })), {})

    # ---- Data plane: MongoDB --------------------------------------------------
    mongo_databases = optional(map(object({
      name       = string
      throughput = optional(number, null)
      autoscale_settings = optional(object({
        max_throughput = number
      }), null)

      collections = optional(map(object({
        name                = string
        default_ttl_seconds = optional(string, null)
        shard_key           = optional(string, null)
        throughput          = optional(number, null)
        autoscale_settings = optional(object({
          max_throughput = number
        }), null)
        index = optional(object({
          keys   = list(string)
          unique = optional(bool, false)
        }), null)
      })), {})
    })), {})

    # ---- Data plane: Gremlin --------------------------------------------------
    gremlin_databases = optional(map(object({
      name       = string
      throughput = optional(number, null)
      autoscale_settings = optional(object({
        max_throughput = number
      }), null)

      graphs = optional(map(object({
        name                   = string
        partition_key_path     = string
        partition_key_version  = optional(string, null)
        throughput             = optional(number, null)
        default_ttl            = optional(number, null)
        analytical_storage_ttl = optional(number, null)

        autoscale_settings = optional(object({
          max_throughput = number
        }), null)

        index_policy = optional(object({
          automatic      = optional(bool, true)
          indexing_mode  = string
          included_paths = list(string)
          excluded_paths = list(string)
          composite_index = optional(list(object({
            index = set(object({
              path  = string
              order = string
            }))
          })), null)
          spatial_index = optional(list(object({
            path = string
          })), null)
        }), null)

        conflict_resolution_policy = optional(object({
          mode                          = string
          conflict_resolution_path      = optional(string, null)
          conflict_resolution_procedure = optional(string, null)
        }), null)

        unique_key = optional(object({
          paths = list(string)
        }), null)
      })), {})
    })), {})
  }))
  default     = {}
  description = <<-EOT
    A map of Azure Cosmos DB (DocumentDB) Database Accounts to create using the `Azure/avm-res-documentdb-databaseaccount/azurerm` module.
    The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.

    Account placement:
    - `name` - (Required) The name of the CosmosDB Account. Must be 3-44 lowercase letters, numbers and `-`; cannot start/end with `-`. Changing this forces a new resource to be created.
    - `name_random_suffix_configuration` - (Optional) Configuration for appending a random suffix to the account name to ensure global uniqueness. When set, a random lowercase alphanumeric string of the specified length is generated and appended to the name. CosmosDB account names must be 3-44 characters — ensure the total length (base name + hyphen if applicable + suffix) does not exceed 44 characters. Defaults to `null` (no suffix).
      - `length` - (Required) Length of the random suffix.
      - `append_with_hyphen` - (Optional) Whether to separate the base name and suffix with a hyphen. Defaults to `true`.
    - `resource_group_key` - (Optional) **Pattern cross-reference**: the key of a resource group in the `resource_groups` variable (created by `spoke_network_and_share_services_pattern`). Resolved to the resource group name. At least one of `resource_group_key` or `resource_group_name` must be provided.
    - `resource_group_name` - (Optional) The name of the resource group to deploy into. Overrides `resource_group_key`. At least one of `resource_group_key` or `resource_group_name` must be provided.
    - `location` - (Optional) Azure region where the account exists. Defaults to `var.location`. Changing this forces a new resource to be created.
    - `tags` - (Optional) A mapping of tags merged with `var.tags`. Defaults to `{}`.

    Account behaviour:
    - `access_key_metadata_writes_enabled` - (Optional) Whether write operations on metadata resources via account keys are enabled. Defaults to `false`.
    - `analytical_storage_enabled` - (Optional) Enable Analytical Storage. Defaults to `false`. Toggling forces a new resource.
    - `automatic_failover_enabled` - (Optional) Enable automatic failover. Defaults to `true`.
    - `free_tier_enabled` - (Optional) Enable the Free Tier pricing option. Defaults to `false`. Changing this forces a new resource.
    - `local_authentication_disabled` - (Optional) Disable local auth (SQL API only). Defaults to `true`.
    - `minimal_tls_version` - (Optional) Minimal TLS version. Possible value `Tls12`. Defaults to `Tls12`.
    - `mongo_server_version` - (Optional) MongoDB server version. Possible values `7.0`, `6.0`, `5.0`, `4.2`, `4.0`, `3.6`, `3.2`. Defaults to `3.6`.
    - `multiple_write_locations_enabled` - (Optional) Enable multi-region writes (ignored when `backup.type` is `Continuous`). Defaults to `false`.
    - `partition_merge_enabled` - (Optional) Is partition merge enabled. Defaults to `false`.
    - `public_network_access_enabled` - (Optional) Whether public network access is allowed. Defaults to `false`.
    - `network_acl_bypass_for_azure_services` - (Optional) If Azure services can bypass ACLs. Defaults to `false`.
    - `network_acl_bypass_resource_ids` - (Optional) Set of resource IDs allowed to bypass network ACLs. Defaults to `[]`.
    - `ip_range_filter` - (Optional) Set of IP addresses/CIDR ranges allowed (firewall). Defaults to `[]`.

    - `consistency_policy` - (Optional) Consistency policy. Defaults to `{}`.
      - `consistency_level` - (Optional) One of `BoundedStaleness`, `Eventual`, `Session`, `Strong`, `ConsistentPrefix`. Defaults to `BoundedStaleness`.
      - `max_interval_in_seconds` - (Optional) Used with `BoundedStaleness`. Range `5`-`86400`. Defaults to `5`.
      - `max_staleness_prefix` - (Optional) Used with `BoundedStaleness`. Range `10`-`2147483647`. Defaults to `100`.
    - `analytical_storage_config` - (Optional) Analytical storage configuration. Defaults to `null`.
      - `schema_type` - (Required) `FullFidelity` or `WellDefined`.
    - `capacity` - (Optional) Throughput limit configuration. Defaults to `{}`.
      - `total_throughput_limit` - (Optional) Total throughput limit (RU/s). `-1` means no limit. Defaults to `-1`.
    - `backup` - (Optional) Backup policy. Defaults to `{}`.
      - `type` - (Optional) `Continuous` or `Periodic`. Defaults to `Continuous`.
      - `tier` - (Optional) Used with `Continuous`. `Continuous7Days` or `Continuous30Days`. Defaults to `Continuous30Days`.
      - `interval_in_minutes` - (Optional) Used with `Periodic`. Range `60`-`1440`. Defaults to `240`.
      - `retention_in_hours` - (Optional) Used with `Periodic`. Range `8`-`720`. Defaults to `8`.
      - `storage_redundancy` - (Optional) Used with `Periodic`. `Geo`, `Local` or `Zone`. Defaults to `Geo`.
    - `cors_rule` - (Optional) CORS rule. Defaults to `null`.
      - `allowed_headers` / `allowed_methods` / `allowed_origins` / `exposed_headers` - (Required) Sets of strings.
      - `max_age_in_seconds` - (Optional) Range `1`-`2147483647`. Defaults to `null`.
    - `geo_locations` - (Optional) Set of replicated regions. Defaults to the deploy region (zone redundant) when `null`.
      - `location` - (Optional) Azure region. Defaults to `var.location` when not set.
      - `failover_priority` - (Required) `0` indicates the write region.
      - `zone_redundant` - (Optional) Defaults to `true`.
    - `capabilities` - (Optional) Set of capabilities to enable. Defaults to `[]`.
      - `name` - (Required) e.g. `EnableServerless`, `EnableGremlin`, `EnableMongo`, `EnableTable`, `EnableCassandra`, `EnableNoSQLVectorSearch`, etc.
    - `virtual_network_rules` - (Optional) Subnets allowed to access the account. Defaults to `[]`.
      - `subnet_id` - (Optional) The subnet resource ID, used directly (requires the `Microsoft.AzureCosmosDB` service endpoint enabled). Fallback when `vnet_key`/`subnet_key` are not provided.
      - `vnet_key` - (Optional) **Pattern cross-reference**: the key of a virtual network in the `virtual_networks` variable.
      - `subnet_key` - (Optional) **Pattern cross-reference**: the key of a subnet within the VNet identified by `vnet_key`. Resolved to the subnet resource ID.
    - `sql_dedicated_gateway` - (Optional) SQL dedicated gateway. Defaults to `null`.
      - `instance_size` - (Required) `Cosmos.D4s`, `Cosmos.D8s` or `Cosmos.D16s`.
      - `instance_count` - (Optional) `1`-`5`. Defaults to `1`.

    Encryption & identity:
    - `customer_managed_key` - (Optional) Customer-managed key for encryption (ignored for Basic/Standard). Defaults to `null`.
      - `key_name` - (Optional) Key name in the Key Vault, used directly. Fallback when `key_key` is not provided.
      - `key_key` - (Optional) **Pattern cross-reference**: the key of a key in the referenced Key Vault's `keys` map (`key_vaults[key_vault_key].keys`), resolved to the key name (derived from the key's `versionless_id`). Used when `key_name` is not set.
      - `key_vault_resource_id` - (Optional) Full resource ID of the Key Vault, used directly. Fallback when `key_vault_key` is not provided.
      - `key_vault_key` - (Optional) **Pattern cross-reference**: the key of a Key Vault in the `key_vaults` variable, resolved to its resource ID. Used when `key_vault_resource_id` is not set.
      - `key_version` - (Unsupported by CosmosDB).
      - `user_assigned_identity` - (Required) The user-assigned identity used to access the vault.
        - `resource_id` - (Optional) Full resource ID of the user-assigned identity, used directly. Fallback when `key` is not provided.
        - `key` - (Optional) **Pattern cross-reference**: the key of a managed identity in the `managed_identities` variable, resolved to its UAMI resource ID. Used when `resource_id` is not set.
    - `managed_identities` - (Optional) Managed identity configuration. Defaults to `{}`.
      - `system_assigned` - (Optional) Enable system-assigned identity. Defaults to `false`.
      - `user_assigned_resource_ids` - (Optional) Set of user-assigned managed identity resource IDs to assign directly. Defaults to `[]`.
      - `user_assigned_keys` - (Optional) **Pattern cross-reference**: a set of keys from the `managed_identities` variable. Resolved to user-assigned managed identity resource IDs and merged with `user_assigned_resource_ids`. Defaults to `[]`.
    - `lock` - (Optional) Resource lock. Defaults to `null`.
      - `kind` - (Required) `CanNotDelete` or `ReadOnly`.
      - `name` - (Optional) Lock name. Defaults to a generated name.
    - `role_assignments` - (Optional) Map of role assignments to create on the account. Defaults to `{}`.
      - `role_definition_id_or_name` - (Required) Role definition ID or name.
      - `principal_id` - (Optional) Principal object ID, used directly. Mutually exclusive with `managed_identity_key` and `assign_to_caller`.
      - `managed_identity_key` - (Optional) **Pattern cross-reference**: the key of a managed identity in the `managed_identities` variable, resolved to its principal ID. Sets `principal_type` to `ServicePrincipal`. Mutually exclusive with `principal_id` and `assign_to_caller`.
      - `assign_to_caller` - (Optional) When `true`, automatically uses the object ID of the identity running Terraform as the principal. Mutually exclusive with `principal_id` and `managed_identity_key`. Defaults to `false`.
      - `description` - (Optional) Defaults to `null`.
      - `skip_service_principal_aad_check` - (Optional) Defaults to `false`.
      - `delegated_managed_identity_resource_id` - (Optional) Cross-tenant delegated identity. Defaults to `null`.
      - `principal_type` / `condition` / `condition_version` - (Unsupported).
    - `diagnostic_settings` - (Optional) Map of diagnostic settings to create. Defaults to `{}`.
      - `name` - (Optional) Generated if not set.
      - `log_categories` - (Optional) Set of log categories (e.g. `DataPlaneRequests`, `MongoRequests`, `ControlPlaneRequests`). Defaults to `[]`.
      - `log_groups` - (Optional) `allLogs` and/or `audit`. Defaults to `["allLogs"]`.
      - `metric_categories` - (Optional) Defaults to `["AllMetrics"]`.
      - `log_analytics_destination_type` - (Optional) `Dedicated` or `AzureDiagnostics`. Defaults to `Dedicated`.
      - `workspace_resource_id` - (Optional) Log Analytics workspace resource ID, used directly. Defaults to `null`.
      - `workspace_key` - (Optional) **Pattern cross-reference**: the key of a Log Analytics workspace in the `log_analytics_workspaces` variable, resolved to its resource ID. Used when `workspace_resource_id` is not set.
      - `use_default_log_analytics` - (Optional) When `true` (and neither `workspace_resource_id` nor `workspace_key` is set), uses the first workspace in the `log_analytics_workspaces` variable. Defaults to `false`. A workspace is not required — storage account, event hub, or marketplace destinations are also valid.
      - `storage_account_resource_id` - (Optional) Storage account resource ID. Defaults to `null`.
      - `event_hub_authorization_rule_resource_id` - (Optional) Event hub auth rule resource ID. Defaults to `null`.
      - `event_hub_name` - (Optional) Event hub name. Defaults to `null`.
      - `marketplace_partner_resource_id` - (Optional) Marketplace partner resource ID. Defaults to `null`.

    Private networking:
    - `private_endpoints_manage_dns_zone_group` - (Optional) Whether to manage private DNS zone groups with this module. Defaults to `true`.
    - `private_endpoints` - (Optional) Map of private endpoints to create. Defaults to `{}`.
      - `subnet_resource_id` - (Optional) Subnet resource ID to deploy the private endpoint in, used directly. Fallback when `vnet_key`/`subnet_key` are not provided.
      - `vnet_key` - (Optional) **Pattern cross-reference**: the key of a virtual network in the `virtual_networks` variable.
      - `subnet_key` - (Optional) **Pattern cross-reference**: the key of a subnet within the VNet identified by `vnet_key`. Resolved to the subnet resource ID.
      - `subresource_name` - (Required) `Sql`, `SqlDedicated`, `MongoDB`, `Cassandra`, `Gremlin`, `Table`, `Analytical` or `Coordinator`.
      - `name` / `private_dns_zone_group_name` / `private_service_connection_name` / `network_interface_name` - (Optional) Generated if not set.
      - `private_dns_zone` - (Optional) Private DNS zones for the endpoint.
        - `resource_ids` - (Optional) A set of private DNS zone resource IDs, used directly. Defaults to `[]`.
        - `keys` - (Optional) **Pattern cross-reference**: a set of keys from the `private_dns_zones` variable (the spoke's `combined_private_dns_zones_resource_ids`), each resolved to a DNS zone resource ID and merged with `resource_ids`. Defaults to `[]`.
      - `application_security_group_associations` - (Optional) Map of ASG resource IDs. Defaults to `{}`.
      - `location` / `resource_group_name` - (Optional) Default to the account's location/resource group.
      - `ip_configurations` - (Optional) Map of static IP configurations. Each has `name` and `private_ip_address`.
      - `tags` - (Optional) Tags for the private endpoint. Defaults to `null`.
      - `lock` - (Optional) Lock for the private endpoint (`kind`, optional `name`).
      - `role_assignments` - (Optional) Role assignments on the private endpoint (same shape as the account `role_assignments`).

    Data plane (SQL):
    - `sql_databases` - (Optional) Map of SQL databases. Defaults to `{}`.
      - `name` - (Required) Database name.
      - `throughput` - (Optional) RU/s (increments of 100, min 400). Defaults to `null`.
      - `autoscale_settings.max_throughput` - (Required when set) Max RU/s (1,000-1,000,000). Conflicts with `throughput`.
      - `containers` - (Optional) Map of SQL containers. Defaults to `{}`.
        - `partition_key_paths` - (Required) Partition key paths.
        - `name` - (Required) Container name.
        - `partition_key_version` - (Optional) Defaults to `2`.
        - `throughput` / `default_ttl` / `analytical_storage_ttl` - (Optional) Defaults to `null`.
        - `unique_keys[].paths` - (Optional) Sets of paths enforcing uniqueness. Defaults to `[]`.
        - `autoscale_settings.max_throughput` - (Required when set) Max RU/s. Conflicts with `throughput`.
        - `functions` / `stored_procedures` - (Optional) Maps of `{ name, body }`. Defaults to `{}`.
        - `triggers` - (Optional) Map of `{ name, body, type (Pre|Post), operation (All|Create|Update|Delete|Replace) }`. Defaults to `{}`.
        - `conflict_resolution_policy` - (Optional) `{ mode (LastWriterWins|Custom), conflict_resolution_path, conflict_resolution_procedure }`.
        - `indexing_policy` - (Optional) `{ indexing_mode, included_paths[].path, excluded_paths[].path, composite_indexes[].indexes[].{path,order}, spatial_indexes[].path }`.

    Data plane (MongoDB):
    - `mongo_databases` - (Optional) Map of MongoDB databases. Defaults to `{}`.
      - `name` - (Required) Database name.
      - `throughput` - (Optional) RU/s. Defaults to `null`.
      - `autoscale_settings.max_throughput` - (Required when set) Max RU/s. Conflicts with `throughput`.
      - `collections` - (Optional) Map of collections. Defaults to `{}`.
        - `name` - (Required) Collection name.
        - `default_ttl_seconds` / `shard_key` / `throughput` - (Optional) Defaults to `null`.
        - `autoscale_settings.max_throughput` - (Required when set) Max RU/s. Conflicts with `throughput`.
        - `index` - (Optional) `{ keys (list), unique (default false) }`.

    Data plane (Gremlin):
    - `gremlin_databases` - (Optional) Map of Gremlin databases. Defaults to `{}`.
      - `name` - (Required) Database name.
      - `throughput` - (Optional) RU/s. Defaults to `null`.
      - `autoscale_settings.max_throughput` - (Required when set) Max RU/s. Conflicts with `throughput`.
      - `graphs` - (Optional) Map of graphs. Defaults to `{}`.
        - `name` - (Required) Graph name.
        - `partition_key_path` - (Required) Partition key path.
        - `partition_key_version` - (Optional) `1` or `2`. Defaults to `null`.
        - `throughput` / `default_ttl` / `analytical_storage_ttl` - (Optional) Defaults to `null`.
        - `autoscale_settings.max_throughput` - (Required when set) Max RU/s. Conflicts with `throughput`.
        - `index_policy` - (Optional) `{ automatic (default true), indexing_mode, included_paths, excluded_paths, composite_index[].index[].{path,order}, spatial_index[].path }`.
        - `conflict_resolution_policy` - (Optional) `{ mode, conflict_resolution_path, conflict_resolution_procedure }`.
        - `unique_key` - (Optional) `{ paths (list) }`.

    > **Pattern note:** If `location` is not specified, defaults to `var.location`. Tags in `tags` are merged with `var.tags`.
  EOT
}

variable "location" {
  description = "Default location fallback when a Cosmos DB account does not set location."
  type        = string
}

variable "resource_groups" {
  description = "Resource groups output map from spoke module. Used to resolve resource_group_key to name."
  type        = any
  default     = {}
}

variable "managed_identities" {
  description = "Managed identities output map from spoke module. Used to resolve user_assigned_keys, role_assignments managed_identity_key, and customer_managed_key user_assigned_identity.key to UAMI resource IDs / principal IDs."
  type        = any
  default     = {}
}

variable "key_vaults" {
  description = "Key Vaults output map from spoke module. Used to resolve customer_managed_key.key_vault_key to a Key Vault resource ID."
  type        = any
  default     = {}
}

variable "virtual_networks" {
  description = "Virtual networks output map from spoke module. Used to resolve vnet_key/subnet_key (private endpoints and virtual_network_rules) to a subnet resource ID."
  type        = any
  default     = {}
}

variable "private_dns_zones" {
  description = "Combined private DNS zones resource-ID map from spoke module (combined_private_dns_zones_resource_ids). Used to resolve private_endpoints[*].private_dns_zone.keys to DNS zone resource IDs."
  type        = any
  default     = {}
}

variable "log_analytics_workspaces" {
  description = "Map of Log Analytics workspace keys to their resource IDs. Used to resolve diagnostic_settings workspace_key / use_default_log_analytics."
  type        = any
  default     = {}
}

variable "tags" {
  description = "Default tags to merge with per-resource tags."
  type        = map(string)
  default     = {}
}

variable "enable_telemetry" {
  description = "Controls whether telemetry is enabled for the underlying AVM module. See https://aka.ms/avm/telemetryinfo."
  type        = bool
  default     = true
}
