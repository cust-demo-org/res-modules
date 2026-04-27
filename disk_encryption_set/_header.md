# Disk Encryption Set

This module deploys one or more Azure Disk Encryption Sets using the native `azurerm_disk_encryption_set` resource.

> **Note:** This is the only module in this repository that does not use an AVM source. The AVM Disk Encryption Set module was not adopted due to underlying bugs and provider version conflicts.

## Key-Based References

| Field | Resolves Via | Description |
|---|---|---|
| `resource_group_key` | `var.resource_groups` | Resource group name |
| `key_vault_key_reference.key_vault_key` / `key_key` | `var.key_vaults` | Key Vault Key versionless ID |
| `managed_identities.user_assigned_keys` | `var.managed_identities` | User-assigned managed identity resource IDs |
