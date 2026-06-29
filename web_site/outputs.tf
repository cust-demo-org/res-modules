output "web_sites" {
  value       = module.web_site
  description = "Map of App Service keys to their AVM module objects (includes resource_id, resource, name, resource_uri, identity_principal_id, private_endpoints, deployment_slots, and other module outputs)."
}
