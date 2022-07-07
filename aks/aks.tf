resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  dns_prefix          = var.cluster_dns_name
  # node_resource_group = "${data.azurerm_resource_group.rg.name}-aks"
  kubernetes_version  = var.kubernetes_version
  api_server_authorized_ip_ranges = var.api_auth_ips

  default_node_pool {
    availability_zones    = [1, 2, 3]
    enable_auto_scaling   = true
    max_count             = 3
    min_count             = 1
    name                  = "system"
    orchestrator_version  = var.kubernetes_version
    os_disk_size_gb       = 1024
    vm_size               = "Standard_DS2_v2"
    type                  = "VirtualMachineScaleSets"
    vnet_subnet_id        = data.azurerm_subnet.subnet.id
    enable_node_public_ip = false
    max_pods              = 250
  }

  addon_profile {
    azure_policy { enabled = true }
    kube_dashboard {
      enabled = true
    }
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.workspace.id
    }
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
    network_policy    = "calico"
  }

  role_based_access_control {
    enabled = true
    azure_active_directory {
      managed                = true
      admin_group_object_ids = [data.azuread_group.aks_admin_group.object_id]
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "airflow" {
  availability_zones    = [1, 2, 3]
  enable_auto_scaling   = true
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  min_count             = var.min_userpool_node_count
  max_count             = var.max_userpool_node_count
  name                  = "user"
  orchestrator_version  = var.kubernetes_version
  os_disk_size_gb       = 1024
  vm_size               = "Standard_DS2_v2"
  vnet_subnet_id        = data.azurerm_subnet.subnet.id
}

resource "azurerm_role_assignment" "aks" {
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = azurerm_kubernetes_cluster.aks.addon_profile[0].oms_agent[0].oms_agent_identity[0].object_id
}

resource "azurerm_role_assignment" "aks_subnet" {
  scope                = data.azurerm_subnet.subnet.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.identity.0.principal_id
}

resource "azurerm_role_assignment" "vm_contributor" {
  scope                = data.azurerm_resource_group.aks_node_rg.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity.0.object_id
}

resource "azurerm_role_assignment" "all_mi_operator" {
  scope                = data.azurerm_resource_group.aks_node_rg.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity.0.object_id
}

resource "azurerm_role_assignment" "rg_all_mi_operator" {
  scope                = data.azurerm_resource_group.rg.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity.0.object_id
  depends_on = [
    azurerm_kubernetes_cluster.aks
  ]
}

resource "azurerm_role_assignment" "mi_operator" {
  scope                = azurerm_user_assigned_identity.managed_identity.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity.0.object_id
}

resource "azurerm_role_assignment" "aks_acr" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity.0.object_id
}

data "azurerm_resource_group" "aks_node_rg" {
  name = azurerm_kubernetes_cluster.aks.node_resource_group
}
