output "communication_services" {
  value       = azapi_resource.communication_service
  description = "Map of communication service keys to their azapi_resource objects."
}
