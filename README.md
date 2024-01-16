# Introduction

A Confluent Cloud monitoring stack on AWS ECS.

# High-level Architecture

![high-level diagram](assets/highlevel-diagram.png)

# Terraform Components depdency diagram
![components diagram](assets/dependency-graph-tf-components.png)


# Usage

## 0. Update configurations

You need to use `.env.example` to create your own configuration file `.env` under the project root folder.

## 1. Init terraform
```
make tf-init
```
The state file for terraform is under `infra` folder. If you want to change the terraform backend, you need to modify the `Makefile`.


## 2. Create AWS resources
```
make tf-apply
```
## 3. Build and push docker containers
```
make ecr-prometheus
make ecr-grafana
make ecr-alertmanager
```
or
```
make ecr-buildAndPush
```

## 4. Destroy all resources
```
make tf-destroy
```

# Reference: 

[Confluent JMX Stack](https://github.com/confluentinc/jmx-monitoring-stacks/tree/main/jmxexporter-prometheus-grafana)

[Terraform AWS VPC module](https://github.com/terraform-aws-modules/terraform-aws-vpc)

[Prometheus Configuration](https://prometheus.io/docs/prometheus/latest/configuration/configuration/
)

[Prometheus Basic Authentication](https://prometheus.io/docs/guides/basic-auth/)


[Grafana Configuration](https://grafana.com/docs/grafana/latest/setup-grafana/configure-grafana/)


[Grafana LDAP Integration](https://grafana.com/docs/grafana/latest/setup-grafana/configure-security/configure-authentication/ldap/)


[Alertmanager Configuration](https://prometheus.io/docs/alerting/latest/alertmanager/)
