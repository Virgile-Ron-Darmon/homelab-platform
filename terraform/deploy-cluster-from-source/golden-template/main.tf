resource "proxmox_virtual_environment_vm" "golden_template" {
  name      = var.template_name
  node_name = var.template_node
  node_ip   = var.node_ip
  vm_id     = var.template_vm_id

  clone {
    vm_id = var.source_vm_id
    full  = true
  }

  agent {
    enabled = true
  }

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
    template_name  = var.template_name
    source_ip    = proxmox_virtual_environment_vm.golden_template.ipv4_addresses[1][0]
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


resource "null_resource" "api_convert_to_template" {

  provisioner "local-exec" {
    command = <<-EOT
      ${path.module}/api_convert_to_template \
      ${var.pm_api_token_id} \
      ${var.pm_api_token_secret} \
      ${var.template_node} \
      ${var.node_ip} \
      ${var.template_vm_id} \
    EOT
  }
  depends_on = [null_resource.run_ansible_playbook]
}

