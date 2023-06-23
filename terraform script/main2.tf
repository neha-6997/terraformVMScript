# Define the resource group
resource "azurerm_resource_group" "neharg" {
  name     = "neharg"
  location = "North Europe"
}

# Define the virtual network
resource "azurerm_virtual_network" "vnet1" {
  name                = "VNet1"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.neharg.location
  resource_group_name = azurerm_resource_group.neharg.name
}

# Define the subnet
resource "azurerm_subnet" "subnet1" {
  name                 = "Subnet1"
  resource_group_name  = azurerm_resource_group.neharg.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.0.0/24"]
}

# Define the virtual machines
variable "vm_count" {
  default = 3
}

resource "azurerm_windows_virtual_machine" "nehavm1" {
  count                        = var.vm_count
  name                         = "VM00022${count.index}"
  resource_group_name          = azurerm_resource_group.neharg.name
  location                     = azurerm_resource_group.neharg.location
  size                         = "Standard_DS2_v2"
  admin_username               = "azureuser"
  admin_password               = "P@ssw0rd123"
  network_interface_ids        = [azurerm_network_interface.neha-nic[count.index].id]
  
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  boot_diagnostics {
    storage_uri = azurerm_storage_account.storageaccount7878.primary_blob_endpoint
  }
}

# Define the network interfaces
resource "azurerm_network_interface" "neha-nic" {
  count               = var.vm_count
  name                = "myNIC${count.index}"
  location            = azurerm_resource_group.neharg.location
  resource_group_name = azurerm_resource_group.neharg.name

  ip_configuration {
    name                          = "myNicConfiguration${count.index}"
    subnet_id                     = azurerm_subnet.neha-nic.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Define the storage account for boot diagnostics
resource "azurerm_storage_account" "storageaccount7878" {
  name                     = "mydiagstorage${random_string.random.result}"
  resource_group_name      = azurerm_resource_group.neharg.name
  location                 = azurerm_resource_group.neharg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Generate a random string
resource "random_string" "random" {
  length = 6
  special = false
}









