data "azurerm_client_config" "current" {}

resource "azapi_resource" "communication_service" {
  for_each = var.communication_services

  type      = "Microsoft.Communication/communicationServices@2025-09-01"
  name      = each.value.name
  parent_id = each.value.resource_group_name != null ? "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${each.value.resource_group_name}" : var.resource_groups[each.value.resource_group_key].resource_id
  location  = coalesce(each.value.location, var.location)

  # Communication Services use Microsoft.Communication/communicationServices properties.
  # Reference: https://learn.microsoft.com/azure/templates/microsoft.communication/communicationservices?pivots=deployment-language-terraform
  body = {
    properties = {
      dataLocation        = each.value.data_location
      disableLocalAuth    = each.value.disable_local_auth
      publicNetworkAccess = each.value.public_network_access
      linkedDomains = tolist(setunion(each.value.linked_domains.resource_ids, toset([
          for key in each.value.linked_domains.keys :
          # Each key must be in the form "<service_key>.<domain_key>" and resolves to
          # that single email domain's resource ID via the email_services_domains output
          # (keyed "<service_key>|<domain_key>").
          var.email_services_domains["${split(".", key)[0]}|${split(".", key)[1]}"].id
        ])
      ))

    }
  }

  tags = merge(var.tags, each.value.tags)

  # Key-based reference: resolve user_assigned_keys to UAMI resource IDs, merge with direct resource IDs.
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
