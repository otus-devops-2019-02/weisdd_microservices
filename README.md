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


## HW#16 (docker-3)
В данной работе мы:
* научились описывать и собирать Docker-образы для сервисного приложения;
* научились оптимизировать работу с Docker-образами;
* опробовали запуск и работу приложения на основе Docker-образов;
* оценили удобство запуска контейнеров при помощи docker run;
* переопределили ENV через docker run;
* оптимизировали размер контейнера (образ на базе Alpine).

Работа велась в каталоге src, где под каждый сервис существует отдельная директория (comment, post-py, ui). Для MongoDB использовался образ из Docker Hub.

В соответствии с рекомендациями hadolint было внесены изменения:
### ui/Dockerfile
RUN apt-get update -qq && apt-get install -y build-essential
=>
RUN apt-get update -qq && apt-get install -y build-essential --no-install-recommends \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

ADD Gemfile* $APP_HOME/
=>
COPY Gemfile* $APP_HOME/

ADD . $APP_HOME
=>
COPY . $APP_HOME

### comment/Dockerfile
RUN apt-get update -qq && apt-get install -y build-essential
=>
RUN apt-get update -qq && apt-get install -y build-essential --no-install-recommends \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
	
ADD Gemfile* $APP_HOME/
=>
COPY Gemfile* $APP_HOME/

ADD . $APP_HOME
=>
COPY . $APP_HOME

### post-py/Dockerfile
ADD . /app
=>
COPY . /app

В Dockerfile со слайдов было обнаружено ряд проблем:
1. image для post-py не собирался, т.к. отсутствовал build-base. Обновлённый dockerfile выглядит следующим образом:
```dockerfile
FROM python:3.6.0-alpine

WORKDIR /app
COPY . /app

RUN apk update && apk add --no-cache build-base \
    && pip install -r /app/requirements.txt \
    && apk del build-base

ENV POST_DATABASE_HOST post_db
ENV POST_DATABASE posts

ENTRYPOINT ["python3", "post_app.py"]
```

2. образы для comment и ui не собирались из-за отсутствия одной записи в apt list:
```
W: Failed to fetch http://deb.debian.org/debian/dists/jessie-updates/InRelease  Unable to find expected entry 'main/binary-amd64/Packages' in Release file (Wrong sources.list entry or malformed file)
E: Some index files failed to download. They have been ignored, or old ones used instead.
```
Поэтому пришлось использовать другую версию контейнера:
FROM ruby:2.2
=>
FROM ruby:2.3

После этого все образы успешно собрались:
```bash
$ docker build -t weisdd/post:1.0 post-py/
$ docker build -t weisdd/comment:1.0 ./comment
$ docker build -t weisdd/ui:1.0 ./ui
```

Также мы скачали image для mongo:
```bash
$ docker pull mongo:latest
```

Для удобства, в наших контейнерах использовались сетевые алиасы (отсылка к ним есть в ENV). Поскольку в сети по умолчанию алиасы недоступны, потребовалось создать отдельную bridge-сеть.
```bash
$ docker network create reddit
$ docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db mongo:latest
$ docker run -d --network=reddit --network-alias=post weisdd/post:1.0
$ docker run -d --network=reddit --network-alias=comment weisdd/comment:1.0
$ docker run -d --network=reddit -p 9292:9292 weisdd/ui:1.0
```

### Задание со * (стр. 15)
Задание:
Остановите контейнеры:
docker kill $(docker ps -q)
Запустите контейнеры с другими сетевыми алиасами.
Адреса для взаимодействия контейнеров задаются через ENV-переменные внутри Dockerfile'ов.
При запуске контейнеров (docker run) задайте им переменные окружения соответствующие новым сетевым алиасам, не пересоздавая образ.
Проверьте работоспособность сервиса

Решение:
Переопределить ENV мы можем при помощи флага -e:

```bash
$ docker run -d --network=reddit --network-alias=post_db2 --network-alias=comment_db2 mongo:latest

$ docker run -d --network=reddit --network-alias=post2 -e POST_DATABASE_HOST=post_db2 weisdd/post:1.0

$ docker run -d --network=reddit --network-alias=comment2 -e COMMENT_DATABASE_HOST=comment_db2 weisdd/comment:1.0

$ docker run -d --network=reddit -p 9292:9292 -e POST_SERVICE_HOST=post2 -e COMMENT_SERVICE_HOST=comment2 weisdd/ui:1.0
```

