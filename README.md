# weisdd_microservices
weisdd microservices repository

## HW#14 (docker-1)
В данной работе мы:
* установили docker, docker-compose, docker-machine;
* рассмотрели жизненные цикл контейнера на примере hello-world и nginx;
* рассмотрели отличия image и container.

### Полезные команды:
```
$ docker info - информация о dockerd (включая количество containers, images и т.п.).
$ docker version
$ docker images - список всех images.
$ docker ps - список запущенных на текущий момент контейнеров.
$ docker ps -a - список всех контейнеров, в т.ч. остановленных.
$ docker system df - информация о дисковом пространстве (контейнеры, образы и т.д.).
$ docker inspect <id> - подробная информация об объекте docker.
$ docker run hello-world - запуск контейнера hello-world. Может служить тестом на проверку работоспособности docker.
$ docker run -it ubuntu:16.04 /bin/bash - пример того, как можно создать и запустить контейнер с последующим переходом в терминал.
    -i - запуск контейнера в foreground-режиме (docker attach).
    -d - запуск контейнера в background-режиме.
    -t - создание TTY.
Пример:
* docker run -it ubuntu:16.04 bash
* docker run -dt nginx:latest
```

Важные моменты:
* если не указывать флаг --rm, то после остановки контейнер останется на диске;
* docker run каждый раз запускает новый контейнер;
* docker run = docker create + docker start;

```
$ docker start <u_container_id> - запуск остановленного контейнера.
$ docker attach <u_container_id> - подключение к терминалу уже созданного контейнера.

$ docker exec <u_container_id> <command> - запуск нового процесса внутри контейнера.
Пример:
docker exec -it <u_container_id> bash

$ docker commit <u_container_id> <name> - создание image из контейнера.

$ docker kill <u_container_id> - отправка SIGKILL.
$ docker stop <u_container_id> - отправка SIGTERM, затем (через 10 секунд) SIGKILL.
Пример:
docker kill $(docker ps -q) - уничтожение всех запущенных контейнеров.

$ docker rm <u_container_id> - удаление контейнер (должен быть остановлен).
    -f - позволяет удалить работающий контейнер (предварительно посылается SIGKILL).
Пример:
$ docker rm $(docker ps -a -q) - удаление всех незапущенных контейнеров.

$ docker rmi - удаление image, если от него не зависят запущенные контейнеры.
```

## HW#15 (docker-2)
В данной работе мы:
* создали docker host;
* описали Dockerfile;
* опубликовали Dockerfile на Docker Hub;
* подготовили прототип автоматизации деплоя приложения в связке Packer + Ansible Terraform.

### Docker machine
Создание хоста с docker в GCP при помощи docker-machine:
```bash
$ docker-machine create --driver google --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts --google-machine-type n1-standard-1 --google-zone europe-west1-b docker-host
```

Переключение на удалённый docker (все команды docker будут выполняться на удалённом хосте):
```bash
eval $(docker-machine env <имя>)
```

Переключение на локальный докер:
```bash
eval $(docker-machine env --unset)
```

Удаление:
```bash
docker-machine rm <имя>
```


### Подготовка Dockerfile
Для полного описания контейнера нам потребуются следующие файлы:
* Dockerfile
* mongod.conf
* db_config
* start.sh

```dockerfile
FROM ubuntu:16.04

RUN apt-get update
RUN apt-get install -y mongodb-server ruby-full ruby-dev build-essential git
RUN gem install bundler
RUN git clone -b monolith https://github.com/express42/reddit.git

COPY mongod.conf /etc/mongod.conf
COPY db_config /reddit/db_config
COPY start.sh /start.sh

RUN cd /reddit && bundle install
RUN chmod 0777 /start.sh

CMD ["/start.sh"]
```

Создание image из Dockerfile:
```bash
$ docker build -t reddit:latest .
```
    -t - тэг для собранного образа;

Запуск контейнера на основе нашего образа:
```bash
$ docker run --name reddit -d --network=host reddit:latest
d6a3b85c02f45a830ae33bedd8e3eb9c40fe92eca36f3739818c73aaea903172
$ docker-machine ls
NAME          ACTIVE   DRIVER   STATE     URL                       SWARM   DOCKER     ERRORS
docker-host   -        google   Running   tcp://35.195.29.23:2376           v18.09.6
```

### Docker hub
После регистрации на docker hub выполняем аутентификацию:
$ docker login

