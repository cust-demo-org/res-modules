# Public IP

This module deploys one or more Azure Public IP addresses using the [AVM Public IP Address module](https://registry.terraform.io/modules/Azure/avm-res-network-publicipaddress/azurerm/0.2.1) (`v0.2.1`).

## Key-Based References

| Field | Resolves Via | Description |
|---|---|---|
| `resource_group_key` | `var.resource_groups` | Resource group name |
| `diagnostic_settings.workspace_key` | `var.log_analytics_workspaces` | Diagnostic destination workspace resource ID |
| `role_assignments.managed_identity_key` | `var.managed_identities` | Principal ID for role assignments |
