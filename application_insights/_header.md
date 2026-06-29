# Application Insights

This module deploys one or more Azure Application Insights components using the [AVM Insights Component module](https://registry.terraform.io/modules/Azure/avm-res-insights-component/azurerm/0.4.0) (`v0.4.0`).

## Key-Based References

| Field | Resolves Via | Description |
|---|---|---|
| `resource_group_key` | `var.resource_groups` | Resource group name |
| `workspace_key` | `var.log_analytics_workspaces` | Log Analytics workspace resource ID (falls back to first workspace) |
| `linked_storage_account.key` | `var.storage_accounts` | Profiler storage account resource ID |
| `diagnostic_settings.workspace_key` | `var.log_analytics_workspaces` | Diagnostic destination workspace resource ID |
| `role_assignments.managed_identity_key` | `var.managed_identities` | Principal ID for role assignments |