### Работа с образами
После внесения изменений в Dockerfile и пересборки образа:
```bash
$ docker build -t weisdd/ui:2.0 ./ui
$ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED              SIZE
weisdd/ui           2.0                 0bab01157f90        About a minute ago   402MB
weisdd/ui           1.0                 29a58be9410f        27 minutes ago       995MB
```

### Задание со * (стр. 19)
Задание:
Попробуйте собрать образ на основе Alpine Linux.
Придумайте еще способы уменьшить размер образа.
Можете реализовать как только для UI сервиса, так и для остальных (post, comment).
Все оптимизации проводите в Dockerfile сервиса.
Дополнительные варианты решения уменьшения размера образов можете оформить в виде файла Dockerfile.<цифра> в папке сервиса.

Решение:
#### ui/Dockerfile
После перехода на Alpine образ уменьшился вдвое:
```bash
$ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
weisdd/ui           2.0                 0bab01157f90        About an hour ago   402MB
weisdd/ui           1.0                 29a58be9410f        2 hours ago         995MB
```

```dockerfile
FROM alpine:3.9.4

RUN apk update && apk add --no-cache build-base ruby-full ruby-dev ruby-bundler \
	&& gem install bundler --no-ri --no-rdoc

ENV APP_HOME /app
RUN mkdir $APP_HOME

WORKDIR $APP_HOME
COPY Gemfile* $APP_HOME/
RUN bundle install
COPY . $APP_HOME

ENV POST_SERVICE_HOST post
ENV POST_SERVICE_PORT 5000
ENV COMMENT_SERVICE_HOST comment
ENV COMMENT_SERVICE_PORT 9292

CMD ["puma"]
```

Более полная оптимизация:
- ruby вместо ruby-full (соответственно, нужно ставить отдельные компоненты вроде ruby-json);
- комбинирование всех команд, связанных с установкой приложения, в одну инструкцию RUN, что позволяет удалить build-base и ruby-dev после сборки приложения.

```dockerfile
FROM alpine:3.9.4

ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME
COPY . $APP_HOME

RUN apk update && apk add --no-cache build-base ruby ruby-json ruby-dev ruby-bundler \
	&& gem install bundler --no-ri --no-rdoc \
	&& bundle install \
	&& apk del build-base ruby-dev

ENV POST_SERVICE_HOST post
ENV POST_SERVICE_PORT 5000
ENV COMMENT_SERVICE_HOST comment
ENV COMMENT_SERVICE_PORT 9292

CMD ["puma"]
```

Таким образом, мы уменьшили размер образа с 995MB до 67.9MB:
```bash
$ docker build -t weisdd/ui:2.3 ./ui
$ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
weisdd/ui           2.3                 580d3a9549ee        45 seconds ago      67.9MB
```

В целом, миграция с ruby-full на ruby+отдельные компоненты не даёт большого выйгрыша в дисковом пространстве. При этом поддержка образа усложняется, поскольку при включении в приложение дополнительного компонента (в процессе разработки) придётся выполнять пересборку. Но для эксперимента сгодится.

#### comment/Dockerfile
Версия с ruby-full (69.2MB):
```dockerfile
FROM alpine:3.9.4

ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME
COPY . $APP_HOME

RUN apk update && apk add --no-cache build-base ruby-full ruby-dev ruby-bundler \
	&& gem install bundler --no-ri --no-rdoc \
	&& bundle install \
	&& apk del build-base ruby-dev

ENV COMMENT_DATABASE_HOST comment_db
ENV COMMENT_DATABASE comments

CMD ["puma"]
```

Версия с ruby + отдельными компонентами (65.1MB):
```dockerfile
FROM alpine:3.9.4

ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME
COPY . $APP_HOME

RUN apk update && apk add --no-cache build-base ruby ruby-json ruby-bigdecimal ruby-dev ruby-bundler \
	&& gem install bundler --no-ri --no-rdoc \
	&& bundle install \
	&& apk del build-base ruby-dev

ENV COMMENT_DATABASE_HOST comment_db
ENV COMMENT_DATABASE comments

CMD ["puma"]
```

#### Запуск приложения
После внесённых изменений, приложение можно запустить набором из следующих команд:
```bash
$ docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db mongo:latest
$ docker run -d --network=reddit --network-alias=post weisdd/post:1.0
$ docker run -d --network=reddit --network-alias=comment weisdd/comment:2.1
$ docker run -d --rm --network=reddit -p 9292:9292 weisdd/ui:2.3
```

