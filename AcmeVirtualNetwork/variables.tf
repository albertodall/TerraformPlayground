variable "region_short" {
  description = "The short abbreviation for the Azure Region we're working in"
  type        = string
}

variable "project_name" {
  description = "The workload name"
  type        = string
}

variable "environment_name" {
  description = "The environment name"
  type        = string
}

variable "private_domain_name" {
  description = "The provate DNS domain name"
  type        = string
}

variable "vm_admin_username" {
  description = "Virtual Machine Administrator Account"
  type        = string
}

variable "vm_admin_password" {
  description = "Virtual Machine Administrator Password"
  type        = string
}

variable "sql_admin_username" {
  description = "Virtual Machine Administrator Account"
  type        = string
}

variable "sql_admin_password" {
  description = "Virtual Machine Administrator Password"
  type        = string
}
