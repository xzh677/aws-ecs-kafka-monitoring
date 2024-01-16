
include .env

########################################################################################################################
## Config values from .env file
########################################################################################################################

export TF_VAR_aws_profile = $(AWS_PROFILE)
export TF_VAR_owner_name = $(OWNER_NAME)
export TF_VAR_owner_email = $(OWNER_EMAIL)
export TF_VAR_resource_prefix = $(RESOURCE_PREFIX)
export TF_VAR_dns_hosted_zone_id = $(DNS_HOSTED_ZONE_ID)
export TF_VAR_dns_suffix = $(DNS_SUFFIX)

export TF_VAR_grafana_repo = $(GRAFANA_REPO)
export TF_VAR_prometheus_repo = $(PROMETHEUS_REPO)
export TF_VAR_alertmanager_repo = $(ALERTMANAGER_REPO)

export TF_VAR_grafana_image_version = $(GRAFANA_VERSION)
export TF_VAR_prometheus_image_version = $(PROMETHEUS_VERSION)
export TF_VAR_alertmanager_image_version = $(ALERTMANAGER_VERSION)

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

ecr-grafana:
	@echo "Generating grafana data source config..."
	@sed "s#{{PROMETHEUS_URL}}#$(PROMETEHUS_URL)#g" \
		grafana/default.yml > grafana/default.tmp.yml
	@echo "Updated grafana datasource config is created."
	cd grafana && \
	aws ecr get-login-password --profile $(AWS_PROFILE) --region ap-southeast-2 | docker login --username AWS --password-stdin $(AWS_ECR_REGISTRY) && \
	docker build . -t $(AWS_ECR_REGISTRY)/$(GRAFANA_REPO):$(GRAFANA_VERSION) && docker push $(AWS_ECR_REGISTRY)/$(GRAFANA_REPO):$(GRAFANA_VERSION)

ecr-prometheus:
	@echo "Generating prometheus config yaml..."
	@sed "s#{{CONFLUENT_CLOUD_API_KEY}}#$(CONFLUENT_CLOUD_API_KEY)#g; s#{{CONFLUENT_CLOUD_API_SECRET}}#$(CONFLUENT_CLOUD_API_SECRET)#g; s#{{ALERTMANAGER_URL}}#$(ALERTMANAGER_URL)#g" \
		prometheus/prometheus.yml > prometheus/prometheus.tmp.yml
	@echo "Updated Prometheus config is created."
	cd prometheus && \
	aws ecr get-login-password --profile $(AWS_PROFILE) --region ap-southeast-2 | docker login --username AWS --password-stdin $(AWS_ECR_REGISTRY) && \
	docker build . -t $(AWS_ECR_REGISTRY)/$(PROMETHEUS_REPO):$(PROMETHEUS_VERSION) && docker push $(AWS_ECR_REGISTRY)/$(PROMETHEUS_REPO):$(PROMETHEUS_VERSION)

ecr-alertmanager:
	@echo "Generating alergmanager config yaml..."
	@sed "s#{{ALERTMANAGER_WEBHOOK_URL}}#$(ALERTMANAGER_WEBHOOK_URL)#g" \
		alertmanager/config.yml > alertmanager/config.tmp.yml
	@echo "Updated Alertmanager config is created."
	cd alertmanager && \
	aws ecr get-login-password --profile $(AWS_PROFILE) --region ap-southeast-2 | docker login --username AWS --password-stdin $(AWS_ECR_REGISTRY) && \
	docker build . -t $(AWS_ECR_REGISTRY)/$(ALERTMANAGER_REPO):$(ALERTMANAGER_VERSION) && docker push $(AWS_ECR_REGISTRY)/$(ALERTMANAGER_REPO):$(ALERTMANAGER_VERSION)

ecr-buildAndPush: ecr-grafana ecr-prometheus ecr-alertmanager
