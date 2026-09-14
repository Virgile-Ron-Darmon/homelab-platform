resource "proxmox_virtual_environment_vm" "golden_template" {
  name      = var.template_name
  node_name = var.template_node
  vm_id     = var.template_vm_id

  clone {
    vm_id = var.source_vm_id
    full  = true
  }

  agent {
    enabled = true
  }

  # Convert this VM into a template once created
  #template = true

  lifecycle {
    ignore_changes = [
      network_device,
      disk,
      template,
    ]
  }
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/inventory_source.ini"

  content = templatefile("${path.module}/inventory_source.tpl", {
    template_name  = template_name
    source_ip    = proxmox_virtual_environment_vm.golden_template.ipv4_addresses
    ssh_user     = var.vm_ssh_user
    ssh_password = var.vm_ssh_password
  })
  depends_on = [proxmox_virtual_environment_vm.golden_template]
}

resource "null_resource" "run_ansible_playbook" {
  triggers = {
    inventory = local_file.ansible_inventory.content
  }
  provisioner "local-exec" {
    command = var.playbook_path

    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
    }
  }
  depends_on = [local_file.ansible_inventory]
}

