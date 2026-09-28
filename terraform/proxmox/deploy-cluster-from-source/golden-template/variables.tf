variable "source_vm_id" {
  type        = number
  description = "VMID of the VM to turn into a template"
}

variable "template_vm_id" {
  type        = number
  description = "VMID to give the template"
}

variable "template_node" {
  type        = string
  description = "Node the source VM and the template live on"
}

variable "template_name" {
  type        = string
  description = "Name to give the template"
}