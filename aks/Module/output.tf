output "id" {
  value = azurerm_application_gateway.resource.id
}

output "moduleDependsOn" {
  depends_on = [
    azurerm_application_gateway.resource
  ]
  value      = [
    azurerm_application_gateway.resource.id
  ]
}
