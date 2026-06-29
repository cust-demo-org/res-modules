# API Management Service

This module deploys one or more Azure API Management services using the [AVM API Management Service module](https://registry.terraform.io/modules/Azure/avm-res-apimanagement-service/azurerm/0.9.0) (`v0.9.0`).

## Key-Based References

| Field | Resolves Via | Description |
|---|---|---|
| `resource_group_key` | `var.resource_groups` | Resource group name |
| `virtual_network_vnet_key` / `virtual_network_subnet_key` | `var.virtual_networks` | VNet injection subnet resource ID |
| `public_ip_address_key` | `var.public_ips` | Public IP resource ID |
| `additional_location.public_ip_address_key` / `vnet_key` / `subnet_key` | `var.public_ips` / `var.virtual_networks` | Per-region public IP and subnet resource IDs |
| `managed_identities.user_assigned_keys` | `var.managed_identities` | User-assigned managed identity resource IDs |
| `private_endpoints.vnet_key` / `subnet_key` | `var.virtual_networks` | Private endpoint subnet resource ID |
| `diagnostic_settings.workspace_key` | `var.log_analytics_workspaces` | Diagnostic destination workspace resource ID |
| `role_assignments.managed_identity_key` | `var.managed_identities` | Principal ID for role assignments |
