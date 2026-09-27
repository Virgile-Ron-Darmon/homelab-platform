





resource "local_file" "ansible_inventory" {
  filename = "${path.module}/ansible/inventory/inventory.ini"

  content = templatefile("${path.module}/ansible/inventory/inventory.tpl", {
    workers = [
      for idx, vm in proxmox_virtual_environment_vm.rbe_worker : {
        name      = vm.name
        mgmt_ip   = vm.ipv4_addresses[1][0]
        vmid      = vm.vm_id
        static_ip = "10.50.0.${vm.vm_id - var.template_vmid}" # linear scheme, scales from 1 to 254 max, make 10.50.x.x for further scaling
      }
    ]
    ssh_user     = var.vm_ssh_user
    ssh_password = var.vm_ssh_password
  })

  depends_on = [proxmox_virtual_environment_vm.template_source]
}