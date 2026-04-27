output "data_factories" {
  value       = module.data_factory
  description = "Map of Data Factory keys to their respective output objects from the AVM Data Factory module. Each output object includes all attributes defined in the AVM module's outputs (resource, resource_id, name, private_endpoints)."
}
