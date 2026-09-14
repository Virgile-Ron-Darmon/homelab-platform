variable "pm_api_token_id" {
  type      = string
  sensitive = true
}

variable "pm_api_token_secret" {
  type      = string
  sensitive = true
}

variable "source_vm_id" {
  type = number
  description = "ID of the source vm"
}

variable "template_name" {
  type = string
  description = "ID of the template vm"
}

variable "template_node" {
  type = string
  description = "ID of the template vm"
}

variable "node_ip" {
  type = number
  description = "ip of the template node"
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