# Step 3: Create the Ansible inventory for the cluster nodes.
#
# The source VM is not represented here; it has its own single-host inventory
# (inventory_source.ini, see source.tf) and is never a cluster member.

# ---------------------------------------------------------------------------
# Worker fingerprint
#
# A single hash over every worker attribute that should force the provisioning
# chain to re-run: instance identity, vmid, name and the DHCP management
# address. Adding, removing, replacing or re-addressing a worker all change
# this value, which is what starts the cascade below.
#
# Note that ipv4_addresses is unknown at plan time whenever a VM is being
# created or replaced. That makes the fingerprint unknown too, which is
# exactly when the chain should re-run, so the behaviour is correct.
# ---------------------------------------------------------------------------
locals {
  worker_fingerprint = sha1(jsonencode([
    for vm in proxmox_virtual_environment_vm.rbe_worker : [
      vm.id,
      vm.vm_id,
      vm.name,
      vm.ipv4_addresses[1][0],
    ]
  ]))

  # Bumping any Buildbarn image tag re-runs site.yml on its own, without
  # touching the earlier stages.
  bb_image_tags = join(",", [
    var.bb_storage_tag,
  ])
}

# ---------------------------------------------------------------------------
# Stage 0: let the qemu-guest-agent settle so ipv4_addresses is populated.
# ---------------------------------------------------------------------------
resource "time_sleep" "wait_for_agent_1" {
  create_duration = "30s"

  triggers = {
    workers = local.worker_fingerprint
  }

  # Implied by the fingerprint reference above, kept for readability.
  depends_on = [proxmox_virtual_environment_vm.rbe_worker]
}

# ---------------------------------------------------------------------------
# Inventory file. Re-renders on its own whenever a worker attribute changes,
# since the content is derived from those attributes.
# ---------------------------------------------------------------------------
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

  depends_on = [time_sleep.wait_for_agent_1]
}

# ---------------------------------------------------------------------------
# Stage 1: assign each worker its static 10.50.0.x IP (reachable via
# mgmt_ip / DHCP at this point).
#
# Keyed off the sleep's id, so it re-runs whenever the worker set changes, and
# off the rendered inventory, so a template edit alone also re-runs it.
# ---------------------------------------------------------------------------
resource "null_resource" "run_ansible_ip" {
  triggers = {
    wait      = time_sleep.wait_for_agent_1.id
    inventory = sha1(local_file.ansible_inventory.content)
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i ${path.module}/ansible/inventory/inventory.ini ${path.module}/ansible/setup_ens19.yml --forks 20"

    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
    }
  }
}

# ---------------------------------------------------------------------------
# Stage 2: hosts have just switched from mgmt_ip to static_ip and need a
# moment to come back up on the new address.
# ---------------------------------------------------------------------------
resource "time_sleep" "wait_for_agent_2" {
  create_duration = "30s"

  triggers = {
    ip_run = null_resource.run_ansible_ip.id
  }
}

# ---------------------------------------------------------------------------
# Stage 3: deploy Buildbarn (firewall + storage/scheduler/browser on
# rbe_master, firewall + worker/runner on rbe_workers). The same tags that
# were pre-pulled onto the golden image are passed here, so every container
# starts from an image that is already cached locally.
# ---------------------------------------------------------------------------
resource "null_resource" "run_ansible_buildbarn" {
  triggers = {
    wait = time_sleep.wait_for_agent_2.id
    tags = local.bb_image_tags
  }

  provisioner "local-exec" {
    command = <<-EOT
      sleep 15
      ansible-playbook -vvv -i ${path.module}/ansible/inventory/inventory.ini ${path.module}/ansible/site.yml \
        --forks 20 \
        --extra-vars "bb_storage_tag=${var.bb_storage_tag}" \
    EOT

    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
    }
  }
}
