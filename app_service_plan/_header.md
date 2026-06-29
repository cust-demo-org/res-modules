# App Service Plan

This module deploys one or more Azure App Service Plans (Server Farms) using the [AVM Web Server Farm module](https://registry.terraform.io/modules/Azure/avm-res-web-serverfarm/azurerm/2.0.6) (`v2.0.6`).

## Key-Based References

| Field | Resolves Via | Description |
|---|---|---|
| `resource_group_key` | `var.resource_groups` | Resource group resource ID (parent) |
| `network_configuration.vnet_key` / `subnet_key` | `var.virtual_networks` | VNet integration subnet resource ID |
| `managed_identities.user_assigned_keys` | `var.managed_identities` | User-assigned managed identity resource IDs |
| `diagnostic_settings.workspace_key` | `var.log_analytics_workspaces` | Diagnostic destination workspace resource ID |
| `role_assignments.managed_identity_key` | `var.managed_identities` | Principal ID for role assignments |
