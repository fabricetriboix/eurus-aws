SHELL := /bin/bash

FEATURES := networking

help:
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$|(^#--)' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m %-20s\033[0m %s\n", $$1, $$2}' \
		| sed -e 's/\[32m #-- /[33m/'

#-- Continuous integration

ci: $(foreach f,$(FEATURES),ci-feature-$(f)) ## Run all CI jobs

ci-feature-%:
	echo XXX && \
		ls -al "$$TF_PLUGIN_CACHE_DIR" || true && \
		echo XXX
	@cd features/$* && \
		time tofu fmt -check -recursive . && \
		time tofu init -upgrade && \
		time tofu validate
