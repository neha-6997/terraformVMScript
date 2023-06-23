resource "azurerm_resource_group" "rg23" {
  location = var.resource_group_location
  name     = "rg23"
}

# Create virtual network
resource "azurerm_virtual_network" "azvnet" {
  name                = "azvnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg23.location
  resource_group_name = azurerm_resource_group.rg23.name
}

# Create subnet
resource "azurerm_subnet" "my_subnet" {
  name                 = "mysubnet"
  resource_group_name  = azurerm_resource_group.rg23.name
  virtual_network_name = azurerm_virtual_network.azvnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "public_ip" {
  count = 3
  name                = "public-ip${count.index}"
  location            = azurerm_resource_group.rg23.location
  resource_group_name = azurerm_resource_group.rg23.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rules
resource "azurerm_network_security_group" "my_terraform_nsg" {
  name                = "vm-nsg"
  location            = azurerm_resource_group.rg23.location
  resource_group_name = azurerm_resource_group.rg23.name

  security_rule {
    name                       = "RDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "web"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "my_nic" {
  count = 3
  name                = "vm-nic${count.index}"
  location            = azurerm_resource_group.rg23.location
  resource_group_name = azurerm_resource_group.rg23.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.my_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip[count.index].id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "my_terraform_nsg" {
  count = 3
  network_interface_id      = azurerm_network_interface.my_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.my_terraform_nsg.id
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "my_storage_account" {
  name                     = "diag${random_id.random_id.hex}"
  location                 = azurerm_resource_group.rg23.location
  resource_group_name      = azurerm_resource_group.rg23.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}


# Create virtual machine
resource "azurerm_windows_virtual_machine" "vm1" {
  count = 3
  name                  = "vm0022${count.index}"
  admin_username        = "azureuser"
  admin_password        = random_password.password1.result
  location              = azurerm_resource_group.rg23.location
  resource_group_name   = azurerm_resource_group.rg23.name
  network_interface_ids = [azurerm_network_interface.my_nic[count.index].id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "myOsDisk${count.index}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }


  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.my_storage_account.primary_blob_endpoint
  }
}

# Install IIS web server to the virtual machine
resource "azurerm_virtual_machine_extension" "web_server_install" {
  count = 3
  name                       = "${random_pet.prefix.id}-wsi"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm1[count.index].id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.8"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "commandToExecute": "powershell -ExecutionPolicy Unrestricted Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature -IncludeManagementTools"
    }
  SETTINGS
}

# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg23.name
  }

  byte_length = 8
}

resource "random_password" "password1" {
  length      = 20
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
  special     = true
}

resource "random_pet" "prefix" {
  prefix = var.prefix
  length = 1
}
