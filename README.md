# microservices-lab
# Microservice DevOps Lab

## Overview
FastAPI app deployed in home lab with CI/CD (Act), IaC (Terraform), automation (Ansible), orchestration (K8s), monitoring (Prometheus/Grafana).

## Setup
- 4 Ubuntu VM in VirtualBox.
- Networks: Bridged (MikroTik internet), Host-only (private).

## Run
- Act CI: act
- Terraform: terraform apply -auto-approve
- Ansible: ansible-playbook deploy-app.yaml -K
- K8s: kubectl apply -f deployment.yaml
- Prometheus: docker run -d --name prometheus -p 9090:9090 -v prometheus.yml:/etc/prometheus/prometheus.yml prom/prometheus
- Grafana: http://192.168.56.102:3000 (datasource Prometheus)

## Tests
- Curl master: curl http://localhost:8000
- Curl node: curl 192.168.56.103:8000
- Prometheus targets: http://192.168.56.102:9090/targets
- Grafana dashboard: Query http_requests_total.

## Logs Example
- Docker logs myapp: Application startup complete.
- Act output: [paste your Act success log, e.g., Success - Main Test app].

## Screenshots
- Grafana graph: [add if possible]
- Docker ps: [paste your docker ps with prometheus].