Публикация образа на docker hub:
```bash
$ docker tag reddit:latest weisdd/otus-reddit:1.0
$ docker push weisdd/otus-reddit:1.0
The push refers to repository [docker.io/weisdd/otus-reddit]
0bf5968c99fc: Pushed 
b1c92e529423: Pushed 
28c2df747281: Pushed 
34a6ce7c331c: Pushed 
25c23944e2ff: Pushed 
95a0f83dbe7b: Pushed 
ed18b4cc6d66: Pushed 
8990d0339489: Pushed 
d1bdff2328b9: Pushed 
4c54072a5034: Mounted from library/ubuntu 
49652298c779: Mounted from library/ubuntu 
e15278fcccca: Mounted from library/ubuntu 
739482a9723d: Mounted from library/ubuntu 
1.0: digest: sha256:89a2160aa4440081157a1534b63bb987e69db67006d58b98e960ddbc31a98da7 size: 3034
```

### Полезные команды
Проверка, с какой командой будет запущен контейнер:
```bash
$ docker inspect weisdd/otus-reddit:1.0 -f '{{.ContainerConfig.Cmd}}'
```

Список изменений в ФС с момента запуска контейнера:
```bash
$ docker diff reddit
```

### Задание со * (стр. 38)
Задание:
Теперь, когда есть готовый образ с приложением, можно автоматизировать поднятие нескольких инстансов в GCP, установку на них докера и запуск там образа <your-login>/otus-reddit:1.0 Нужно реализовать в виде прототипа в директории /docker-monolith/infra/
* Поднятие инстансов с помощью Terraform, их количество задается переменной;
* Несколько плейбуков Ansible с использованием динамического инвентори для установки докера и запуска там образа приложения;
* Шаблон пакера, который делает образ с уже установленным Docker.

Решение:
Решение базировалось на том, что мы описывали в infra-репозитории, - это в последствии сыграет нам на руку.

#### terraform
Здесь всё предельно схоже с предыдущим кодом:
main.tf:
```hcl-terraform
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
```

outputs.tf
```hcl-terraform
output "app_external_ip" {
  value = "${google_compute_instance.app.*.network_interface.0.access_config.0.nat_ip}"
}
```

variables.tf
```hcl-terraform
variable "project" {
  description = "Project ID"
}

variable "region" {
  description = "Region"
  default     = "europe-west-1"
}

variable "public_key_path" {
  description = "Path to the public key used for ssh access"
}

variable "app_disk_image" {
  description = "Disk image for reddit app"
  default     = "docker-host"
}

variable "private_key_path" {
  description = "Path to the private key used for ssh provisioners"
}

variable "zone" {
  description = "Zone"
  default     = "europe-west1-b"
}

variable "number_of_instances" {
  description = "Number of reddit-app instances (count)"
  default     = 1
}

variable "location" {
  description = "Bucket location"
  default     = "europe-west1"
}

variable "label_env" {
  description = "GCP label 'env' associating an instance with an environment in which it's being run (e.g. stage, prod)"
  default     = "stage"
}
```

terraform.tfvars
```hcl-terraform
project = "docker-12345"

public_key_path = "~/.ssh/appuser.pub"

app_disk_image = "docker-host"

region = "europe-west1"

private_key_path = "~/.ssh/appuser"

number_of_instances = 1

location = "europe-west1"

label_env = "stage"
```

#### Ansible
ansible.cfg
```ini
[defaults]
inventory = ./environments/stage/inventory_gcp.yml
remote_user = appuser
private_key_file = ~/.ssh/appuser
host_key_checking = False
retry_files_enabled = False
roles_path = ./roles
vault_password_file = ~/devops/vault.key

[inventory]
enable_plugins = gcp_compute, host_list, script, yaml, ini, auto

[diff]
# Включим обязательный вывод diff при наличии изменений и вывод 5 строк контекста
always = True
context = 5
```

Dynamic inventory будет основан на gcp_compute (он как раз и был активирован выше в секции inventory).
inventory.gcp
```yaml
---
#http://docs.testing.ansible.com/ansible/latest/plugins/inventory/gcp_compute.html
#Uses a YAML configuration file that ends with gcp_compute.(yml|yaml) or gcp.(yml|yaml).
plugin: gcp_compute
zones:
  - europe-west1-b
projects:
  - docker-240120
scopes:
  - https://www.googleapis.com/auth/compute
service_account_file: ~/devops/service_account_docker.json
auth_kind: serviceaccount
filters:
  - labels.env = stage
keyed_groups:
  # <prefix><separator><key>
  - prefix: ""
    separator: ""
    key: labels.ansible_group
hostnames:
  # List hosts by name instead of the default public ip
  - name
compose:
  # Set an inventory parameter to use the Public IP address to connect to the host
  # For Private ip use "networkInterfaces[0].networkIP"
  ansible_host: networkInterfaces[0].accessConfigs[0].natIP
```

Плейбуки для удобства разбиты на роли docker_host и otus_reddit.
ansible/roles/docker_host/tasks/main.yml
```yaml
---
- include: install_docker.yml

```

