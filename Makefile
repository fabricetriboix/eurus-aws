SHELL := /bin/bash

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
ci: $(foreach f,$(FEATURES),ci-feature-$(f))

ci-feature-%:
	@cd features/$* && \
		time tofu fmt -check -recursive . && \
		time tofu init -upgrade && \
		time tofu validate && \
		time checkov -d .