### Подключение volume к MongoDB
```bash
$ docker volume create reddit_db
reddit_db
```

```bash
$ docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db -v reddit_db:/data/db mongo:latest
$ docker run -d --network=reddit --network-alias=post weisdd/post:1.0
$ docker run -d --network=reddit --network-alias=comment weisdd/comment:2.1
$ docker run -d --rm --network=reddit -p 9292:9292 weisdd/ui:2.3
```


## HW#17 (docker-4)
В данной работе мы:
* изучили особенности работы с сетями в Docker;
* опробовали docker-compose;
* параметризировали docker-compose.yml через .env файл;
* переопределили базовое имя проекта;
* при помощи docker-compose.override.yml добавили следующие возможности (*):
  - изменять код каждого из приложений, не выполняя сборку образа;
  - запускать puma для руби приложений в дебаг-режиме с двумя воркерами (флаги --debug и -w 2)

### None network driver
```bash
$ docker run -ti --rm --network none joffotron/docker-net-tools -c ifconfig
```
В данном случае в контейнере будет только интерфейс lo.

### Host network driver
```bash
docker run --network host -d nginx
```
В данном случае будет использоваться namespace хоста.

На стр. 11 было предложено выполнить вышеуказанную команду несколько раз и изучить результат. - В итоге оказался запущенным только первый контейнер, поскольку каждый последующий пытался использовать уже занятый порт:

```bash
$ docker ps -a
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                      PORTS               NAMES
7570632fd416        nginx               "nginx -g 'daemon of…"   14 seconds ago      Exited (1) 11 seconds ago                       goofy_mclean
e02b2bd6889a        nginx               "nginx -g 'daemon of…"   23 seconds ago      Exited (1) 20 seconds ago                       clever_mahavira
4f7d9625ffa0        nginx               "nginx -g 'daemon of…"   34 seconds ago      Up 32 seconds                                   priceless_goldstine

$ docker logs e02b2bd6889a
2019/06/03 21:19:21 [emerg] 1#1: bind() to 0.0.0.0:80 failed (98: Address already in use)
nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address already in use)
2019/06/03 21:19:21 [emerg] 1#1: bind() to 0.0.0.0:80 failed (98: Address already in use)
nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address already in use)
2019/06/03 21:19:21 [emerg] 1#1: bind() to 0.0.0.0:80 failed (98: Address already in use)
nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address already in use)
2019/06/03 21:19:21 [emerg] 1#1: bind() to 0.0.0.0:80 failed (98: Address already in use)
nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address already in use)
2019/06/03 21:19:21 [emerg] 1#1: bind() to 0.0.0.0:80 failed (98: Address already in use)
nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address already in use)
2019/06/03 21:19:21 [emerg] 1#1: still could not bind()
nginx: [emerg] still could not bind()
```

### Bridge network driver
```bash
docker network create reddit --driver bridge
```
--driver bridge можно не указывать, т.к. это - опция по умолчанию.

Интересной особенностью является тот факт, что при инициализации контейнера к нему можно подключить только одну сеть, тогда как нам необходимо использовать несколько:
```bash
$ docker run -d --network=front_net -p 9292:9292 --name ui weisdd/ui:1.0
$ docker run -d --network=back_net --name comment weisdd/comment:1.0
$ docker run -d --network=back_net --name post weisdd/post:1.0
$ docker run -d --network=back_net --name mongo_db --network-alias=post_db --network-alias=comment_db mongo:latest

```
Дополнительные сети подключаются отдельной командой:
```bash
$ docker network connect front_net post
$ docker network connect front_net comment
```

Список всех сетей можно вывести следующим образом:
```bash
docker-user@docker-host:~$ sudo docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
b9b5b1434f86        back_net            bridge              local
b85ca48c0c17        bridge              bridge              local
ff21730503d4        front_net           bridge              local
67dc6e20baac        host                host                local
01e8073f021f        none                null                local
e5f24ec1dd5d        reddit              bridge              local
```

