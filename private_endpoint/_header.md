# Private Endpoint

This module deploys one or more standalone Azure Private Endpoints using the [AVM Private Endpoint module](https://registry.terraform.io/modules/Azure/avm-res-network-privateendpoint/azurerm/0.2.0) (`v0.2.0`).

## Key-Based References

| Field | Resolves Via | Description |
|---|---|---|
| `resource_group_key` | `var.resource_groups` | Resource group name |
| `network_configuration.vnet_key` / `subnet_key` | `var.virtual_networks` | Subnet resource ID |
| `private_dns_zone_keys` | `var.private_dns_zone_resource_ids` | Private DNS zone resource IDs |
| `role_assignments.managed_identity_key` | `var.managed_identities` | Principal ID for role assignments |
