variable "source_vm_id" {
  type = number
  description = "ID of the source vm"
}

variable "template_name" {
  type = number
  description = "ID of the template vm"
}

variable "template_node" {
  type = number
  description = "ID of the template vm"
}

variable "template_vm_id" {
  type = number
  description = "ID of the template vm"
}

variable "vm_ssh_user" {
  type = string
  description = "SSH username for the source vm"
}

variable "vm_ssh_password" {
  type = string
  description = "SSH password for the source vm"
}

variable "playbook_path" {
  type = string
  default = ""
  description = "path to an ansible playbook to run on the template"
}