ansible/roles/docker_host/tasks/install_docker.yml
```yaml
---
- name: Install packages to allow apt to use a repository over HTTPS
  apt:
    name: "{{ packages }}"
    update_cache: yes
  vars:
    packages:
      - apt-transport-https
      - ca-certificates
      - curl
      - gnupg-agent
      - software-properties-common

- name: Add APT key
  apt_key:
    url: https://download.docker.com/linux/ubuntu/gpg
    state: present

- name: Add APT repository
  apt_repository:
    repo: "deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable"
    state: present

- name: Install Docker CE & python-docker
  apt:
    name: "{{ packages }}"
    update_cache: yes
  vars:
    packages:
      - docker-ce
      - docker-ce-cli
      - containerd.io
      - python-docker
```
- поскольку далее мы планируем использовать Ansible, нам необходимо установить python-docker. Все остальные шаги - "перевод" официальной документации Docker (список shell-команд) в yaml.

ansible/roles/otus_reddit/tasks/main.yml
```yaml
---
- include: deploy_container.yml
```

ansible/roles/otus_reddit/tasks/deploy_container.yml
```yaml
---
- name: Create a container with the otus-reddit app
  docker_container:
    name: reddit
    image: "weisdd/otus-reddit:1.0"
    ports:
      - "9292:9292"
```

Плейбуки, в которых используются описанные выше роли:
site.yml
```yaml
---
- import_playbook: base.yml
- import_playbook: docker_host.yml
- import_playbook: otus_reddit.yml
```

base.yml
```yaml
---
- name: Check && install python
  hosts: all
  become: true
  gather_facts: false

  tasks:
    - name: Install python for Ansible
      raw: test -e /usr/bin/python || (apt -y update && apt install -y python-minimal)
      changed_when: false
```

docker_host.yml
```yaml
---
- name: Install docker
  hosts: docker_host
  become: true

  roles:
    - docker_host
```

otus_reddit.yml
```yaml
---
- name: Deploy app
  hosts: docker_host
  become: true

  roles:
    - otus_reddit
```

Плейбук для Packer:
```yaml
---
- import_playbook: base.yml

- name: Install Docker CE
  hosts: all
  become: true
  roles:
    - docker_host
```

#### Packer
docker_host.json
```json
{
    "variables": {
        "project_id": null,
        "source_image_family": null,
        "machine_type": "f1-micro",
        "image_description": "no description",
        "disk_size": "10",
        "network": "default",
        "tags": "docker_host"
    },
    "builders": [
        {
            "type": "googlecompute",
            "project_id": "{{ user `project_id` }}",
            "image_name": "docker-host-{{timestamp}}",
            "image_family": "docker-host",
            "source_image_family": "{{ user `source_image_family` }}",
            "zone": "europe-west1-b",
            "ssh_username": "appuser",
            "machine_type": "{{ user `machine_type` }}",
            "image_description": "{{ user `image_description` }}",
            "disk_size": "{{ user `disk_size` }}",
            "network": "{{ user `network` }}",
            "tags": "{{ user `tags` }}"
        }
    ],
    "provisioners": [
        {
            "type": "ansible",
            "playbook_file": "ansible/playbooks/packer_docker_host.yml",
            "ansible_env_vars": ["ANSIBLE_ROLES_PATH={{ pwd }}/ansible/roles"]
        }
    ]
}
```

variables.json.example
```json
{
  "project_id": "docker-12345",
  "source_image_family": "ubuntu-1804-lts",
  "machine_type": "f1-micro",
  "image_description": "base image for docker host",
  "disk_size": "10",
  "network": "default",
  "tags": "docker-host"
}
```

#### Проверка работы
Создаём образ в GCP при помощи packer:
```bash
weisdd_microservices/docker-monolith/infra$ packer validate -var-file=packer/variables.json packer/docker_host.json 
Template validated successfully.
weisdd_microservices/docker-monolith/infra$ packer build -var-file=packer/variables.json packer/docker_host.json 
googlecompute output will be in this color.
[...]
==> googlecompute: Provisioning with Ansible...
[...]
    googlecompute: PLAY RECAP *********************************************************************
    googlecompute: default                    : ok=6    changed=4    unreachable=0    failed=0
[...]
==> Builds finished. The artifacts of successful builds are:
--> googlecompute: A disk image was created: docker-host-1559416667
```

Создаём instance с этим образом:
```bash
$ terraform apply
```

Деплоим контейнер:
```bash
weisdd_microservices/docker-monolith/infra/ansible$ ansible-playbook playbooks/otus_reddit.yml 

PLAY [Deploy app] ******************************************************************************************************************************

TASK [Gathering Facts] *************************************************************************************************************************
ok: [docker-host-0]

TASK [otus_reddit : Create a container with the otus-reddit app] *******************************************************************************
changed: [docker-host-0]

PLAY RECAP *************************************************************************************************************************************
docker-host-0              : ok=2    changed=1    unreachable=0    failed=0   
```

Теперь приложение доступно по адресу:
35.240.8.240:9292
