# Load Balancer

This module deploys one or more Azure Load Balancers using the [AVM Load Balancer module](https://registry.terraform.io/modules/Azure/avm-res-network-loadbalancer/azurerm/0.5.0) (`v0.5.0`).

## Key-Based References

| Field | Resolves Via | Description |
|---|---|---|
| `resource_group_key` | `var.resource_groups` | Resource group name |
| `frontend_subnet.vnet_key` / `subnet_key` | `var.virtual_networks` | Frontend subnet resource ID |
| `backend_address_pools.virtual_network.key` | `var.virtual_networks` | Backend pool VNet resource ID |
| `role_assignments.managed_identity_key` | `var.managed_identities` | Principal ID for role assignments |
