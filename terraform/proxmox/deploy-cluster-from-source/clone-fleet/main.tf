local{
  
}



resource "proxmox_virtual_environment_vm" "rbe_worker" {
  count     = length(local.rbe_workers)
  node_name = local.rbe_workers[count.index].node
  vm_id     = var.clone_vmid_start + count.index
  name      = "rbe-worker-${count.index + 1}"
  stop_on_destroy = true


  clone {
    # Destination is node_name above; this is where the *source* template
    # lives. Omitting it defaults to the destination node, which is why this
    # only ever worked on a single node before.
    node_name = var.target_node
    vm_id     = proxmox_virtual_environment_vm.template_source.vm_id
    full      = false # linked clone
  }

  agent {
    enabled = true
  }
    network_device {
    bridge = var.mgmt_bridge
    model  = var.mgmt_network_model
    mac_address = local.mgt_macs[count.index]
    vlan_id = 0
  }

  network_device {
    bridge      = var.cluster_bridge
    model       = var.cluster_network_model
    mac_address = local.worker_macs[count.index]
    vlan_id     = var.cluster_vlan_id
  }
  
  depends_on = []
}


resource "local_file" "ansible_inventory" {
  filename = "${path.module}/ansible/inventory/inventory.ini"

  content = templatefile("${path.module}/ansible/inventory/inventory.tpl", {
    workers = [
      for idx, vm in proxmox_virtual_environment_vm.rbe_worker : {
        name      = vm.name
        mgmt_ip   = vm.ipv4_addresses[1][0]
        vmid      = vm.vm_id
        static_ip = "10.50.0.${vm.vm_id - var.template_vm_id}" # linear scheme, scales from 1 to 254 max, make 10.50.x.x for further scaling
      }
    ]
    ssh_user     = var.vm_ssh_user
    ssh_password = var.vm_ssh_password
  })
}