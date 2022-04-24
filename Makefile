DOCKER_TAG ?= cadvisor-docker-$(USER)

.PHONY: all
all: check

.PHONY: install-hooks
install-hooks:
	pre-commit install

.PHONY: check
check:
	pre-commit run --all-files
