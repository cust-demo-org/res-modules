# Cosmos DB

This module deploys one or more Azure Cosmos DB accounts using the [AVM DocumentDB Database Account module](https://registry.terraform.io/modules/Azure/avm-res-documentdb-databaseaccount/azurerm/0.10.0) (`v0.10.0`).

## Key-Based References

| Field | Resolves Via | Description |
|---|---|---|
| `resource_group_key` | `var.resource_groups` | Resource group name |
| `virtual_network_rules.vnet_key` / `subnet_key` | `var.virtual_networks` | Allowed subnet resource IDs |
| `customer_managed_key.key_vault_key` / `key_key` | `var.key_vaults` | CMK Key Vault and key references |
| `customer_managed_key.user_assigned_identity.key` | `var.managed_identities` | CMK identity resource ID |
| `managed_identities.user_assigned_keys` | `var.managed_identities` | User-assigned managed identity resource IDs |
| `role_assignments.managed_identity_key` | `var.managed_identities` | Principal ID for role assignments |
| `private_endpoints.vnet_key` / `subnet_key` | `var.virtual_networks` | Private endpoint subnet resource ID |
| `diagnostic_settings.workspace_key` | `var.log_analytics_workspaces` | Diagnostic destination workspace resource ID |
