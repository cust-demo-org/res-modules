output "api_management_services" {
  value       = module.api_management_service
  description = "Map of API Management service keys to their AVM module objects. Each object includes resource_id, name, the raw resource, identity, gateway/portal URLs, and the nested apis, backends, products, subscriptions, named_values, private_endpoints, and other module outputs."
}
