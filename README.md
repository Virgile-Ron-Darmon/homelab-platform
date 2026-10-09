# homelab-platform

Reusable Terraform modules, Ansible roles and scripts for building VMs and Kubernetes on my Proxmox homelab.

**Status:** Active

## Contents

- [Overview](#overview)
- [How it works](#how-it-works)
- [Requirements](#requirements)
- [Setup](#setup)
- [Usage](#usage)
- [Project structure](#project-structure)
- [Notes](#notes)
- [License](#license)

## Overview

This repo is a library: it holds no environment of its own. Deployment repos pull its components in by Git URL and supply the configuration.

Used by:

- [homelab-k8s-deploy](https://github.com/Virgile-Ron-Darmon/homelab-k8s-deploy): kubeadm Kubernetes cluster on Proxmox

Components:

| Component | Kind | Description |
|---|---|---|
| [golden-template](terraform/proxmox/deploy-cluster-from-source/golden-template/README.md) | Terraform module | Turn a prepared VM into a Proxmox template |
| [clone-fleet](terraform/proxmox/deploy-cluster-from-source/clone-fleet/README.md) | Terraform module | Clone VMs from a template and write Ansible inventories |
| [golden-template-WIP](terraform/proxmox/deploy-cluster-from-source/golden-template-WIP/README.md) | Terraform module | Experimental template flow (not used yet) |
| [apt_install](ansible/roles/apt/apt_install/README.md) | Ansible role | Install packages |
| [apt_update_upgrade_all](ansible/roles/apt/apt_update_upgrade_all/README.md) | Ansible role | Upgrade everything, optionally reboot |
| [apt_install_pin](ansible/roles/apt/apt_install_pin/README.md) | Ansible role | Install packages at one shared version and hold them |
| [conf_interface](ansible/roles/network/conf_interface/README.md) | Ansible role | Move a host from DHCP to a static IP |
| conf_interface_vlan | Ansible role | Add a tagged VLAN subinterface with a static address |
| system/identity | Ansible role | Set the hostname and regenerate a cloned machine-id once |
| pki/local_ca | Ansible role | Create or reuse a self-signed CA on the controller |
| pki/issue_cert | Ansible role | Issue a TLS server certificate from that CA |
| storage/nfs_server | Ansible role | Share a folder over NFS with a list of clients |
| registry/distribution | Ansible role | Configure Debian's docker-registry package with TLS and basic auth |
| [k8s/setup/common](ansible/roles/k8s/setup/common/README.md) | Ansible role | Prepare any Kubernetes node, optionally trusting an extra CA |
| [k8s/setup/master](ansible/roles/k8s/setup/master/README.md) | Ansible role | Build the control plane |
| [k8s/setup/worker](ansible/roles/k8s/setup/worker/README.md) | Ansible role | Join a worker |
| [k8s/setup/helm](ansible/roles/k8s/setup/helm/README.md) | Ansible role | Install Helm pinned to one minor version |
| [kubectl_apply_daemonset](ansible/roles/k8s/operation/kubectl_apply_daemonset/README.md) | Ansible role | Apply a manifest and wait for its DaemonSet |
| [install_and_pin.sh](bash/README.md) | Bash script | Shell version of `apt_install_pin` |

## How it works

A typical deployment chains the components like this:

1. `golden-template` turns a prepared VM into a template
2. `clone-fleet` clones VMs from it and writes a DHCP inventory and a static inventory
3. `conf_interface` runs against the DHCP inventory and moves each VM to its static IP
4. Everything else runs against the static inventory, for example the `k8s/setup` roles

## Requirements

- Terraform with the [bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox/latest) provider, configured by the caller
- Ansible, plus the `community.general` collection for some roles and `community.crypto` for the `pki` roles
- Target VMs running Debian with `ifupdown` networking and apt

Each component README lists its own requirements.

## Setup

Nothing to install. Reference components from a deployment repo, ideally at a pinned ref.

## Usage

### Terraform modules

```hcl
module "workers" {
  source = "git::https://github.com/Virgile-Ron-Darmon/homelab-platform.git//terraform/proxmox/deploy-cluster-from-source/clone-fleet?ref=main"
  # inputs
}
```

### Ansible roles

Roles are included by path rather than installed from Galaxy. Clone the repo into the playbook's `roles/` folder, then include roles from it:

```yaml
- name: Fetch homelab-platform
  hosts: localhost
  connection: local
  gather_facts: false
  tasks:
    - ansible.builtin.git:
        repo: https://github.com/Virgile-Ron-Darmon/homelab-platform.git
        version: main
        dest: "{{ playbook_dir }}/roles/homelab-platform"
        depth: 1
        force: true

- name: Prepare nodes
  hosts: all
  become: true
  vars:
    platform_roles: "{{ playbook_dir }}/roles/homelab-platform/ansible/roles"
  tasks:
    - ansible.builtin.include_role:
        name: "{{ platform_roles }}/k8s/setup/common"
```

Roles that include other roles expect `platform_roles` to point at `homelab-platform/ansible/roles`.

## Project structure

```
terraform/proxmox/deploy-cluster-from-source/
  golden-template/          Template from a prepared VM
  clone-fleet/              VM fleet plus inventories
  golden-template-WIP/      Experimental template flow
ansible/roles/
  apt/                      Package install, upgrade, pinning
  network/                  DHCP to static IP, VLAN subinterfaces
  system/                   Hostname and machine-id
  pki/                      Self-signed CA and certificates
  storage/                  NFS server
  registry/                 Container image registry
  k8s/setup/                Node, control plane, worker, Helm
  k8s/operation/            Day 2 operations
  .base/                    Skeleton for new roles
bash/
  install_and_pin.sh        Install packages at one version and hold them
```

## Notes

- Consumers that reference `main` pick up every change on the next run. Pin a tag for reproducible deployments.

## License

Not licensed yet.
