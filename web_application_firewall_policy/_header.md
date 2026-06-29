# Web Application Firewall Policy

This module deploys one or more Application Gateway WAF policies using the [AVM Application Gateway WAF Policy module](https://registry.terraform.io/modules/Azure/avm-res-network-applicationgatewaywebapplicationfirewallpolicy/azurerm/0.2.0) (`v0.2.0`).

## Key-Based References

| Field | Resolves Via | Description |
|---|---|---|
| `resource_group_key` | `var.resource_groups` | Resource group name |
| `role_assignments.managed_identity_key` | `var.managed_identities` | Principal ID for role assignments |
