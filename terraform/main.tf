locals { name = "${var.prefix}-platform" }

resource "azurerm_resource_group" "rg" {
  name     = coalesce(var.resource_group, "${local.name}-rg")
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${local.name}-vnet"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_subnet" "aks" {
  name                 = "${local.name}-aks-snet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.aks_subnet_cidr]
}

resource "azurerm_subnet" "app" {
  name                 = "${local.name}-app-snet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.app_subnet_cidr]
  delegations {
    name = "delegation"
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "random_integer" "suffix" { min = 10000 max = 99999 }

resource "azurerm_container_registry" "acr" {
  name                = replace("${var.prefix}acr${random_integer.suffix.result}", "-", "")
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  admin_enabled       = false
  tags                = var.tags
}

resource "random_password" "grafana_admin" {
  length  = 20
  special = true
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${local.name}-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${var.prefix}-aks"
  kubernetes_version  = var.kubernetes_version
  private_cluster_enabled = var.enable_private_cluster

  default_node_pool {
    name                = "system"
    vm_size             = var.node_vm_size
    node_count          = var.node_count
    vnet_subnet_id      = azurerm_subnet.aks.id
    type                = "VirtualMachineScaleSets"
    enable_auto_scaling = true
    min_count           = 2
    max_count           = 5
    upgrade_settings { max_surge = "33%" }
  }

  identity { type = "SystemAssigned" }

  network_profile {
    network_plugin       = "azure"
    network_policy       = "azure"
    dns_service_ip       = "10.2.0.10"
    service_cidr         = "10.2.0.0/24"
    docker_bridge_cidr   = "172.17.0.1/16"
    outbound_type        = "loadBalancer"
  }

  workload_identity_enabled       = true
  oidc_issuer_enabled             = true
  role_based_access_control_enabled = true

  azure_active_directory_role_based_access_control {
    managed                = true
    admin_group_object_ids = []
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  tags = var.tags
}

resource "azurerm_role_assignment" "aks_acrpull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}