# Virtual Machine

This module deploys one or more Azure Virtual Machines (Windows or Linux) using the [AVM Virtual Machine module](https://registry.terraform.io/modules/Azure/avm-res-compute-virtualmachine/azurerm/0.20.0) (`v0.20.0`).

## Key-Based References

| Field | Resolves Via | Description |
|---|---|---|
| `resource_group_key` | `var.resource_groups` | Resource group name |
| `network_interfaces.ip_configurations.subnet.vnet_key` / `subnet_key` | `var.virtual_networks` | NIC subnet resource ID |
| `network_interfaces.ip_configurations.load_balancer_backend_pools.load_balancer_key` / `backend_pool_key` | `var.load_balancers` | Load balancer backend pool resource ID |
| `os_disk.disk_encryption_set.key` | `var.disk_encryption_sets` | OS disk encryption set resource ID |
| `data_disk_managed_disks.disk_encryption_set.key` | `var.disk_encryption_sets` | Data disk encryption set resource ID |
| `azure_backup_configurations.recovery_services_vault.key` | `var.recovery_services_vaults` | Recovery Services Vault resource ID |
| `account_credentials.key_vault_configuration.key_vault_key` | `var.key_vaults` | Key Vault resource ID for credential storage |
| `managed_identities.user_assigned_managed_identity_keys` | `var.managed_identities` | User-assigned managed identity resource IDs |
| `role_assignments.managed_identity_key` | `var.managed_identities` | Principal ID for role assignments |
