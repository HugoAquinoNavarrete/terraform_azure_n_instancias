# Script en Terraform para desplegar en Azure n instancias tipo ubuntu
# con acceso a internet que permiten tráfico SSH, HTTP y HTTPS
# Hugo Aquino
# Octubre 2020

# Antes de ejecutar este script, ejecuta "az login"
# Sigue las instrucciones del sitio "https://microsoft.com/devicelogin"
# e ingresar el código

# Después genera una llave ejecutando
# "ssh-keygen"
# Sálvalo en el directorio donde este este script <ruta_completa>/key
# Deja en blanco "passphrase"
# Cambia los permisos al archivo "chmod 400 key"

# Para conectarte con la VM una vez creada
# ssh -v -l azureuser -i key <ip_publica_instancia_creada>

# Para correr este script desde la consola:
# terraform apply -var "nombre_instancia=<nombre_recursos>" -var "cantidad_instancias=<n>"

# Para ajustar la cantidad de VMs a crear hay que cambiar el valor de la siguiente variable a la cantidad "default = n"

# Variable para saber cuantas instancias crear
variable cantidad_instancias {
  default = 1
}

# Para ajustar el nombre de los recursos hay que cambiar el valor de la siguiente variable al nombre que desees "default = <nombre>"
variable nombre_instancia {
  default = "prueba"
}

# Haremos despliegue en Azure
provider "azurerm" {
    version = "~>2.0"
    features {}
}

#provider "random" {
#    version = "=2.2.1"
#}

# Crear un Resource Group si no existe
resource "azurerm_resource_group" "rg" {
    name     = "${var.nombre_instancia}-rg"
    location = "eastus"

    tags = {
        #environment = "${var.nombre_instancia}" # Línea usada en versión 0.11.3
        environment = var.nombre_instancia
    }
}

# Crea red virtual
resource "azurerm_virtual_network" "vn" {
    name                = "${var.nombre_instancia}-vn"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    #resource_group_name = "${azurerm_resource_group.rg.name}" # Línea usada en versión 0.11.3
    resource_group_name = azurerm_resource_group.rg.name

    tags = {
        #environment = "${var.nombre_instancia}" # Línea usada en versiób 0.11.3
        environment = var.nombre_instancia
    }
}

# Crea las subredes
resource "azurerm_subnet" "subred" {
    #name                 = "${var.nombre_instancia}" # Línea usada en versión 0.11.3
    name                 = var.nombre_instancia
    #resource_group_name  = "${azurerm_resource_group.rg.name}" # Línea usada en versión 0.11.3
    resource_group_name  = azurerm_resource_group.rg.name
    #virtual_network_name = "${azurerm_virtual_network.vn.name}" # Línea usada en versiób 0.11.3
    virtual_network_name = azurerm_virtual_network.vn.name
    #address_prefix       = "10.0.1.0/24" # Línea usada en versió 0.11.3
    address_prefixes     = ["10.0.1.0/24"]
}

# Crea IPs públicas
resource "azurerm_public_ip" "ip-publica" {
    #count                        = "${var.cantidad_instancias}" # Línea usada en versiób 0.11.3
    count                        = var.cantidad_instancias
    name                         = "${var.nombre_instancia}-ip-publica-${count.index + 1}"
    location                     = "eastus"
    #resource_group_name          = "${azurerm_resource_group.rg.name}" # Línea usada en versión 0.11.3
    resource_group_name          = azurerm_resource_group.rg.name
    allocation_method            = "Dynamic"

    tags = {
        #environment = "${var.nombre_instancia}" # Línea usada en versión 0.11.3
        environment = var.nombre_instancia
    }
}

# Crea Security Group 
resource "azurerm_network_security_group" "security-group" {
    name                = "${var.nombre_instancia}-security-group"
    location            = "eastus"
    #resource_group_name = "${azurerm_resource_group.rg.name}" # Línea usada en versión 0.11.3
    resource_group_name = azurerm_resource_group.rg.name

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

    security_rule {
        name                       = "HTTP"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "HTTPS"
        priority                   = 1003
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        #environment = "${var.nombre_instancia}" # Línea usada en versión 0.11.3
        environment = var.nombre_instancia
    }
}


