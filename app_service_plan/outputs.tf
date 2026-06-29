output "app_service_plans" {
  value       = module.app_service_plan
  description = "Map of App Service Plan keys to their AVM module objects (includes resource_id and name)."
}