Каждой bridge-сети будет соответствовать отдельный интерфейс:
```bash
docker-user@docker-host:~$ ifconfig | grep br
br-b9b5b1434f86 Link encap:Ethernet  HWaddr 02:42:22:16:32:a2  
br-e5f24ec1dd5d Link encap:Ethernet  HWaddr 02:42:23:6b:b7:a6  
br-ff21730503d4 Link encap:Ethernet  HWaddr 02:42:aa:ab:90:a3  

docker-user@docker-host:~$ brctl show br-b9b5b1434f86
bridge name	bridge id		STP enabled	interfaces
br-b9b5b1434f86		8000.0242221632a2	no		veth0b4f90a
							veth6340764
							vethb631212
docker-user@docker-host:~$ brctl show br-ff21730503d4 
bridge name	bridge id		STP enabled	interfaces
br-ff21730503d4		8000.0242aaab90a3	no		veth7902c28
							veth7e78ec6
							veth8f619b0
```

В iptables существуют соответствующие правила:
```bash
$ sudo iptables -nL -t nat
Chain PREROUTING (policy ACCEPT)
target     prot opt source               destination         
DOCKER     all  --  0.0.0.0/0            0.0.0.0/0            ADDRTYPE match dst-type LOCAL

Chain INPUT (policy ACCEPT)
target     prot opt source               destination         

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination         
DOCKER     all  --  0.0.0.0/0           !127.0.0.0/8          ADDRTYPE match dst-type LOCAL

Chain POSTROUTING (policy ACCEPT)
target     prot opt source               destination         
MASQUERADE  all  --  10.0.1.0/24          0.0.0.0/0           
MASQUERADE  all  --  10.0.2.0/24          0.0.0.0/0           
MASQUERADE  all  --  172.17.0.0/16        0.0.0.0/0           
MASQUERADE  all  --  172.18.0.0/16        0.0.0.0/0           
MASQUERADE  tcp  --  10.0.1.2             10.0.1.2             tcp dpt:9292

Chain DOCKER (2 references)
target     prot opt source               destination         
RETURN     all  --  0.0.0.0/0            0.0.0.0/0           
RETURN     all  --  0.0.0.0/0            0.0.0.0/0           
RETURN     all  --  0.0.0.0/0            0.0.0.0/0           
RETURN     all  --  0.0.0.0/0            0.0.0.0/0           
DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:9292 to:10.0.1.2:9292
```
- в цепочке POSTROUTING мы видим правила NAT'а для каждой подсети + проброс порта. 

Для выставленных наружу портов (в данном случае - 9292) мы видим процесс docker-proxy:
```bash
docker-user@docker-host:~$ ps ax | grep docker-proxy
 7705 ?        Sl     0:00 /usr/bin/docker-proxy -proto tcp -host-ip 0.0.0.0 -host-port 9292 -container-ip 10.0.1.2 -container-port 9292
10982 pts/0    S+     0:00 grep --color=auto docker-proxy
```

### docker-compose
docker-compose поддерживает интерполяцию переменных окружения, при этом можно использовать как export, так и специальный файл .env (об этом позже):
```bash
$ export USERNAME=weisdd
$ weisdd_microservices/src$ docker-compose up -d
Creating network "src_reddit" with the default driver
Creating volume "src_post_db" with default driver
Pulling post_db (mongo:3.2)...
[...]
Status: Downloaded newer image for mongo:3.2
Creating src_ui_1      ... done
Creating src_post_db_1 ... done
Creating src_post_1    ... done
Creating src_comment_1 ... done

ibeliako@dev:~/devops/git/weisdd_microservices/src$ docker-compose ps
    Name                  Command             State           Ports         
----------------------------------------------------------------------------
src_comment_1   puma                          Up                            
src_post_1      python3 post_app.py           Up                            
src_post_db_1   docker-entrypoint.sh mongod   Up      27017/tcp             
src_ui_1        puma                          Up      0.0.0.0:9292->9292/tcp
```

### Задание (стр. 35)
Задача 1:
Изменить docker-compose под кейс с множеством сетей, сетевых алиасов (стр 18)

Решение:
```dockerfile
version: '3.3'
services:
  post_db:
    image: mongo:3.2
    volumes:
      - post_db:/data/db
    networks:
      back_net:
        aliases:
          - comment_db
  ui:
    build: ./ui
    image: ${USERNAME}/ui:1.0
    ports:
      - 9292:9292/tcp
    networks:
      - front_net
  post:
    build: ./post-py
    image: ${USERNAME}/post:1.0
    networks:
      - back_net
      - front_net
  comment:
    build: ./comment
    image: ${USERNAME}/comment:1.0
    networks:
      - back_net
      - front_net

volumes:
  post_db:

networks:
  back_net:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 10.0.2.0/24
  front_net:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 10.0.1.0/24
```
**ВАЖНО**: На слайдах была ошибка в описании docker-compose - отсутствует алиас для comment_db, поэтому работает всё, кроме комментариев. В решении выше, эта ошибка исправлена.

