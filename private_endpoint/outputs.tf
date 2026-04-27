output "private_endpoints" {
  value       = module.private_endpoint
  description = "Map of private endpoint keys to their respective output objects from the AVM private endpoint module. Each output object includes all attributes defined in the AVM module's outputs (name, resource, resource_id)."
}
