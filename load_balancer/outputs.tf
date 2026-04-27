output "load_balancers" {
  value       = module.load_balancer
  description = "Outputs the entire map of load balancer keys to their respective output objects from the AVM load balancer module. Each output object includes all attributes defined in the AVM module's outputs for load balancers."
}
