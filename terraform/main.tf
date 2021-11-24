data "azurerm_resource_group" "rg" {
  name = "alejandro-valderrama"
}

## ===== CosmosDB-Mongo
resource "azurerm_cosmosdb_account" "mongoAccount" {
  name                = "tfex-cosmos-db-2468"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "MongoDB"

  enable_automatic_failover = true

  capabilities {
    name = "EnableAggregationPipeline"
  }

  capabilities {
    name = "mongoEnableDocLevelTTL"
  }

  capabilities {
    name = "MongoDBv3.4"
  }

  capabilities {
    name = "EnableMongo"
  }

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 10
    max_staleness_prefix    = 200
  }

  geo_location {
    location          = data.azurerm_resource_group.rg.location
    failover_priority = 0
  }
}

## ===== RabbitMQ - VM

resource "azurerm_cosmosdb_mongo_database" "db" {
  name                = "tfex-cosmos-mongo-db"
  resource_group_name = data.azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.mongoAccount.name
  throughput          = 400
}

resource "azurerm_virtual_network" "vnet" {
  name                = "rabbit-network"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "internal"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "rabbitmw-nsg"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  security_rule {
    name                       = "port-5672"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5672"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "port-15672"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "15672"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AccountService"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AuthService"
    priority                   = 104
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "ConfigService"
    priority                   = 105
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8888"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "GatewayService"
    priority                   = 106
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "NotificationService"
    priority                   = 107
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Registry"
    priority                   = 108
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8761"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "StatisticsService"
    priority                   = 109
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "7000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "public-ip-vm" {
  name                = "Public-Ip-VM"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

resource "azurerm_network_interface" "nic" {
  name                = "rabbit-nic"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public-ip-vm.id
  }
}

resource "azurerm_network_interface_security_group_association" "nic-nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_linux_virtual_machine" "rabbitmq_vm" {
  name                = "rabbitmq"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  size                = "Standard_F2"
  admin_username      = "rabbit-vm-admin"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_ssh_key {
    username   = "rabbit-vm-admin"
    public_key = file("~/.ssh/id_rsa_projInt.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Bitnami"
    offer     = "rabbitmq"
    sku       = "rabbitmq"
    version   = "3.9.2111112035"
  }

  plan {
    name      = "rabbitmq"
    publisher = "bitnami"
    product   = "rabbitmq"
  }
}

## ===== Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "containerRegistryPiggy"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  sku                 = "Premium"
  admin_enabled       = false
}

## ===== K8s cluster
resource "azurerm_kubernetes_cluster" "k8s_piggy" {
  name                = "piggymetrics-aks1"
  location            = "Central US"
  resource_group_name = data.azurerm_resource_group.rg.name
  dns_prefix          = "piggymetrics-dns"

  default_node_pool {
    name       = "default"
    node_count = 5
    vm_size    = "Standard_DS3_v2" 
    #D2
  }

  identity {
    type = "SystemAssigned"
  }
}

output "client_certificate" {
  value = azurerm_kubernetes_cluster.k8s_piggy.kube_config.0.client_certificate
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.k8s_piggy.kube_config_raw
  sensitive = true
}

resource "azurerm_role_assignment" "k8s_to_acr" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.k8s_piggy.kubelet_identity[0].object_id
}