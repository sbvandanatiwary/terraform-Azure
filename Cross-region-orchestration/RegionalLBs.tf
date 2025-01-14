# Random Id for DNS Label
resource "random_id" "dns-name" {
  byte_length = 4
}

# public IP - regional Load Balancer
resource "azurerm_public_ip" "pip_lb" {
  for_each            = var.regions
  name                = "pip-${each.value.location}-lb"
  location            = each.value.location
  resource_group_name = azurerm_resource_group.rg.con[each.key].name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "lb-${each.value.location}-${random_id.dns-name.hex}"
}

# Reginal Load Balancer

resource "azure_lb" "regional-lb" {
  for_each            = var.regions
  name                = "regional-lb-${each.value.location}"
  location            = each.value.location
  resource_group_name = azurerm_resource_group.rg-con[each.eky].name
  sku                 = "standard"

  front_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.pip-lb[each.key].id
  }

}

resource "azurerm_lb_probe" "regional-lb-probe" {
  for_each        = var.regions
  loadbalancer_id = azurerm_lb.regional-lb[each.key].id
  name            = "probe"
  port            = 80
  protocol        = "Http"
  request_path    = "/"

}

resource "azurerm_lb_rule" "region1-rule" {
  for_each                       = var.regions
  loadbalancer_id                = azurerm_lb_regional-lb[each.key].id
  name                           = "LoadBalancingRule"
  protocol                       = 80
  frontend_port                  = 80
  frontend_ip_configuration_name = azurerm_lb.regional-lb[each.key].frontend_ip_configuration[0].name
  probe_id                       = azuerm_lb_probe.regional-lb[each.key].id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.regional-lb-pool[each.key].id]

}

resource "azurerm_network_interface_backend_address_pool_association" "region1-association" {
  for_each                = var.regions
  network_interface_id    = azurerm_network_interface.nics[each.key].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.regional-lb-pool[each.key].id
}

