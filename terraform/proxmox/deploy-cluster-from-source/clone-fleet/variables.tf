variable "vms" {
  description = "VMs to create. List position sets the VMID and new IP."
  type = list(object({
    node = string # Proxmox node to launch on
    cpus = number
    ram  = number # MB
  }))
}

variable "name_prefix" {
  type        = string
  default     = "vm"
  description = "VMs are named <prefix>-1, <prefix>-2, ..."
}

variable "template_vm_id" {
  type        = number
  description = "ID of the template to clone"
}

variable "template_node" {
  type        = string
  description = "Node the template lives on"
}

variable "vm_id_start" {
  type        = number
  description = "VMID of the first VM, the rest count up from it (1600, 1601, ...)"
}

variable "ip_network" {
  type        = string
  description = "Network the new IPs are taken from, e.g. 10.0.0.0"
}

variable "ip_netmask" {
  type        = string
  description = "Netmask of that network, e.g. 255.255.0.0"
}

variable "interface" {
  type        = string
  default     = "ens18"
  description = "Guest interface whose address is read now and changed later"
}

variable "inventory_dir" {
  type        = string
  default     = "inventory"
  description = "Where inventory_current.ini and inventory_new.ini are written"
}

variable "vm_ssh_user" {
  type        = string
  description = "SSH username for the VMs"
}

variable "vm_ssh_password" {
  type        = string
  description = "SSH password for the VMs"
  sensitive   = true
}
