output "resource_group_name" {
  value = azurerm_resource_group.rg23.name
}

output "public_ip_address" {
  value = [for vm in azurerm_windows_virtual_machine.vm1 : vm.public_ip_address]
}

output "admin_password" {
  sensitive = true
  value     = [for vm in azurerm_windows_virtual_machine.vm1 : vm.admin_password]
}
