output "resource_group"        { value = azurerm_resource_group.rg.name }
output "acr_name"              { value = azurerm_container_registry.acr.name }
output "aks_name"              { value = azurerm_kubernetes_cluster.aks.name }
output "kube_config"           { value = azurerm_kubernetes_cluster.aks.kube_config_raw  sensitive = true }
output "grafana_admin_user"    { value = "admin" }
output "grafana_admin_password"{ value = random_password.grafana_admin.result  sensitive = true }