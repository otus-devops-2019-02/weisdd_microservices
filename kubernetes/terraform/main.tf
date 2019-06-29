terraform {
  required_version = ">=0.11,<0.12"
}

provider "google" {
  version = "2.0.0"
  project = "${var.project}"
  region  = "${var.region}"
}

resource "google_container_cluster" "cluster" {
  name                     = "${var.cluster_name}"
  zone                     = "${var.zone}"
  remove_default_node_pool = true
  initial_node_count       = 1

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

  //for hw kubernetes-5
  enable_legacy_abac = "${var.enable_legacy_abac}"
  monitoring_service = "none"
  logging_service = "none"
}

resource "google_container_node_pool" "node_pool_1" {
  cluster    = "${google_container_cluster.cluster.name}"
  name       = "node-pool-1"
  node_count = "${var.node_count_1}"
  zone       = "${var.zone}"

  node_config {
    preemptible  = "${var.is_preemptible}"
    machine_type = "${var.machine_type_1}"
  }
}

resource "google_container_node_pool" "node_pool_2" {
  cluster    = "${google_container_cluster.cluster.name}"
  name       = "node-pool-2"
  node_count = "${var.node_count_2}"
  zone       = "${var.zone}"

  node_config {
    preemptible  = "${var.is_preemptible}"
    machine_type = "${var.machine_type_2}"
  }
}
