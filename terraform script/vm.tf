resource "azurerm_resource_group" "rg0" {
    name     = "rg0"
    location = "westus"
  
}
resource "azurerm_virtual_network" "vnet1" {
    name                = "vnet1"
    address_space       = "10.0.0.0/16"
    resource_group_name = azurerm_resource_group.rg0.name
    location            = azurerm_resource_group.rg0.location
  
}
resource "azurerm_subnet" "sub1" {
    name                 = "sub1"
    resource_group_name  = azurerm_resource_group.rg0.name
    virtual_network_name = azurerm_virtual_network.vnet1.name
    address_prefixes     = "10.0.1.0/24"
  
}
resource "azurerm_subnet" "" {
  
}