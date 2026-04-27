resource "azurerm_disk_encryption_set" "this" {
  for_each = var.disk_encryption_sets

  name                = each.value.name
  location            = coalesce(each.value.location, var.location)
  resource_group_name = coalesce(each.value.resource_group_name, var.resource_groups[each.value.resource_group_key].name)

  # Key-based reference: resolve key_vault_key + key_name to construct Key Vault Key URL
  key_vault_key_id = try(
    var.key_vaults[each.value.key_vault_key_reference.key_vault_key].keys[each.value.key_vault_key_reference.key_key].versionless_id,
    each.value.key_vault_key_reference.resource_id
  )

  auto_key_rotation_enabled = each.value.auto_key_rotation_enabled
  encryption_type           = each.value.encryption_type
  federated_client_id       = each.value.federated_client_id
  tags                      = merge(var.tags, each.value.tags)

  # Key-based reference: resolve user_assigned_keys to UAMI resource IDs, merge with direct resource IDs
  dynamic "identity" {
    for_each = (
      each.value.managed_identities.system_assigned ||
      length(each.value.managed_identities.user_assigned_resource_ids) > 0 ||
      length(each.value.managed_identities.user_assigned_keys) > 0
    ) ? { this = each.value.managed_identities } : {}

    content {
      type = (
        identity.value.system_assigned &&
        (length(identity.value.user_assigned_resource_ids) > 0 || length(identity.value.user_assigned_keys) > 0)
        ? "SystemAssigned, UserAssigned"
        : (length(identity.value.user_assigned_resource_ids) > 0 || length(identity.value.user_assigned_keys) > 0)
        ? "UserAssigned"
        : "SystemAssigned"
      )
      identity_ids = setunion(
        identity.value.user_assigned_resource_ids,
        toset([for key in identity.value.user_assigned_keys : var.managed_identities[key].resource_id])
      )
    }
  }
}
