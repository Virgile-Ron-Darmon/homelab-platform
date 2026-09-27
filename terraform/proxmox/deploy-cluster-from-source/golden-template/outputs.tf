output "template_vm_id" {
  value = proxmox_virtual_environment_vm.golden_template.vm_id
}

output "template_node" {
  value = proxmox_virtual_environment_vm.golden_template.node_name
}