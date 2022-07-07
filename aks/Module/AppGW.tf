module "common_tags" {
  source             = "../common/tags"
  environment        = var.environment
  name               = "applicationGateway"
  resourceGroupName  = var.resourceGroupName
  tagsIncludeVersion = var.tagsIncludeVersion
}

//TODO not completed
resource "azurerm_application_gateway" "resource" {
  name                = local.appGatewayName
  location            = var.location
  resource_group_name = var.resourceGroupName
  enable_http2        = true
  zones               = var.zones
  tags                = module.common_tags.mapOfTags

  sku {
    name = var.sku_name
    tier = var.sku_tier
  }

  autoscale_configuration {
    min_capacity = var.capacityMin
    max_capacity = var.capacityMax
  }

  waf_configuration {
    firewall_mode            = "Detection"
    rule_set_type            = "OWASP"
    rule_set_version         = "3.2"
    enabled                  = true
    max_request_body_size_kb = "128"
    file_upload_limit_mb     = "750"
    request_body_check       = true
   }

  #identity {
  # type         = "UserAssigned"
  # identity_ids = [var.userAssignedIdentity]
  #}

  gateway_ip_configuration {
    name      = "${var.baseName}-ip-configuration"
    subnet_id = var.subnet_id
  }


  ssl_certificate {
    name     = var.sslCertName
    //data     = filebase64("phoenix.optum.com.pfx")
    //data     = filebase64("sasviyadev.optum.com.pfx")
    data     = filebase64(var.sslcertificatefilename)
    password = var.sslCertSecret
  }


  //dynamic
  frontend_ip_configuration {
    //for_each = var.frontend_ip_configuration_name
    //content {
      name                 = "${var.frontend_ip_configuration_name}-public"
      //name                 = "${frontend_ip_configuration.value}-public"
      public_ip_address_id = var.publicIp
   // }
  }

  //frontend_port {
  //  name = "${var.frontend_port_name}-80"
  //  port = 80
  //}

//  dynamic
  frontend_port {
   // for_each = var.frontend_port_name
    //content {
      name = "${var.frontend_port_name}-443"
      //name = "${frontend_port.value}-443"
      port = 443
    //}
  }

  dynamic backend_address_pool {
    for_each = var.backend_address_pool_name
    content {
      name = "${var.prefix}-${backend_address_pool.value.name}-${var.environment}"
      fqdns = backend_address_pool.value.virtualMachineAddress
    }
  }

  dynamic backend_http_settings {
    for_each = var.backendhttphostname
    content {
      //name                  = var.http_setting_name
      name                  ="${var.prefix}-${backend_http_settings.value.backendhttpsettingname}-${var.environment}-https"
      cookie_based_affinity = "Enabled"
      port                  = 443
      protocol              = "Https"
      //host_name             = backend_http_settings.value
      host_name             = "${backend_http_settings.value.backendhostname}"
      request_timeout       = 120
    }
  }

  //http_listener {
  //  name                           = "${var.listener_name}-http"
  //  frontend_ip_configuration_name = "${var.frontend_ip_configuration_name}-public"
  //  frontend_port_name             = "${var.frontend_port_name}-80"
  //  protocol                       = "Http"
  //}

  dynamic http_listener {

    for_each                       = var.listener_name
    content {
    name                           = "${var.prefix}-${http_listener.value.listenername}-${var.environment}-https"
    //frontend_ip_configuration_name = "${var.prefix}-${http_listener.value.frontend_ip_configuration_name}-${var.environment}-public"
    //frontend_port_name             = "${var.prefix}-${http_listener.value.frontend_port_name}-${var.environment}-443"
    frontend_ip_configuration_name = "${var.frontend_ip_configuration_name}-public"
    frontend_port_name             = "${var.frontend_port_name}-443"
    protocol                       = "Https"
    require_sni                    = true
    host_name                      = "${http_listener.value.listenerhostname}"
    ssl_certificate_name           = var.sslCertName
  }
}
  dynamic request_routing_rule {

    for_each = var.request_routing_rule_name
    content {
      name                       = "${var.prefix}-${request_routing_rule.value.routingname}-${var.environment}-https"
      rule_type                  = "Basic"
      http_listener_name         = "${var.prefix}-${request_routing_rule.value.routing_listener_name}-${var.environment}-https"
      backend_address_pool_name  = "${var.prefix}-${request_routing_rule.value.routing_backend_address_pool_name}-${var.environment}"
      //backend_http_settings_name = var.http_setting_name
      backend_http_settings_name = "${var.prefix}-${request_routing_rule.value.routing_http_setting_name}-${var.environment}-https"
    }
  }
  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20170401S"
  }

  lifecycle {
    ignore_changes = [
      backend_address_pool,
      backend_http_settings,
      frontend_port,
      http_listener,
      probe,
      request_routing_rule,
      url_path_map,
      ssl_certificate,
      redirect_configuration,
      autoscale_configuration
    ]
  }
}
