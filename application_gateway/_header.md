# Application Gateway

This module deploys one or more Azure Application Gateways using the [AVM Application Gateway module](https://registry.terraform.io/modules/Azure/avm-res-network-applicationgateway/azurerm/0.5.2) (`v0.5.2`).

## Key-Based References

| Field | Resolves Via | Description |
|---|---|---|
| `resource_group_key` | `var.resource_groups` | Resource group name |
| `gateway_ip_configuration.vnet_key` / `subnet_key` | `var.virtual_networks` | Gateway subnet resource ID |
| `public_ip_address_configuration.public_ip_key` | `var.public_ips` | Frontend public IP resource ID |
| `app_gateway_waf_policy_key` | `var.web_application_firewall_policies` | WAF policy resource ID |
| `backend_address_pools` IP config `vnet_key` / `subnet_key` | `var.virtual_networks` | Backend pool subnet resource ID |
| `managed_identities.user_assigned_keys` | `var.managed_identities` | User-assigned managed identity resource IDs |
