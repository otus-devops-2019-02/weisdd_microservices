variable "project" {
  description = "Project ID"
}

variable "region" {
  description = "Region"
  default     = "europe-west-1"
}

variable "cluster_name" {
  default = "default-cluster-1"
}

variable "zone" {
  description = "Zone"
  default     = "europe-west1-b"
}

variable "initial_node_count" {
  default = 2
}

variable "disk_size" {
  default = 20
}

variable "machine_type" {
  default = "n1-standard-1"
}

variable "is_preemptible" {
  default = "true"
}

variable "disable_network_policy_addon" {
  default = "true"
}

variable "enable_network_policy" {
  default = "false"
}

variable "enable_legacy_abac" {
  default = "false"
}
