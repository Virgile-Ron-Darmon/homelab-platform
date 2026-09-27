# Step 1: full clone of the source VM, converted straight to a template.
#
# The clone is taken only after null_resource.prewarm_source_images has
# finished pulling every Buildbarn image onto source_vm_id, so the template's
# disk already contains them. Nothing needs to boot or be provisioned here,
# which is why template = true is safe to set at creation time.
resource "proxmox_virtual_environment_vm" "template_source" {
  name      = var.template_name
  node_name = var.target_node
  vm_id     = var.template_vmid

  clone {
    vm_id = var.source_vm_id
    full  = true
  }

  agent {
    enabled = true
  }

  # Convert this VM into a template once created
  template = true

  lifecycle {
    ignore_changes = [
      network_device,
      disk,
    ]
  }

  depends_on = [null_resource.prewarm_source_images]
}

locals {
  # One entry per VM, expanded from the per-node counts. Terraform walks maps
  # in lexicographic key order, so this runs local1's VMs, then local2's, and
  # so on.
  #
  # Position in this list is the only thing that determines a VM's VMID, and
  # therefore (via configure.tf) its static IP. Node placement rides along and
  # feeds neither, which is what keeps the existing sequential addressing
  # scheme intact while the fleet spreads across nodes.
  rbe_workers = flatten([
    for node, worker_count in var.rbe_nodes : [
      for i in range(worker_count) : { node = node }
    ]
  ])
}

# Step 2: linked clones from the template, spread across the nodes named in
# rbe_nodes. The template stays put on var.target_node; because it lives on
# Ceph, any node can clone from it.
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

  depends_on = [proxmox_virtual_environment_vm.template_source]
}
