SHELL := /bin/bash

CHECKOV ?= 1
CHECKOV_QUIET ?= 1
MODULES := bootstrap
FEATURES := networking
BOOTSTRAPS := common-nonprod

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

## Run all CI jobs
ci: $(foreach f,$(MODULES),ci-module-$(f)) $(foreach f,$(FEATURES),ci-feature-$(f)) $(foreach f,$(BOOTSTRAPS),ci-bootstrap-$(f))

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
