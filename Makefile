SHELL := /bin/bash

CHECKOV ?= 1
CHECKOV_QUIET ?= 1
MODULES := bootstrap
FEATURES := networking

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
ci: $(foreach f,$(MODULES),ci-module-$(f)) $(foreach f,$(FEATURES),ci-feature-$(f))

ci-module-%:
	@set -euxo pipefail && \
		cd modules/$* && \
		tofu fmt -check -recursive . && \
		[ $(CHECKOV_QUIET) -eq 1 ] && checkov_args=--quiet || checkov_args= && \
		if [ $(CHECKOV) -eq 1 ]; then checkov -d . $$checkov_args; fi

ci-feature-%:
	@set -euxo pipefail && \
		cd features/$* && \
		tofu fmt -check -recursive . && \
		tofu init -upgrade && \
		tofu validate && \
		[ $(CHECKOV_QUIET) -eq 1 ] && checkov_args=--quiet || checkov_args= && \
		if [ $(CHECKOV) -eq 1 ]; then checkov -d . $$checkov_args; fi
