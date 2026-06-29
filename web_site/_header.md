# Web Site

This module deploys one or more Azure App Services / Function Apps / Logic Apps (with deployment slots) using the [AVM Web Site module](https://registry.terraform.io/modules/Azure/avm-res-web-site/azurerm/0.22.0) (`v0.22.0`).

## Key-Based References

| Field | Resolves Via | Description |
|---|---|---|
| `resource_group_key` | `var.resource_groups` | Resource group resource ID (parent) |
| `service_plan_key` | `var.service_plans` | App Service Plan resource ID |
| `network_configuration.vnet_key` / `subnet_key` | `var.virtual_networks` | VNet integration subnet resource ID |
| `application_insights.key` | `var.application_insights` | Connection string / instrumentation key for app settings |
| `application_insights_user_assigned_identity_key` | `var.managed_identities` | AI managed-identity client ID |
| `key_vault_reference_identity_key` | `var.managed_identities` | Key Vault reference identity resource ID |
| `storage_account_key` | `var.storage_accounts` | Storage account name / access key |
| `storage_user_assigned_identity_key` | `var.managed_identities` | Storage identity resource ID |
| `certificates.key_vault_key` | `var.key_vaults` | Certificate Key Vault resource ID |
| `private_endpoints.vnet_key` / `subnet_key` | `var.virtual_networks` | Private endpoint subnet resource ID |
| `diagnostic_settings.workspace_key` | `var.log_analytics_workspaces` | Diagnostic destination workspace resource ID |
| `role_assignments.managed_identity_key` | `var.managed_identities` | Principal ID for role assignments |
| `managed_identities.user_assigned_keys` | `var.managed_identities` | User-assigned managed identity resource IDs |
