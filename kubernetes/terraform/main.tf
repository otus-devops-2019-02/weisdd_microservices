terraform {
  required_version = ">=0.11,<0.12"
}

provider "google" {
  version = "2.0.0"
  project = "${var.project}"
  region  = "${var.region}"
}

resource "google_container_cluster" "cluster" {
  name               = "${var.cluster_name}"
  zone               = "${var.zone}"
  initial_node_count = "${var.initial_node_count}"

  node_config {
    preemptible  = "${var.is_preemptible}"
    machine_type = "${var.machine_type}"
  }

  addons_config {
    kubernetes_dashboard {
      disabled = false
    }

    network_policy_config {
      disabled = "${var.disable_network_policy_addon}"
    }
  }

  network_policy {
    enabled = "${var.enable_network_policy}"
  }

  //for hw kubernetes-4
  enable_legacy_abac = "${var.enable_legacy_abac}"
}
