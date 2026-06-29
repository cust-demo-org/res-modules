output "email_communication_services" {
  value       = azapi_resource.email_communication_service
  description = "Map of email communication service keys to their raw azapi_resource objects. Each object includes id, name, and other resource attributes."
}

output "email_services_domains" {
  value       = azapi_resource.email_services_domain
  description = "Map of email domain keys (in the form `<service_key>|<domain_key>`) to their raw azapi_resource objects. Each object includes id, name, and other resource attributes. Used by Communication Services `linked_domains`."
}
