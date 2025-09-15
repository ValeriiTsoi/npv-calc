variable "namespace" {
  type    = string
  default = "npv"
}

variable "docker_host_ip" {
  type = string
}

variable "postgres_password" {
  type      = string
  default   = "npvpass"
  sensitive = true
}

variable "postgres_user" {
  type    = string
  default = "npvuser"
}

variable "postgres_db" {
  type    = string
  default = "npvdb"
}

variable "ldap_admin_password" {
  type      = string
  default   = "admin"
  sensitive = true
}

variable "ingress_npv_host" {
  type    = string
  default = "npv.local"
}

variable "ingress_ldapadmin_host" {
  type    = string
  default = "ldapadmin.local"
}
