# Communication Services

This module deploys one or more Azure Communication Services using the native `azapi_resource` (`Microsoft.Communication/communicationServices`).

> **Note:** This module uses `azapi_resource` directly rather than an AVM source.

## Key-Based References

| Field | Resolves Via | Description |
|---|---|---|
| `resource_group_key` | `var.resource_groups` | Resource group resource ID (parent) |
| `linked_domains.keys` (`<service_key>.<domain_key>`) | `var.email_services_domains` | Linked email domain resource IDs |
| `managed_identities.user_assigned_keys` | `var.managed_identities` | User-assigned managed identity resource IDs |
