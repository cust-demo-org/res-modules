output "application_insights" {
  value       = module.application_insights
  description = "Map of Application Insights keys to their AVM module objects (includes resource_id, resource, name, app_id, connection_string, instrumentation_key, and other module outputs)."
}
