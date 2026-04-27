# Data Factory

This module deploys one or more Azure Data Factory instances using the [AVM Data Factory module](https://registry.terraform.io/modules/Azure/avm-res-datafactory-factory/azurerm/0.1.0) (`v0.1.0`). 

## Key-Based References

| Field | Resolves Via | Description |
|---|---|---|
| `resource_group_key` | `var.resource_groups` | Resource group name |
| `network_configuration.vnet_key` / `subnet_key` | `var.virtual_networks` | Subnet resource ID for private endpoints |
| `customer_managed_key.key_vault_key` / `key_key` | `var.key_vaults` | Key Vault Key URI for CMK encryption |
| `managed_identities.user_assigned_managed_identity_keys` | `var.managed_identities` | User-assigned managed identity resource IDs |
| `private_dns_zone.keys` | `var.private_dns_zone_resource_ids` | Private DNS zone resource IDs |
| `role_assignments.managed_identity_key` | `var.managed_identities` | Principal ID for role assignments |
