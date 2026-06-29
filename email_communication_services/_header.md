# Email Communication Services

This module deploys one or more Azure Email Communication Services and their email domains using the native `azapi_resource` (`Microsoft.Communication/emailServices` and `.../domains`).

> **Note:** This module uses `azapi_resource` directly rather than an AVM source.

## Key-Based References

| Field | Resolves Via | Description |
|---|---|---|
| `resource_group_key` | `var.resource_groups` | Resource group resource ID (parent) |
