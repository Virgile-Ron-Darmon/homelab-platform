terraform {
  required_providers {
    proxmox = { source = "bpg/proxmox" }
  }
}

locals {
  # 255.255.0.0 -> 16
  mask_bits = { "255" = 8, "254" = 7, "252" = 6, "248" = 5, "240" = 4, "224" = 3, "192" = 2, "128" = 1, "0" = 0 }
  prefix    = sum([for o in split(".", var.ip_netmask) : local.mask_bits[o]])
  cidr      = "${var.ip_network}/${local.prefix}"

  new_ips = [for i in range(length(var.vms)) : cidrhost(local.cidr, i + 1)]

  # Address the guest agent reports on var.interface, looked up by name.
  current_ips = [
    for vm in proxmox_virtual_environment_vm.fleet :
    try(vm.ipv4_addresses[index(vm.network_interface_names, var.interface)][0], null)
  ]
}

resource "proxmox_virtual_environment_vm" "fleet" {
  count           = length(var.vms)
  name            = "${var.name_prefix}-${count.index + 1}"
  node_name       = var.vms[count.index].node
  vm_id           = var.vm_id_start + count.index
  stop_on_destroy = true

  clone {
    node_name = var.template_node
    vm_id     = var.template_vm_id
    full      = false
  }

  cpu {
    cores = var.vms[count.index].cpus
  }

  memory {
    dedicated = var.vms[count.index].ram
  }

  agent {
    enabled = true
  }
}

resource "local_sensitive_file" "inventory_current" {
  filename = "${var.inventory_dir}/${var.name_prefix}_inventory_DHCP.ini"
  content = templatefile("${path.module}/inventory.tpl", {
    hosts        = [for i, vm in proxmox_virtual_environment_vm.fleet : { name = vm.name, ip = local.current_ips[i], new_ip = local.new_ips[i] }]
    interface    = var.interface
    netmask      = var.network_netmask
    ssh_user     = var.vm_ssh_user
    ssh_password = var.vm_ssh_password
    target_gateway = var.gateway
    target_dns = var.dns_nameservers
  })

  lifecycle {
    precondition {
      condition     = alltrue([for ip in local.current_ips : ip != null])
      error_message = "The guest agent reported no IPv4 address on ${var.interface} for at least one VM."
    }
  }
}

resource "local_sensitive_file" "inventory_new" {
  filename = "${var.inventory_dir}/${var.name_prefix}_inventory_static.ini"
  content = templatefile("${path.module}/inventory.tpl", {
    hosts        = [for i, vm in proxmox_virtual_environment_vm.fleet : { name = vm.name, ip = local.new_ips[i], new_ip = local.new_ips[i] }]
    interface    = var.interface
    netmask      = var.network_netmask
    ssh_user     = var.vm_ssh_user
    ssh_password = var.vm_ssh_password
    target_gateway = var.gateway
    target_dns = var.dns_nameservers
  })
}
