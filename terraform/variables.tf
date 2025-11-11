variable "prefix"             { type = string  default = "demo" }
variable "location"           { type = string  default = "eastus" }
variable "resource_group"     { type = string  default = null }
variable "kubernetes_version" { type = string  default = null }
variable "node_count"         { type = number  default = 2 }
variable "node_vm_size"       { type = string  default = "Standard_DS3_v2" }
variable "enable_private_cluster" { type = bool default = false }
variable "admin_ip_cidr"      { type = string  default = "0.0.0.0/0" }
variable "vnet_cidr"          { type = string  default = "10.20.0.0/16" }
variable "aks_subnet_cidr"    { type = string  default = "10.20.1.0/24" }
variable "app_subnet_cidr"    { type = string  default = "10.20.2.0/24" }

variable "github_org"         { type = string  default = "your-org" }
variable "github_repo"        { type = string  default = "your-repo" }

variable "tags" {
  type = map(string)
  default = {
    environment = "prod-like"
    owner       = "platform-team"
  }
}