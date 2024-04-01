resource "azurerm_resource_group" "exaRG" {
  name     = "InfraRG"
  location = "central US"
}

resource "azurerm_virtual_network" "exaVnet" {
    depends_on = [ azurerm_resource_group.exaRG ]
  name                = "InfraVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.exaRG.location
  resource_group_name = azurerm_resource_group.exaRG.name
}

resource "azurerm_subnet" "exaSubnet" {
    depends_on = [ azurerm_virtual_network.exaVnet ]
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.exaRG.name
  virtual_network_name = azurerm_virtual_network.exaVnet.name
  address_prefixes     = ["10.0.2.0/24"]
  
}

resource "azurerm_network_interface" "exanetwork" {
  name                = "NIC01"
  location            = azurerm_resource_group.exaRG.location
  resource_group_name = azurerm_resource_group.exaRG.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.exaSubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.exapip.id
  }
}
resource "azurerm_network_security_group" "exaNSG" {
  name                = "CloudInfraNSG"
  location            = azurerm_resource_group.exaRG.location
  resource_group_name = azurerm_resource_group.exaRG.name

  security_rule {
    name                       = "rdp_allow"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}
resource "azurerm_network_interface_security_group_association" "exaassociation" {
    depends_on = [ azurerm_network_security_group.exaNSG ]
  network_interface_id      = azurerm_network_interface.exanetwork.id
  network_security_group_id = azurerm_network_security_group.exaNSG.id
  
}
resource "azurerm_public_ip" "exapip" {
    depends_on = [ azurerm_resource_group.exaRG ]
  name                = "infravmpip01"
  location            = azurerm_resource_group.exaRG.location
  resource_group_name = azurerm_resource_group.exaRG.name
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}
resource "azurerm_linux_virtual_machine" "exaVM" {
    depends_on = [ azurerm_resource_group.exaRG, azurerm_network_interface.exanetwork ]
  name                            = "infravm"
  location                        = azurerm_resource_group.exaRG.location
  resource_group_name             = azurerm_resource_group.exaRG.name
  size                            = "Standard_F2"
  admin_username                  = "superuser"
  admin_password                  = "India@123"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.exanetwork.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

