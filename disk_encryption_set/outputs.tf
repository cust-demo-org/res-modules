output "disk_encryption_sets" {
  value       = azurerm_disk_encryption_set.this
  description = "Map of disk encryption set keys to their azurerm_disk_encryption_set resource objects. Each object includes id, name, key_vault_key_id, and identity attributes."
}
