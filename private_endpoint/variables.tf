variable "private_endpoints" {
  type = map(object({
    name                = string
    resource_group_key  = optional(string)
    resource_group_name = optional(string)
    location            = optional(string)
    enable_telemetry    = optional(bool)
    tags                = optional(map(string), {})

    network_interface_name = string

    network_configuration = object({
      subnet_resource_id = optional(string)
      vnet_key           = optional(string)
      subnet_key         = optional(string)
    })

    private_connection_resource_id = optional(string)

    subresource_names = optional(list(string))
    private_dns_zone = optional(object({
      resource_ids = optional(set(string))
      keys         = optional(set(string))
    }))
    private_service_connection_name = optional(string)
    private_dns_zone_group_name     = optional(string)

    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
      subresource_name   = string
      member_name        = optional(string, "default")
    })), {})

    application_security_group_association_ids = optional(set(string), [])

    lock = optional(object({
      kind = string
      name = optional(string)
    }))

    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = optional(string)
      managed_identity_key                   = optional(string)
      assign_to_caller                       = optional(bool, false)
      description                            = optional(string)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string)
      condition_version                      = optional(string)
      delegated_managed_identity_resource_id = optional(string)
      principal_type                         = optional(string)
    })), {})
  }))
  default     = {}
  description = <<-EOT
    A map of Azure Private Endpoints to create. Each private endpoint is deployed using the AVM `Azure/avm-res-network-privateendpoint/azurerm` module (v0.2.0).
    The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.

    - `name` - (Required) The name of the private endpoint. Changing this forces a new resource to be created.
    - `resource_group_key` - (Optional) **Pattern cross-reference**: the key of a resource group in the `resource_groups` variable. Resolved to the resource group name. At least one of `resource_group_key` or `resource_group_name` must be provided.
    - `resource_group_name` - (Optional) The name of the resource group to deploy the private endpoint into. Overrides `resource_group_key`. At least one of `resource_group_key` or `resource_group_name` must be provided.
    - `location` - (Optional) Azure region where the resource should be deployed. If null, the location will be inferred from the resource group location. Defaults to `var.location`.
    - `enable_telemetry` - (Optional) Override telemetry setting for this Private Endpoint. Defaults to `var.enable_telemetry`.
    - `tags` - (Optional) Tags merged with `var.tags`. Defaults to `{}`.
    - `network_interface_name` - (Required) The custom name of the network interface attached to the private endpoint. Changing this forces a new resource to be created.
    - `network_configuration` - (Required) Network placement for the private endpoint.
      - `subnet_resource_id` - (Optional) The resource ID of the subnet. Mutually exclusive with `vnet_key`/`subnet_key`.
      - `vnet_key` - (Optional) The key of the virtual network in the `virtual_networks` variable. Used with `subnet_key`.
      - `subnet_key` - (Optional) The key of the subnet within the virtual network identified by `vnet_key`.
    - `private_connection_resource_id` - (Optional) The ID of the Private Link Enabled Remote Resource which this Private Endpoint should be connected to. Mutually exclusive with `private_connection_resource_key`.
    - `subresource_names` - (Optional) A list of subresource names which the Private Endpoint is able to connect to (e.g., `["blob"]`, `["vault"]`, `["dataFactory"]`). See https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-overview#private-link-resource.
    - `private_service_connection_name` - (Optional) Specifies the Name of the Private Service Connection.
    - `private_dns_zone_group_name` - (Optional) Specifies the Name of the Private DNS Zone Group.
    - `private_dns_zone` - (Optional) Private DNS zone configuration for the endpoint.
      - `resource_ids` - (Optional) A set of Private DNS Zone resource IDs.
      - `keys` - (Optional) A set of keys from the `private_dns_zones` variable. Resolved to resource IDs and merged with `resource_ids`.
    - `ip_configurations` - (Optional) A map of IP configurations for the private endpoint. Defaults to `{}`.
      - `name` - (Required) The name of the IP configuration.
      - `private_ip_address` - (Required) Specifies the static IP address within the private endpoint's subnet to be used. Changing this forces a new resource to be created.
      - `subresource_name` - (Required) Specifies the subresource this IP address applies to.
      - `member_name` - (Optional) Specifies the member name this IP address applies to. Defaults to `"default"`.
    - `application_security_group_association_ids` - (Optional) A set of resource IDs of application security groups to associate. Defaults to `[]`.
    - `lock` - (Optional) Lock configuration. Defaults to `var.lock`.
      - `kind` - (Required) The type of lock. Possible values are `"CanNotDelete"` and `"ReadOnly"`.
      - `name` - (Optional) The name of the lock.
    - `role_assignments` - (Optional) A map of role assignments on the private endpoint. Defaults to `{}`.
      - `role_definition_id_or_name` - (Required) The ID or name of the role definition to assign to the principal.
      - `principal_id` - (Optional) The ID of the principal to assign the role to. Mutually exclusive with `managed_identity_key` and `assign_to_caller`.
      - `managed_identity_key` - (Optional) **Pattern cross-reference**: key of a managed identity in `var.managed_identities`. Resolved to the principal ID. Mutually exclusive with `principal_id`.
      - `assign_to_caller` - (Optional) If `true`, assigns the role to the current Terraform caller. Defaults to `false`. Mutually exclusive with `principal_id` and `managed_identity_key`.
      - `description` - (Optional) The description of the role assignment.
      - `skip_service_principal_aad_check` - (Optional) If true, skips the Azure Active Directory check for the service principal. Defaults to `false`.
      - `condition` - (Optional) The condition which will be used to scope the role assignment.
      - `condition_version` - (Optional) The version of the condition syntax. Valid values are `"2.0"`.
      - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Used in cross-tenant scenarios.
      - `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`.
  EOT
}

variable "location" {
  description = "Default location fallback when a private endpoint does not set location."
  type        = string
}

variable "resource_groups" {
  description = "Resource groups output map from spoke module. Used to resolve resource_group_key to name."
  type        = any
  default     = {}
}

variable "enable_telemetry" {
  description = "Default telemetry flag fallback when a private endpoint does not set enable_telemetry."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Default tags to merge with per-resource tags."
  type        = map(string)
  default     = {}
}

variable "lock" {
  description = "Default lock fallback when a private endpoint does not set lock."
  type = object({
    kind = string
    name = optional(string)
  })
  default = null
}

variable "virtual_networks" {
  description = "Virtual networks output map from spoke module. Used to resolve vnet_key/subnet_key references to subnet resource IDs."
  type        = any
  default     = {}
}

variable "private_dns_zone_resource_ids" {
  description = "Private DNS Zone resource IDs output map from spoke module. Used to resolve private_dns_zone resource IDs in private endpoints."
  type        = any
  default     = {}
}

variable "managed_identities" {
  description = "Managed identities output map from spoke module. Used to resolve role assignment principal IDs."
  type        = any
  default     = {}
}