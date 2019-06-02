terraform {
  # Версия terraform
  required_version = ">=0.11,<0.12"
}

provider "google" {
  # Версия провайдера
  version = "2.0.0"

  # ID проекта
  project = "${var.project}"
  region  = "${var.region}"
}

resource "google_compute_instance" "app" {
  count        = "${var.number_of_instances}"
  name         = "docker-host-${count.index}"
  machine_type = "g1-small"
  zone         = "${var.zone}"

  boot_disk {
    initialize_params {
      # Здесь можно передать либо имя семейства, либо полное имя
      image = "${var.app_disk_image}"
    }
  }

  metadata {
    # путь до публичного ключа
    # file считывает файл и вставляет в конфигурационный файл
    ssh-keys = "appuser:${file(var.public_key_path)}"
  }

  tags = ["docker-machine"]

  labels {
    ansible_group = "docker-host"
    env           = "${var.label_env}"
  }

  network_interface {
    # сеть, к которой присоединить данный интерфейс
    network = "default"

    # использовать ephemeral IP для доступа в Интернет
    access_config {
      nat_ip = "${element(google_compute_address.app_ip.*.address, count.index)}"
    }
  }

  # Параметры подключения провижионеров
  connection {
    type        = "ssh"
    user        = "appuser"
    agent       = false
    private_key = "${file(var.private_key_path)}"
  }
}

resource "google_compute_address" "app_ip" {
  count  = "${var.number_of_instances}"
  name   = "reddit-app-ip-${count.index}"
  region = "${var.region}"
}
