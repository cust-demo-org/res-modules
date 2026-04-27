variable "disk_encryption_sets" {
  type = map(object({
    name                = string
    resource_group_key  = optional(string)
    resource_group_name = optional(string)
    location            = optional(string)
    key_vault_key_reference = optional(object({
      key_vault_key = optional(string)
      key_key       = optional(string)
      resource_id   = optional(string)
    }))
    auto_key_rotation_enabled = optional(bool, false)
    encryption_type           = optional(string, "EncryptionAtRestWithCustomerKey")
    federated_client_id       = optional(string)
    managed_identities = optional(object({
      system_assigned            = optional(bool, false)
      user_assigned_resource_ids = optional(set(string), [])
      user_assigned_keys         = optional(set(string), [])
    }), {})
    tags = optional(map(string), {})
  }))
  default     = {}
  description = <<-EOT
    A map of Azure Disk Encryption Sets to create using the `azurerm_disk_encryption_set` resource.
    The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.

    - `name` - (Required) The name of the Disk Encryption Set. Changing this forces a new resource to be created.
    - `resource_group_key` - (Required) **Pattern cross-reference**: the key of a resource group in the `resource_groups` variable (created by `spoke_network_and_share_services_pattern`). Resolved to the resource group name. At least one of `resource_group_key` or `resource_group_name` must be provided.
    - `resource_group_name` - (Optional) The name of the resource group to deploy the Disk Encryption Set into. Overrides `resource_group_key`. At least one of `resource_group_key` or `resource_group_name` must be provided.
    - `location` - (Optional) Specifies the Azure Region where the Disk Encryption Set should exist. Defaults to `var.location`. Changing this forces a new resource to be created.
    - `key_vault_key_reference` - (Optional) Key Vault key reference for the Disk Encryption Set. Provide either key-based references (`key_vault_key`/`key_key`) or a direct `resource_id`, not both.
      - `key_vault_key` - (Optional) **Pattern cross-reference**: the key of a Key Vault in the `key_vaults` variable. Used together with `key_key` to construct the Key Vault Key URL from the Key Vault URI output.
      - `key_key` - (Optional) The key of the key within the Key Vault specified by `key_vault_key`. Used together with `key_vault_key` to construct the Key Vault Key URL from the Key Vault URI output.
      - `resource_id` - (Optional) Specifies the URL to a Key Vault Key (either the ID or the versionless ID).
    - `auto_key_rotation_enabled` - (Optional) Boolean to specify whether Azure Disk Encryption Set automatically rotates the encryption Key to latest version. Defaults to `false`.
    - `encryption_type` - (Optional) The type of key used to encrypt the data of the disk. Possible values are `EncryptionAtRestWithCustomerKey`, `EncryptionAtRestWithPlatformAndCustomerKeys` and `ConfidentialVmEncryptedWithCustomerKey`. Defaults to `EncryptionAtRestWithCustomerKey`.
    - `federated_client_id` - (Optional) Multi-tenant application client id to access key vault in a different tenant.
    - `managed_identities` - (Optional) Managed identity configuration for the Disk Encryption Set. Defaults to `{}`.
      - `system_assigned` - (Optional) Whether to enable system-assigned managed identity. Defaults to `false`.
      - `user_assigned_resource_ids` - (Optional) A set of user-assigned managed identity resource IDs to assign directly. Defaults to `[]`.
      - `user_assigned_keys` - (Optional) **Pattern cross-reference**: a set of keys from the `managed_identities` variable. Resolved to user-assigned managed identity resource IDs and merged with `user_assigned_resource_ids`. Defaults to `[]`.
    - `tags` - (Optional) A mapping of tags merged with `var.tags`. Defaults to `{}`.

    > **Downstream references:** Other modules reference this resource via the map key:
    > - `virtual_machines.<vm_key>.os_disk.disk_encryption_set.key` → key from this map.
    > - `virtual_machines.<vm_key>.data_disk_managed_disks.<disk_key>.disk_encryption_set.key` → key from this map.

    > **Pattern note:** If `location` is not specified, defaults to `var.location`. Tags in `tags` are merged with `var.tags`.
  EOT
}

variable "location" {
  description = "Default location fallback when a disk encryption set does not set location."
  type        = string
}

variable "resource_groups" {
  description = "Resource groups output map from spoke module. Used to resolve resource_group_key to name."
  type        = any
  default     = {}
}

variable "key_vaults" {
  description = "Key Vaults output map from spoke module. Used to resolve key_vault_key_reference.key_vault_key to Key Vault URI."
  type        = any
  default     = {}
}

variable "managed_identities" {
  description = "Managed identities output map from spoke module. Used to resolve user_assigned_keys to UAMI resource IDs."
  type        = any
  default     = {}
}

variable "tags" {
  description = "Default tags to merge with per-resource tags."
  type        = map(string)
  default     = {}
}
