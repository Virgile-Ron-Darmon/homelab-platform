output "vms" {
  value = [
    for i, vm in proxmox_virtual_environment_vm.fleet : {
      name       = vm.name
      vm_id      = vm.vm_id
      node       = vm.node_name
      current_ip = local.current_ips[i]
      new_ip     = local.new_ips[i]
    }
  ]
}

output "inventory_current" {
  value = local_sensitive_file.inventory_current.filename
}

output "inventory_new" {
  value = local_sensitive_file.inventory_new.filename
}
