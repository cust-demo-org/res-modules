# Terraform Resource Modules

Terraform resource modules built on top of [Azure Verified Modules (AVM)](https://azure.github.io/Azure-Verified-Modules/). They are designed to work alongside the pattern modules [ptn-lzp-connectivity-hub-vnet](https://github.com/cust-demo-org/ptn-lzp-connectivity-hub-vnet) and [ptn-lza-ntwk-shared-services](https://github.com/cust-demo-org/ptn-lza-ntwk-shared-services) from the [cust-demo-org](https://github.com/cust-demo-org) GitHub organization.

All modules support **key-based referencing** — resources created by pattern modules (VNets, subnets, Key Vaults, managed identities, etc.) can be referenced by their map key in `tfvars` rather than by resource ID. This enables deploying multiple pattern and resource modules together in a single Terraform run.

## Modules

| Module | AVM Source | Description |
|---|---|---|
| [`api_management_service`](api_management_service/) | [avm-res-apimanagement-service v0.9.0](https://registry.terraform.io/modules/Azure/avm-res-apimanagement-service/azurerm/0.9.0) | API Management with VNet injection, public IP, managed identities, additional regions, and private endpoints. |
| [`application_gateway`](application_gateway/) | [avm-res-network-applicationgateway v0.5.2](https://registry.terraform.io/modules/Azure/avm-res-network-applicationgateway/azurerm/0.5.2) | Application Gateway with WAF policy, public/private frontends, autoscaling, and backend routing. |
| [`application_insights`](application_insights/) | [avm-res-insights-component v0.4.0](https://registry.terraform.io/modules/Azure/avm-res-insights-component/azurerm/0.4.0) | Workspace-based Application Insights with sampling, retention, and diagnostic settings. |
| [`app_service_plan`](app_service_plan/) | [avm-res-web-serverfarm v2.0.6](https://registry.terraform.io/modules/Azure/avm-res-web-serverfarm/azurerm/2.0.6) | App Service Plans (Server Farms) with VNet integration, scaling, and zone balancing. |
| [`communication_services`](communication_services/) | Native `azapi_resource`\* | Azure Communication Services with linked email domains and managed identities. |
| [`cosmos_db`](cosmos_db/) | [avm-res-documentdb-databaseaccount v0.10.0](https://registry.terraform.io/modules/Azure/avm-res-documentdb-databaseaccount/azurerm/0.10.0) | Cosmos DB accounts with CMK encryption, geo-replication, VNet rules, and private endpoints. |
| [`data_factory`](data_factory/) | [avm-res-datafactory-factory v0.1.0](https://registry.terraform.io/modules/Azure/avm-res-datafactory-factory/azurerm/0.1.0) | Azure Data Factory with CMK encryption, managed VNet, Git integration, private endpoints, and diagnostic settings. |
| [`disk_encryption_set`](disk_encryption_set/) | Native `azurerm_disk_encryption_set`\* | Disk Encryption Sets for customer-managed key encryption of VM disks. Referenced by the `virtual_machine` module. |
| [`email_communication_services`](email_communication_services/) | Native `azapi_resource`\* | Email Communication Services and email domains; consumed by `communication_services`. |
| [`load_balancer`](load_balancer/) | [avm-res-network-loadbalancer v0.5.0](https://registry.terraform.io/modules/Azure/avm-res-network-loadbalancer/azurerm/0.5.0) | Azure Load Balancer (Standard/Regional) with frontend IPs, backend pools, probes, rules, NAT rules, and outbound rules. |
| [`private_endpoint`](private_endpoint/) | [avm-res-network-privateendpoint v0.2.0](https://registry.terraform.io/modules/Azure/avm-res-network-privateendpoint/azurerm/0.2.0) | Standalone Private Endpoints for connecting to Azure PaaS services over private networks. |
| [`public_ip`](public_ip/) | [avm-res-network-publicipaddress v0.2.1](https://registry.terraform.io/modules/Azure/avm-res-network-publicipaddress/azurerm/0.2.1) | Public IP addresses with SKU/zones, DNS labels, DDoS protection, and diagnostics. |
| [`virtual_machine`](virtual_machine/) | [avm-res-compute-virtualmachine v0.20.0](https://registry.terraform.io/modules/Azure/avm-res-compute-virtualmachine/azurerm/0.20.0) | Windows/Linux VMs with NIC configuration, data disks, disk encryption, Azure Backup, credential management, and extensions. |
| [`web_application_firewall_policy`](web_application_firewall_policy/) | [avm-res-network-applicationgatewaywebapplicationfirewallpolicy v0.2.0](https://registry.terraform.io/modules/Azure/avm-res-network-applicationgatewaywebapplicationfirewallpolicy/azurerm/0.2.0) | App Gateway WAF policies with managed/custom rules; consumed by `application_gateway`. |
| [`web_site`](web_site/) | [avm-res-web-site v0.22.0](https://registry.terraform.io/modules/Azure/avm-res-web-site/azurerm/0.22.0) | App Services / Function Apps / Logic Apps with deployment slots, App Insights, and private endpoints. |

> \* **`disk_encryption_set`**, **`communication_services`**, and **`email_communication_services`** do not use an AVM source. The AVM Disk Encryption Set module was not adopted due to underlying bugs and provider version conflicts. No AVM module exists for `communication_services`, and the AVM Email Communication Services module was not adopted due to underlying bugs; both use the native `azapi_resource` instead. These are exceptions to the AVM-based approach used by all other modules.

## Key-Based Cross-Referencing

Each module accepts outputs from pattern modules as input variables (e.g. `var.virtual_networks`, `var.key_vaults`, `var.managed_identities`, `var.resource_groups`). Instead of hard-coding resource IDs in your `tfvars`, you reference resources by their map key:

```hcl
# Reference a subnet by key instead of resource ID
network_configuration = {
  vnet_key   = "hub_vnet"
  subnet_key = "pe_subnet"
}

# Reference a Key Vault key by key instead of URI
key_vault_key_reference = {
  key_vault_key = "encryption_kv"
  key_key       = "des_key"
}

# Reference a managed identity by key instead of resource ID
managed_identities = {
  system_assigned                     = false
  user_assigned_managed_identity_keys = ["vm_identity"]
}
```

Every key-based field also supports a direct resource ID fallback (e.g. `subnet_resource_id`, `resource_id`) for resources not managed by the pattern modules.

## Common Input Variables

All modules share a consistent set of cross-reference variables sourced from pattern module outputs:

| Variable | Description |
|---|---|
| `resource_groups` | Resource groups output map — resolves `resource_group_key` to a resource group name. |
| `virtual_networks` | Virtual networks output map — resolves `vnet_key`/`subnet_key` to subnet resource IDs. |
| `key_vaults` | Key Vaults output map — resolves key vault and key references to URIs/IDs. |
| `managed_identities` | Managed identities output map — resolves identity keys to resource IDs and principal IDs. |
| `private_dns_zone_resource_ids` | Private DNS zone map — resolves DNS zone keys to resource IDs. |
| `log_analytics_workspaces` | Log Analytics workspaces output map — resolves `workspace_key` to workspace resource IDs for diagnostics. |
| `storage_accounts` | Storage accounts output map — resolves storage keys to names, resource IDs, and access keys. |
| `public_ips` | Public IP output map — resolves public IP keys to resource IDs. |
| `service_plans` | App Service Plan output map — resolves `service_plan_key` to plan resource IDs. |
| `application_insights` | Application Insights output map — resolves AI keys to connection strings / instrumentation keys. |
| `web_application_firewall_policies` | WAF policy output map — resolves WAF policy keys to resource IDs. |
| `location` | Default Azure region (used when a resource does not specify its own location). |
| `tags` | Default tags merged with per-resource tags. |
| `enable_telemetry` | Toggle AVM telemetry collection (default varies by module). |

> Not every module uses every variable — see each module's `variables.tf` for the specific set it accepts.

## Dependant Resource Variables

Some modules accept other resource modules' outputs as variables to enable key-based references between them. Examples:

- `virtual_machine` takes `disk_encryption_sets` (CMK on disks), `load_balancers` (backend pools), and `recovery_services_vaults` (backup).
- `application_gateway` takes `public_ips` and `web_application_firewall_policies`.
- `web_site` takes `service_plans` (from `app_service_plan`) and `application_insights`.
- `communication_services` takes `email_services_domains` (from `email_communication_services`).
- `api_management_service` takes `public_ips` for gateway/region public IPs.

## Prerequisites

- Pattern module outputs from [ptn-lzp-connectivity-hub-vnet](https://github.com/cust-demo-org/ptn-lzp-connectivity-hub-vnet) or [ptn-lza-ntwk-shared-services](https://github.com/cust-demo-org/ptn-lza-ntwk-shared-services) (for key-based referencing)

## Development Skills

This repo ships two AI agent skills under [.github/skills](.github/skills) that automate authoring new modules and wiring them into root environments following the repo conventions:

| Skill | Purpose | Example Usage |
|---|---|---|
| [`terraform-resource-module-creator`](.github/skills/terraform-resource-module-creator) | Generates a single self-contained resource module (`variables.tf`, `main.tf`, `outputs.tf`, `terraform.tf`) from an AVM module, native `azurerm` resource, or `azapi`/ARM reference. Crawls the source schema exhaustively, applies the standard `map(object)` + `for_each` conventions, key-based cross-references, managed-identity blocks, and raw outputs. | "/terraform-resource-module-creator Generate a resource module web_application_firewall_policy using this AVM module: terraform registry -> https://registry.terraform.io/modules/Azure/avm-res-network-applicationgatewaywebapplicationfirewallpolicy/azurerm/0.2.0, github ->https://github.com/Azure/terraform-azurerm-avm-res-network-applicationgatewaywebapplicationfirewallpolicy. Create a new folder called web_application_firewall_policy" |
| [`terraform-resource-module-wirer`](.github/skills/terraform-resource-module-wirer) | Wires an existing module into a root environment — adds the wrapper variable, the `module` block (passing pattern/sibling-module outputs), a `terraform.tfvars` example, and required providers. | "/terraform-resource-module-wirer and wire web_application_firewall_policy module to _connectivity project folder. Take note of dependancy from ptn-lzp-connectivity-hub-vnet and web_application_firewall_policy modules." |
| [`terraform-resource-module-docs-generator`](.github/skills/terraform-resource-module-docs-generator) | Generates and maintains per-module docs — creates `.terraform-docs.yml`, `_header.md`, `_footer.md`, audits `main.tf` for key-based cross-references, and runs `terraform-docs` to regenerate `README.md`. | "/terraform-resource-module-docs-generator application_gateway" or "/terraform-resource-module-docs-generator" (all modules) |

The three skills are complementary: the creator authors module files, the wirer connects them into an environment, and the docs-generator produces and refreshes each module's README.

## Usage
Refer to repository [azure-terraform-infra-as-config](https://github.com/cust-demo-org/azure-terraform-infra-as-config)