data "azurerm_client_config" "current" {}

locals {
  # Flatten the per-service domains map into a single map keyed by "<service_key>|<domain_key>"
  # so the email domains can be created with a single for_each.
  email_services_domains = merge([
    for svc_key, svc in var.email_communication_services : {
      for dom_key, dom in svc.domains :
      "${svc_key}|${dom_key}" => {
        service_key              = svc_key
        name                     = dom.name
        domain_management        = dom.domain_management
        user_engagement_tracking = dom.user_engagement_tracking
        tags                     = dom.tags
      }
    }
  ]...)
}

resource "azapi_resource" "email_communication_service" {
  for_each = var.email_communication_services

  type      = "Microsoft.Communication/emailServices@2025-09-01"
  name      = each.value.name
  parent_id = each.value.resource_group_name != null ? "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${each.value.resource_group_name}" : var.resource_groups[each.value.resource_group_key].resource_id
  location  = coalesce(each.value.location, var.location)

  # Email Communication Services use Microsoft.Communication/emailServices properties.
  # Reference: https://learn.microsoft.com/en-us/azure/templates/microsoft.communication/emailservices?pivots=deployment-language-terraform
  body = {
    properties = {
      dataLocation = each.value.data_location
    }
  }

  tags = merge(var.tags, each.value.tags)
}

resource "azapi_resource" "email_services_domain" {
  for_each = local.email_services_domains

  type      = "Microsoft.Communication/emailServices/domains@2025-09-01"
  name      = each.value.name
  parent_id = azapi_resource.email_communication_service[each.value.service_key].id
  location  = azapi_resource.email_communication_service[each.value.service_key].location

  # Email domains use Microsoft.Communication/emailServices/domains properties.
  # Reference: https://learn.microsoft.com/en-us/azure/templates/microsoft.communication/emailservices/domains?pivots=deployment-language-terraform
  body = {
    properties = {
      domainManagement       = each.value.domain_management
      userEngagementTracking = each.value.user_engagement_tracking
    }
  }

  tags = merge(var.tags, each.value.tags)
}
