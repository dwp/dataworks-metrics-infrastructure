SHELL:=bash

aws_profile=default
aws_profile_mgt_dev=dataworks-management-dev
aws_region=eu-west-2
enterprise_github_url=`aws --region ${aws_region} --profile ${aws_profile_mgt_dev} secretsmanager get-secret-value --secret-id /concourse/dataworks/dataworks | jq .SecretBinary | tr -d "\"" | base64 -D | jq .enterprise_github_url | tr -d "\""`

default: help

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: bootstrap
bootstrap: ## Bootstrap local environment for first use
	make git-hooks
	pip3 install --user Jinja2 PyYAML boto3
	@{ \
		export AWS_PROFILE=$(aws_profile); \
		export AWS_PROFILE_MGT_DEV=$(aws_profile_mgt_dev); \
		export AWS_REGION=$(aws_region); \
		python3 bootstrap_terraform.py; \
	}
	@if [ ! -d "config/grafana/provisioning/dashboards" ]; then git clone https://$(enterprise_github_url)/dip/dataworks-dashboards.git config/grafana/provisioning/dashboards; fi
	@terraform fmt -recursive

.PHONY: git-hooks
git-hooks: ## Set up hooks in .git/hooks
	@{ \
		HOOK_DIR=.git/hooks; \
		for hook in $(shell ls .githooks); do \
			if [ ! -h $${HOOK_DIR}/$${hook} -a -x $${HOOK_DIR}/$${hook} ]; then \
				mv $${HOOK_DIR}/$${hook} $${HOOK_DIR}/$${hook}.local; \
				echo "moved existing $${hook} to $${hook}.local"; \
			fi; \
			ln -s -f ../../.githooks/$${hook} $${HOOK_DIR}/$${hook}; \
		done \
	}

.PHONY: terraform-init
terraform-init: ## Run `terraform init` from repo root
	terraform init

.PHONY: terraform-plan
terraform-plan: ## Run `terraform plan` from repo root
	terraform plan

.PHONY: terraform-apply
terraform-apply: ## Run `terraform apply` from repo root
	terraform apply 
