
include .env

################################################################################
## Config values from .env file
################################################################################

export TF_VAR_aws_profile = $(AWS_PROFILE)
export TF_VAR_owner_name = $(OWNER_NAME)
export TF_VAR_owner_email = $(OWNER_EMAIL)
export TF_VAR_resource_prefix = $(RESOURCE_PREFIX)
export TF_VAR_secret_name_suffix = $(SECRET_NAME_SUFFIX)
export TF_VAR_dns_hosted_zone_id = $(DNS_HOSTED_ZONE_ID)
export TF_VAR_dns_suffix = $(DNS_SUFFIX)

export TF_VAR_grafana_repo = $(GRAFANA_REPO)
export TF_VAR_grafana_image_version = $(GRAFANA_VERSION)
export TF_VAR_grafana_admin_password = $(GRAFANA_ADMIN_PASSWORD)
export TF_VAR_grafana_prometheus_url = $(GRAFANA_PROMETHEUS_URL)

export TF_VAR_prometheus_repo = $(PROMETHEUS_REPO)
export TF_VAR_prometheus_image_version = $(PROMETHEUS_VERSION)
export TF_VAR_prometheus_confluent_cloud_api_key = $(CONFLUENT_CLOUD_API_KEY)
export TF_VAR_prometheus_confluent_cloud_api_secret = $(CONFLUENT_CLOUD_API_SECRET)
export TF_VAR_prometheus_alertmanager_url = $(PROMETHEUS_ALERTMANAGER_URL)
export TF_VAR_prometheus_admin_password = $(PROMETHEUS_ADMIN_PASSWORD)

export TF_VAR_alertmanager_repo = $(ALERTMANAGER_REPO)
export TF_VAR_alertmanager_image_version = $(ALERTMANAGER_VERSION)
export TF_VAR_alertmanager_webhook_url = $(ALERTMANAGER_WEBHOOK_URL)

################################################################################
## Terraform Infra
################################################################################

tf-init:
	terraform -chdir=infra init

tf-fmt:
	terraform -chdir=infra fmt

tf-apply:
	terraform -chdir=infra apply -auto-approve
	
tf-destroy:
	terraform -chdir=infra destroy -auto-approve

tf-clean:
	rm -rf infra/.terraform
	rm infra/.terraform.lock.hcl
	rm infra/terraform.tfstate
	rm infra/terraform.tfstate.backup

################################################################################
## Docker Images
################################################################################

ecr-grafana:
	cd grafana && \
	aws ecr get-login-password --profile $(AWS_PROFILE) --region ap-southeast-2 | docker login --username AWS --password-stdin $(AWS_ECR_REGISTRY) && \
	docker build . -t $(AWS_ECR_REGISTRY)/$(GRAFANA_REPO):$(GRAFANA_VERSION) && docker push $(AWS_ECR_REGISTRY)/$(GRAFANA_REPO):$(GRAFANA_VERSION)

ecr-prometheus:
	cd prometheus && \
	aws ecr get-login-password --profile $(AWS_PROFILE) --region ap-southeast-2 | docker login --username AWS --password-stdin $(AWS_ECR_REGISTRY) && \
	docker build . -t $(AWS_ECR_REGISTRY)/$(PROMETHEUS_REPO):$(PROMETHEUS_VERSION) && docker push $(AWS_ECR_REGISTRY)/$(PROMETHEUS_REPO):$(PROMETHEUS_VERSION)

ecr-alertmanager:
	cd alertmanager && \
	aws ecr get-login-password --profile $(AWS_PROFILE) --region ap-southeast-2 | docker login --username AWS --password-stdin $(AWS_ECR_REGISTRY) && \
	docker build . -t $(AWS_ECR_REGISTRY)/$(ALERTMANAGER_REPO):$(ALERTMANAGER_VERSION) && docker push $(AWS_ECR_REGISTRY)/$(ALERTMANAGER_REPO):$(ALERTMANAGER_VERSION)

ecr-all: ecr-grafana ecr-prometheus ecr-alertmanager

docker-build:
	cd prometheus && docker build . -t $(PROMETHEUS_REPO):$(PROMETHEUS_VERSION)
	cd grafana && docker build . -t $(GRAFANA_REPO):$(GRAFANA_VERSION)
	cd alertmanager && docker build . -t $(ALERTMANAGER_REPO):$(ALERTMANAGER_VERSION)

docker-run:
	@mkdir -p tmp
	@sed -e "s#{{PROMETHEUS_REPO}}#$(PROMETHEUS_REPO)#g" \
		-e "s#{{PROMETHEUS_VERSION}}#$(PROMETHEUS_VERSION)#g" \
		-e "s#{{CONFLUENT_CLOUD_API_KEY}}#$(CONFLUENT_CLOUD_API_KEY)#g" \
		-e "s#{{CONFLUENT_CLOUD_API_SECRET}}#$(CONFLUENT_CLOUD_API_SECRET)#g" \
		-e "s#{{PROMETHEUS_ALERTMANAGER_URL}}#$(PROMETHEUS_ALERTMANAGER_URL)#g" \
		-e "s#{{GRAFANA_REPO}}#$(GRAFANA_REPO)#g" \
		-e "s#{{GRAFANA_VERSION}}#$(GRAFANA_VERSION)#g" \
		-e "s#{{GRAFANA_ADMIN_PASSWORD}}#$(GRAFANA_ADMIN_PASSWORD)#g" \
		docker-compose.tpl.yml > tmp/docker-compose.yml
	
	@cd tmp && docker-compose up

docker-delete:
	@cd tmp && docker-compose down
