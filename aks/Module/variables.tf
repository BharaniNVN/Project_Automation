locals {
  appIdentityName = "${var.baseName}-ai-${var.environment}"
  appGatewayName = "${var.baseName}-ag-${var.environment}"
}

variable "baseName" {
  type        = string
  description = "name for the application gateway"
}

variable "location" {
  type        = string
  description = "location for the application gateway"
}

variable "prefix" {
  type        = string
  description = "Project Prefix as a variable"
}

variable "environment" {
  type        = string
  description = "environment for the application gateway"
}

variable "resourceGroupName" {
  type        = string
  description = "resource group for the application gateway"
}

variable "zones" {
  type        = list(string)
  description = "zones for the application gateway"
}

variable "sku_name" {
  type        = string
  description = "sky name for the application gateway"
}

variable "sku_tier" {
  type        = string
  description = "sku tier for the application gateway"
}
variable "capacityMin" {
  type        = number
  description = "capacity min for the application gateway"
}

variable "capacityMax" {
  type        = number
  description = "Capacity max  for the application gateway"
}

variable "subnet_id" {
  type        = string
  description = "subnet for the application gateway"
}

variable "publicIp" {
  type        = string
  description = "public ip for the application gateway"
}

variable "frontend_port_name" {
  type        = string
  description = "frontend port name for the application gateway"
}

variable "backend_address_pool_name" {
  type        = any
  description = "address pool name for the application gateway"
}

variable "listener_name" {
  type        = any
  description = "listener name for the application gateway"
}

variable "frontend_ip_configuration_name" {
  type        = string
  description = "front end ip config name for the application gateway"
}

variable "http_setting_name" {
  type        = string
  description = "http setting name for the application gateway"
}

variable "request_routing_rule_name" {
  type        = any
  description = "routing rule name for the application gateway"
}

variable "sslcertificatefilename" {
  type        = string
  description = "SSL certificate filename in the calling repository"
}

#variable "virtualMachineAddress" {
#  type        = list(string)
#  description = "virtual Machine Address for the application gateway"
#}

//variable "virtualMachineAddress" {
//  type        = list(string)
//  description = "virtual Machine Address for the application gateway"
//}

variable "sslCertName" {
  type        = string
  description = "sslCertName for the application gateway"
}

variable "sslCertSecret" {
  type        = string
  description = "sslCertSecret for the application gateway"
}

variable "backendhttphostname" {
  type        = any
  description = "Backend http host name for the application gateway"
}

variable "noOfHttpListeners" {
  type        = number
  description = "NumberOfListeners for the gateway"
}

#variable "userAssignedIdentity" {
#  type        = string
#  description = "userAssignedIdentity for the application gateway"
#}

variable "tagsIncludeVersion" {
  type        = bool
  description = "should resource be tagged with the module version"
  default     = true
}
