output "rbe_worker_ip" {
  value = proxmox_virtual_environment_vm.rbe_worker[*].ipv4_addresses
}