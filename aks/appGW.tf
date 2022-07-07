################################
##### Module of AppGateway #####
################################

module "application_landing_gateway_public_ip" {
  source = "../shared-terraform-modules/azurerm-public-ip"

  baseName          = "${var.prefix}-wvd-landing"
  environment       = var.environment
  location          = var.location
  resourceGroupName  = data.azurerm_resource_group.appgatewayrg.name
  //resourceGroupName = "phx-parent-rg-dev"
}

module "parent_app_gateway" {
  source = "../shared-terraform-modules/azurerm-application-gateway"

  baseName          = "${var.prefix}-wvd-landing"
  location          = var.location
  environment       = var.environment
  resourceGroupName =data.azurerm_resource_group.appgatewayrg.name
  zones             = var.zones
  sku_name          = var.sku_name
  sku_tier          = var.sku_tier
  capacityMin       = var.capacityMin
  capacityMax       = var.capacityMax

  subnet_id          = data.azurerm_subnet.appgatewaysubnet.id
  publicIp          = module.application_landing_gateway_public_ip.id
  //frontend_port_name              = "${var.prefix}-agw-port-${var.environment}"
  frontend_port_name              = var.frontend_port_name
  backend_address_pool_name       = var.backend_address_pool_name_list_values
  //backend_address_pool_name       = "${var.prefix}-wvd-ag-pool-${var.environment}"
  listener_name                   = var.http_listener_name_list_values
  //listener_name                   = ${var.prefix}-wvd-ag-https-listener-${var.environment}"
  //frontend_ip_configuration_name  = "${var.prefix}-agw-ip-config"
  frontend_ip_configuration_name  = var.frontend_ip_configuration_name
  http_setting_name               = "wvd-ag-backend"
  request_routing_rule_name       = var.request_routing_rule_name_list_values
  //request_routing_rule_name       = "${var.prefix}-wvd-appGateway-rule-${var.environment}"
  sslCertName                     = var.ag_cert
  #sslCertName                     = azurerm_app_service_certificate.example.id
  sslCertSecret                   = var.sslCertSecret
  backendhttphostname             = var.backend_http_host_name_list_values
  noOfHttpListeners               = var.noOfHttpListeners
  prefix                          = var.prefix
  sslcertificatefilename          = var.sslppxcertificatefilename
}
