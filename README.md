DevOps Microservice Lab
Overview

This project is a hands-on DevOps lab for deploying a simple FastAPI microservice in a home lab environment. It demonstrates a full pipeline including CI/CD with Act (local GitHub Actions), IaC with Terraform, automation with Ansible, orchestration with Kind Kubernetes, and monitoring with Prometheus and Grafana. The setup uses 4 Ubuntu Server VM in VirtualBox, with bridged (MikroTik for internet) and host-only networks.

Key components:

    App: FastAPI service with /metrics endpoint for Prometheus.
    Infra: 1 master VM (ubuntu-server-1) + 3 nodes (ubuntu-server-2/3/4).
    Tools: Docker, Kind (K8s), Terraform, Ansible, Act, Prometheus/Grafana.
    Workflow: Git push triggers Act (build/test/deploy), Ansible distributes to nodes, K8s orchestrates, monitoring scrapes metrics.

This lab is ideal for learning DevOps practices and building a portfolio for Upwork/freelance.
Requirements

    Windows 10 host with VirtualBox 7.0+ and Extension Pack.
    MikroTik router for bridged network (subnet 192.168.88.0/24, gateway 192.168.88.1).
    Ubuntu Server 24.04 LTS ISO.
    GitHub account (for repo push, optional).
    Minimum VM resources: 4 GB RAM, 2–4 CPU cores per VM.

Installation

    Setup VirtualBox Networks:
        Bridged Adapter: Link to MikroTik interface.
        Host-Only: vboxnet0, 192.168.56.1/24, DHCP off.
    Create VM:
        Create ubuntu-server-1 (master): Memory 4 GB, CPU 2–4, Disk 50 GB, Network Adapter 1 Bridged, Adapter 2 Host-Only.
        Install Ubuntu: Minimal, user citizenfour, enable SSH.
        Clone for ubuntu-server-2/3/4, change MAC addresses.
    Configure Netplan on Each VM (example for master):
    text

sudo nano /etc/netplan/50-cloud-init.yaml
Insert (adjust IP for nodes):
yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:  # Bridged
      dhcp4: no
      addresses:
      - "192.168.88.15/24"
      nameservers:
        addresses:
        - 8.8.8.8
        - 8.8.4.4
        search: []
      routes:
      - to: "default"
        via: "192.168.88.1"
    enp0s8:  # Host-only
      dhcp4: no
      addresses:
      - "192.168.56.102/24"
text
sudo netplan apply
ip addr show  # Verify IP
ping 8.8.8.8  # Internet
SSH Setup:

    On master: ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "".
    Copy pub key to nodes: cat ~/.ssh/id_rsa.pub (paste to node ~/.ssh/authorized_keys, chmod 600).
    Fix permissions: chmod 600 ~/.ssh/id_rsa.

Install Tools on Master (then playbook for nodes):

    Base: sudo apt update && sudo apt upgrade -y; sudo apt install curl wget git vim net-tools unzip -y.
    Docker: sudo apt install docker.io -y; sudo usermod -aG docker $USER; newgrp docker; docker run hello-world.
    Go: wget https://go.dev/dl/go1.22.5.linux-amd64.tar.gz; sudo tar -C /usr/local -xzf go1.22.5.linux-amd64.tar.gz; echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.profile; source ~/.profile.
    Kind: go install sigs.k8s.io/kind@v0.29.0; kind version.
        Config: ~/.kind-config.yaml (4 nodes).
        Cluster: kind create cluster --name devops-lab --config ~/.kind-config.yaml.
    kubectl: curl -LO "https://dl.k8s.io/release/v1.31.0/bin/linux/amd64/kubectl"; sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl.
    Terraform: wget https://releases.hashicorp.com/terraform/1.14.0-alpha20250716/terraform_1.14.0-alpha20250716_linux_amd64.zip; unzip ...; sudo mv terraform /usr/local/bin/.
    Ansible: sudo apt install ansible -y.
        Inventory: ~/.ansible/hosts (as above).
        Test: ansible -i ~/.ansible/hosts all -m ping.
    Prometheus/Grafana: docker run -d --name prometheus -p 9090:9090 -v prometheus.yml:/etc/prometheus/prometheus.yml prom/prometheus; docker run -d --name grafana -p 3000:3000 --network host grafana/grafana.
    Act: go install github.com/nektos/act@latest.

Playbook for Nodes (install-tools.yaml):
text

    ---
    - hosts: nodes
      become: yes
      tasks:
        - name: Update and upgrade
          apt:
            update_cache: yes
            upgrade: yes

        - name: Install base
          apt:
            name: [curl, wget, git, vim, net-tools, unzip]
            state: present

        - name: Install Docker
          apt:
            name: docker.io

        - name: Add docker group
          user:
            name: "{{ ansible_user }}"
            groups: docker
            append: yes

        - name: Install Go
          shell: |
            wget https://go.dev/dl/go1.22.5.linux-amd64.tar.gz
            tar -C /usr/local -xzf go1.22.5.linux-amd64.tar.gz
            echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> /home/{{ ansible_user }}/.profile
          args:
            creates: /usr/local/go/bin/go

        - name: Install Terraform
          shell: |
            wget https://releases.hashicorp.com/terraform/1.14.0-alpha20250716/terraform_1.14.0-alpha20250716_linux_amd64.zip
            unzip terraform_1.14.0-alpha20250716_linux_amd64.zip
            mv terraform /usr/local/bin/
          args:
            creates: /usr/local/bin/terraform

        - name: Install Ansible
          apt:
            name: ansible

        - name: Install kubectl
          shell: |
            curl -LO "https://dl.k8s.io/release/v1.31.0/bin/linux/amd64/kubectl"
            install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
          args:
            creates: /usr/local/bin/kubectl

        - name: Install Act
          shell: /usr/local/go/bin/go install github.com/nektos/act@latest
          become_user: "{{ ansible_user }}"
        Run: ansible-playbook -i ~/.ansible/hosts install-tools.yaml -K.
    Cloud Integration (AWS/GCP on master/nodes via playbook).

Выполненные Шаги: Развёртывание App

    Repo: git init microservices-lab; cd microservices-lab.
    main.py (FastAPI with metrics).
    Dockerfile (with pip install).
    Build/test: docker build -t myapp:latest .; docker run -d -p 8000:80 --name myapp myapp:latest; curl http://localhost:8000.
    Terraform main.tf for IaC, apply.
    Ansible deploy-app.yaml for nodes, run.
    K8s deployment.yaml, apply after kind load docker-image myapp:latest.
    Act ci.yaml with build/test/Terraform/kubectl install (deploy manual note).
    Prometheus prometheus.yml with targets, restart.
    Grafana with datasource, dashboard.
    Outputs: Your Act logs show success for build/test/Terraform, Ansible changed=4, K8s pods Pending to Running after load.
    Fixes: Syntax in main.py (class Item(BaseModel)), port conflicts (docker rm), PATH (source ~/.profile), GPG (export GPG_TTY), apt exclusive (divide tasks), image pull (kind load), module not found (pip in Dockerfile), container name conflict (docker rm), Act tool not found (install in workflow).
