# Terraform Resource Modules

Terraform resource modules built on top of [Azure Verified Modules (AVM)](https://azure.github.io/Azure-Verified-Modules/). They are designed to work alongside the pattern modules [ptn-lzp-connectivity-hub-vnet](https://github.com/cust-demo-org/ptn-lzp-connectivity-hub-vnet) and [ptn-lza-ntwk-shared-services](https://github.com/cust-demo-org/ptn-lza-ntwk-shared-services) from the [cust-demo-org](https://github.com/cust-demo-org) GitHub organization.

All modules support **key-based referencing** — resources created by pattern modules (VNets, subnets, Key Vaults, managed identities, etc.) can be referenced by their map key in `tfvars` rather than by resource ID. This enables deploying multiple pattern and resource modules together in a single Terraform run.

## Modules

| Module | AVM Source | Description |
|---|---|---|
| [`data_factory`](data_factory/) | [avm-res-datafactory-factory v0.1.0](https://registry.terraform.io/modules/Azure/avm-res-datafactory-factory/azurerm/0.1.0) | Azure Data Factory with CMK encryption, managed VNet, Git integration, private endpoints, and diagnostic settings. |
| [`disk_encryption_set`](disk_encryption_set/) | Native `azurerm_disk_encryption_set`\* | Disk Encryption Sets for customer-managed key encryption of VM disks. Referenced by the `virtual_machine` module. |
| [`load_balancer`](load_balancer/) | [avm-res-network-loadbalancer v0.5.0](https://registry.terraform.io/modules/Azure/avm-res-network-loadbalancer/azurerm/0.5.0) | Azure Load Balancer (Standard/Regional) with frontend IPs, backend pools, probes, rules, NAT rules, and outbound rules. |
| [`private_endpoint`](private_endpoint/) | [avm-res-network-privateendpoint v0.2.0](https://registry.terraform.io/modules/Azure/avm-res-network-privateendpoint/azurerm/0.2.0) | Standalone Private Endpoints for connecting to Azure PaaS services over private networks. |
| [`virtual_machine`](virtual_machine/) | [avm-res-compute-virtualmachine v0.20.0](https://registry.terraform.io/modules/Azure/avm-res-compute-virtualmachine/azurerm/0.20.0) | Windows/Linux VMs with NIC configuration, data disks, disk encryption, Azure Backup, credential management, and extensions. |

> \* **`disk_encryption_set`** is the only module that does not use an AVM source. The AVM Disk Encryption Set module was not adopted due to underlying bugs and provider version conflicts. The native `azurerm_disk_encryption_set` resource is used directly as an exception to the AVM-based approach used by all other modules.

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
| `location` | Default Azure region (used when a resource does not specify its own location). |
| `tags` | Default tags merged with per-resource tags. |
| `enable_telemetry` | Toggle AVM telemetry collection (default varies by module). |

> Not every module uses every variable — see each module's `variables.tf` for the specific set it accepts.

## Dependant Resource Variables

Some modules such as virtual machine have additiional variables that allow referencing other resource modules' outputs. For example, the `virtual_machine` module takes in `disk_encryption_sets` variable which allows referencing outputs from the `disk_encryption_set` module with key-based references to enable CMK encryption on VM disks.

## Prerequisites

- Pattern module outputs from [ptn-lzp-connectivity-hub-vnet](https://github.com/cust-demo-org/ptn-lzp-connectivity-hub-vnet) or [ptn-lza-ntwk-shared-services](https://github.com/cust-demo-org/ptn-lza-ntwk-shared-services) (for key-based referencing)

## Usage
Refer to repository [azure-terraform-infrastructure-as-configuration](TODO-placeholder)