terraform {
  required_providers {
    proxmox = { source = "bpg/proxmox" }
  }
}

resource "proxmox_virtual_environment_vm" "golden_template" {
  name      = var.template_name
  node_name = var.template_node
  vm_id     = var.template_vm_id

  clone {
    vm_id = var.source_vm_id
    full  = true
  }
  template = true
  lifecycle {
    ignore_changes = [
      network_device,
      disk,
    ]
  }
}