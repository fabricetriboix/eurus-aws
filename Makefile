# When running the Makefile, you need to ensure the following
# environment variables are set:
#   - AWS_REGION: Region where the platform is deployed

SHELL := /bin/bash

CHECKOV ?= 1
CHECKOV_QUIET ?= 1
MODULES := bootstrap ecs-cluster
FEATURES := networking amg amp
BOOTSTRAPS := all
ENVS := common-nonprod dev
ACTION ?= apply

# Feature name only (e.g. grafana, networking, amg) — not the full stack path
STACK_UNIT ?=

define stack_queue_flags
$(if $(STACK_UNIT),--queue-include-dir "**/feature-$(STACK_UNIT)" --queue-strict-include,)
endef

## This help screen
help:
	@printf "Available targets:\n\n"
	@awk '/^[a-zA-Z\-\_0-9%:\\]+/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = $$1; \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			gsub("\\\\", "", helpCommand); \
			gsub(":+$$", "", helpCommand); \
			printf "  \x1b[32;01m%-20s\x1b[0m %s\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST) | sort -u
	@printf "\n"

## Run CI for the modules
ci-module: $(foreach f,$(MODULES),ci-module-$(f))
ci-modules: ci-module

## Run CI for the features
ci-feature: $(foreach f,$(FEATURES),ci-feature-$(f))
ci-features: ci-feature

## Run CI for the environments
ci-env: $(foreach f,$(ENVS),ci-env-$(f))
ci-envs: ci-env

## Run all CI jobs
ci: ci-module ci-feature $(foreach f,$(BOOTSTRAPS),ci-bootstrap-$(f)) ci-env

## Run all CD jobs
cd: $(foreach f,$(ENVS),cd-env-$(f))

ci-module-%:
	@set -euxo pipefail && \
		cd module/$* && \
		tofu fmt -check -recursive . && \
		if [ $(CHECKOV_QUIET) -eq 1 ]; then checkov_args=--quiet; else checkov_args=; fi && \
		if [ $(CHECKOV) -eq 1 ]; then checkov -d . $$checkov_args; fi

ci-feature-%:
	@set -euxo pipefail && \
		cd feature/$* && \
		tofu fmt -check -recursive . && \
		tofu init -upgrade && \
		tofu validate && \
		if [ $(CHECKOV_QUIET) -eq 1 ]; then checkov_args=--quiet; else checkov_args=; fi && \
		if [ $(CHECKOV) -eq 1 ]; then checkov -d . $$checkov_args; fi

ci-bootstrap-%:
	@set -euxo pipefail && \
		cd bootstrap/$* && \
		tofu fmt -check -recursive . && \
		terragrunt init -upgrade && \
		terragrunt validate && \
		if [ $(CHECKOV_QUIET) -eq 1 ]; then checkov_args=--quiet; else checkov_args=; fi && \
		if [ $(CHECKOV) -eq 1 ]; then checkov -d . $$checkov_args; fi

ci-env-%:
	@set -euxo pipefail && \
		cd env/$* && \
		export TF_INPUT=0 && \
		terragrunt stack generate && \
		terragrunt --non-interactive stack run plan \
			--queue-include-external && \
		if [ $(CHECKOV_QUIET) -eq 1 ]; then checkov_args=--quiet; else checkov_args=; fi && \
		if [ $(CHECKOV) -eq 1 ]; then checkov -d . $$checkov_args; fi

cd-env-%:
	@set -euxo pipefail && \
		cd env/$* && \
		export TF_INPUT=0 && \
		terragrunt stack generate && \
		terragrunt --non-interactive stack run $(ACTION) \
			--queue-include-external \
			-- -auto-approve

## Preview destroy for a single feature in an environment (runs: tofu plan -destroy)
plan-destroy-env-unit-%:
	@set -euxo pipefail && \
		test -n "$(STACK_UNIT)" || { echo "STACK_UNIT is required (feature name, e.g. grafana)"; exit 1; } && \
		cd env/$* && \
		export TF_INPUT=0 && \
		terragrunt stack generate && \
		terragrunt --non-interactive stack run plan \
			$(stack_queue_flags) \
			--queue-include-external \
			-- -destroy

## Destroy a single feature in an environment (runs: tofu destroy)
destroy-env-unit-%:
	@set -euxo pipefail && \
		test -n "$(STACK_UNIT)" || { echo "STACK_UNIT is required (feature name, e.g. grafana)"; exit 1; } && \
		cd env/$* && \
		export TF_INPUT=0 && \
		terragrunt stack generate && \
		terragrunt --non-interactive stack run destroy \
			$(stack_queue_flags) \
			--queue-include-external \
			-- -auto-approve