# Crea interfaz de red
resource "azurerm_network_interface" "interfaz-red" {
    #count                     = "${var.cantidad_instancias}" # Línea usada en versión 0.11.3
    count                     = var.cantidad_instancias
    name                      = "${var.nombre_instancia}-interfaz-red-${count.index + 1}"      
    location                  = "eastus"
    #resource_group_name       = "${azurerm_resource_group.rg.name}" # Línea usada en versión 0.11.3
    resource_group_name       = azurerm_resource_group.rg.name

    ip_configuration {
        name                          = "${var.nombre_instancia}-interfaz-configuracion-${count.index + 1}"
        #subnet_id                     = "${azurerm_subnet.subred.id}" # Línea usada en versión 0.11.3
        subnet_id                     = azurerm_subnet.subred.id
        private_ip_address_allocation = "Dynamic"
        #public_ip_address_id          = "${element(azurerm_public_ip.ip-publica.*.id, count.index)}" # Línea usada en versión 0.11.3
        public_ip_address_id          = element(azurerm_public_ip.ip-publica.*.id, count.index)
    }

    tags = {
        #environment = "${var.nombre_instancia}" # Línea usada en versión 0.11.3
         environment = var.nombre_instancia
    }
}

# Conecta el Security Group a la interfaz de red
resource "azurerm_network_interface_security_group_association" "security-group_asociacion" {
    #count                     = "${var.cantidad_instancias}" # Línea usada en versión 0.11.3
    count                     = var.cantidad_instancias
    #network_interface_id      = "${element(azurerm_network_interface.interfaz-red.*.id, count.index)}" # Línea usada en versión 0.11.3
    network_interface_id      = element(azurerm_network_interface.interfaz-red.*.id, count.index)
    #network_security_group_id = "${azurerm_network_security_group.security-group.id}" # Línea usada en versión 0.11.3
    network_security_group_id = azurerm_network_security_group.security-group.id
}

# Genera texto al azar para la cuenta de almacenamiento
#resource "random_id" "randomId" {
#    keepers = {
        # Genera un nuevo ID solo cuando un Resource Group es definido
#        resource_group = "${azurerm_resource_group.rg.name}"
#    }
#    byte_length = 8
#}


# Crea una cuenta de almacenamiento para diagnóstico en boot
resource "azurerm_storage_account" "cuenta-almacenamiento" {
    #name                        = "diag${random_id.randomId.hex}"
    name                        = "diag${var.nombre_instancia}"
    #resource_group_name         = "${azurerm_resource_group.rg.name}" # Línea usada en versión 0.11.3
    resource_group_name         = azurerm_resource_group.rg.name
    location                    = "eastus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        #environment = "${var.nombre_instancia}" # Línea usada en versión 0.11.3
        environment = var.nombre_instancia
    }
}

# Crea la máquina virtual
resource "azurerm_linux_virtual_machine" "virtual_machine" {
    #count                 = "${var.cantidad_instancias}" # Línea usada en versión 0.11.3
    count                 = var.cantidad_instancias
    name                  = "${var.nombre_instancia}-${count.index + 1}"
    location              = "eastus"
    #resource_group_name   = "${azurerm_resource_group.rg.name}" # Línea usada en versiób 0.11.3
    resource_group_name   = azurerm_resource_group.rg.name
    #network_interface_ids = ["${element(azurerm_network_interface.interfaz-red.*.id, count.index)}"] # Línea usada en versión 0.11.3
    network_interface_ids = [element(azurerm_network_interface.interfaz-red.*.id, count.index)]
    size                  = "Standard_DS1_v2"

    os_disk {
        name              = "${var.nombre_instancia}-disco-${count.index + 1}"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    #computer_name  = "${var.nombre_instancia}" # Línea usada en versión 0.11.3
    computer_name  = var.nombre_instancia
    admin_username = "azureuser"
    disable_password_authentication = true

    admin_ssh_key {
        username        = "azureuser"
	#public_key	= "${file("key.pub")}" # Línea usada en versión 0.11.3
        public_key      = file("key.pub")
    }

    boot_diagnostics {
        #storage_account_uri = "${azurerm_storage_account.cuenta-almacenamiento.primary_blob_endpoint}" # Línea usada en versión 0.11.3
         storage_account_uri = azurerm_storage_account.cuenta-almacenamiento.primary_blob_endpoint
    }

    tags = {
        #environment = "${var.nombre_instancia}" # Línea usada en versión 0.11.3
        environment = var.nombre_instancia
    }
}
