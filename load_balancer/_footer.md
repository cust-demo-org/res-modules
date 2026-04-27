## Cross-Module References

This module's output (`load_balancers`) can be consumed by other modules in this repository. The `virtual_machine` module references load balancer backend pools via `network_interfaces.<nic_key>.ip_configurations.<ipconfig_key>.load_balancer_backend_pools.<pool_key>.load_balancer_key` and `backend_pool_key`.
