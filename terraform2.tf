#Configure the Microsoft Azure Provider
provider "azurerm" {
    subscription_id = "subs-id"
    client_id       = "cl-id"
    client_secret   = "cs-id"
    tenant_id       = "tt-id"
}

#define variable 
variable "prefix" {
  default = "2azuredemo"
}
# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "main" {
  name     = "AzureDemoOct19"
  location = "centralus"
}

# Create virtual network
resource "azurerm_virtual_network" "main" {
    name                = "${var.prefix}-vNet"
    address_space       = ["10.0.0.0/16"]
    location            = "${azurerm_resource_group.main.location}"
    resource_group_name = "${azurerm_resource_group.main.name}"

 }

# Create subnet
resource "azurerm_subnet" "main" {
    name                 = "${var.prefix}-Subnet"
    resource_group_name  = "${azurerm_resource_group.main.name}"
    virtual_network_name = "${azurerm_virtual_network.main.name}"
    address_prefix       = "10.0.2.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "main" {
    name                         = "${var.prefix}-myPublicIP"
    location                     = "${azurerm_resource_group.main.location}"
    resource_group_name          = "${azurerm_resource_group.main.name}"
    allocation_method            = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "main" {
    name                = "${var.prefix}-nsg"
    location            = "${azurerm_resource_group.main.location}"
    resource_group_name =  "${azurerm_resource_group.main.name}"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

#Associates a Network Security Group with a Subnet within a Virtual Network.

resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = "${azurerm_subnet.main.id}"
  network_security_group_id = "${azurerm_network_security_group.main.id}"
}

# Create network interface
resource "azurerm_network_interface" "main" {
    name                      = "${var.prefix}-nic"
    location                  = "${azurerm_resource_group.main.location}"
    resource_group_name       = "${azurerm_resource_group.main.name}"
    

    ip_configuration {
        name                          = "${var.prefix}-myNicConfiguration"
        subnet_id                     = "${azurerm_subnet.main.id}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${azurerm_public_ip.main.id}"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "main" {
    name                  = "${var.prefix}-VM"
    location              = "${azurerm_resource_group.main.location}"
    resource_group_name   = "${azurerm_resource_group.main.name}"
    network_interface_ids = ["${azurerm_network_interface.main.id}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "${var.prefix}-myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
    computer_name  = "hostname"
    admin_username = "${var.prefix}admin"
    admin_password = "${var.prefix}-pass"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
}

