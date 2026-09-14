# Step 0: pre-warm the golden image.
#
# source_vm_id is a pre-existing VM that this Terraform does not manage; it is
# only ever read and cloned. Before deploy.tf full-clones it into the template,
# we pull every Buildbarn container image onto it, so the template and every
# linked clone downstream inherit a populated Docker image cache and never hit
# ghcr.io on first boot.
#
# Its IP is discovered the same way the workers' are: from the QEMU guest
# agent, second interface. Unlike the workers it gets no static 10.50.0.x
# address, since it is never a cluster member and only needs outbound access
# to the registry.

data "proxmox_virtual_environment_vm" "source" {
  node_name = var.target_node
  vm_id     = var.source_vm_id
}

resource "local_file" "source_inventory" {
  filename = "${path.module}/ansible/inventory/inventory_source.ini"

  content = templatefile("${path.module}/ansible/inventory/inventory_source.tpl", {
    source_name  = "rbe-source"
    source_ip    = var.source_vm_ip
    ssh_user     = var.vm_ssh_user
    ssh_password = var.vm_ssh_password
  })
}

resource "null_resource" "prewarm_source_images" {

  # Re-run whenever any tag changes, so the golden image can never carry a
  # stale image set relative to what the roles will later try to run.
  triggers = {
    source_vm_id         = var.source_vm_id
    bb_storage_tag       = var.bb_storage_tag

  }

  provisioner "local-exec" {
    command = <<-EOT
      ansible-playbook -i ${path.module}/ansible/inventory/inventory_source.ini ${path.module}/ansible/prewarm_images.yml \
        --extra-vars "bb_storage_tag=${var.bb_storage_tag}" \

    EOT
    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
    }
  }

  depends_on = [local_file.source_inventory]
}