Задача 2:
Параметризуйте с помощью переменных окружений:
* порт публикации сервиса ui
* версии сервисов
* возможно что-либо еще на ваше усмотрение
Параметризованные параметры запишите в отдельный файл c расширением .env
Без использования команд source и export docker-compose должен подхватить переменные из этого файла.

Решение:
docker-compose.yml
```dockerfile
version: '3.3'
services:
  post_db:
    image: mongo:3.2
    volumes:
      - post_db:/data/db
    networks:
      back_net:
        aliases:
          - comment_db
  ui:
    build: ./ui
    image: ${USERNAME}/ui:${UI_VERSION}
    ports:
      - ${UI_PORT}:9292/tcp
    networks:
      - front_net
  post:
    build: ./post-py
    image: ${USERNAME}/post:${POST_VERSION}
    networks:
      - back_net
      - front_net
  comment:
    build: ./comment
    image: ${USERNAME}/comment:${COMMENT_VERSION}
    networks:
      - back_net
      - front_net

volumes:
  post_db:

networks:
  back_net:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 10.0.2.0/24
  front_net:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 10.0.1.0/24
```

https://docs.docker.com/compose/environment-variables/#the-env-file
.env
```bash
weisdd_microservices/src$ cat env
USERNAME=weisdd
UI_PORT=9292
UI_VERSION=1.0
POST_VERSION=1.0
COMMENT_VERSION=1.0
```

### Задание (стр. 36)
Задание:
Узнайте как образуется базовое имя проекта.

Решение:
Структура имени: project_service_index_slug, где slug - случайно сгенерированное шестнадцатиричное число. 

Задание:
Можно ли его задать? Если можно то как?

Решение:
Имя можно переопределить при помощи специальной переменной окружения COMPOSE_PROJECT_NAME (её можно также внести в файл .env). Пример:

```bash
export COMPOSE_PROJECT_NAME=test

weisdd_microservices/src$ docker-compose up -d
Creating network "test_back_net" with driver "bridge"
Creating network "test_front_net" with driver "bridge"
Creating volume "test_post_db" with default driver
Creating test_post_1    ... done
Creating test_post_db_1 ... done
Creating test_comment_1 ... done
Creating test_ui_1      ... done
```

### Задание со * (стр. 37)
Задание:
Создайте docker-compose.override.yml для reddit проекта, который позволит:
* Изменять код каждого из приложений, не выполняя сборку образа;
* Запускать puma для руби приложений в дебаг режиме с двумя воркерами (флаги --debug и -w 2).

Решение:
https://docs.docker.com/compose/extends/

weisdd_microservices/src/docker-compose.override.yml 
```dockerfile
version: '3.3'

services:
  ui:
    command: puma --debug -w 2
    volumes:
      - app_ui:/app

  post:
    volumes:
      - app_post:/app

  comment:
    command: puma --debug -w 2
    volumes:
      - app_comment:/app

volumes:
  app_ui:
  app_comment:
  app_post:
```
- инструкция command переопределяет CMD, указанное в Dockerfile;
- для каждого каталога с приложением создан отдельный volume.

Проверка:
```bash
$ docker ps
CONTAINER ID        IMAGE                COMMAND                  CREATED             STATUS              PORTS                    NAMES
b3479d2afabe        mongo:3.2            "docker-entrypoint.s…"   47 seconds ago      Up 44 seconds       27017/tcp                src_post_db_1
c63dba23b2fb        weisdd/post:1.0      "python3 post_app.py"    47 seconds ago      Up 43 seconds                                src_post_1
fe962f5e8ff7        weisdd/ui:1.0        "puma --debug -w 2"      47 seconds ago      Up 44 seconds       0.0.0.0:9292->9292/tcp   src_ui_1
cd046c798596        weisdd/comment:1.0   "puma --debug -w 2"      47 seconds ago      Up 43 seconds                                src_comment_1
ib

$ docker volume ls | egrep 'DRIVER|src'
DRIVER              VOLUME NAME
local               src_app_comment
local               src_app_post
local               src_app_ui
local               src_post_db
```
