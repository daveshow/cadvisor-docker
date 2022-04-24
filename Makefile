DOCKER_TAG ?= cadvisor-docker-$(USER)
MAKE               := make --no-print-directory
CHDIR_SHELL        := $(SHELL)

DESCRIBE           := $(shell git describe --match "v*" --always --tags)
DESCRIBE_PARTS     := $(subst -, ,$(DESCRIBE))

VERSION_TAG        := $(word 1,$(DESCRIBE_PARTS))
COMMITS_SINCE_TAG  := $(word 2,$(DESCRIBE_PARTS))

VERSION            := $(subst v,,$(VERSION_TAG))
VERSION_PARTS      := $(subst ., ,$(VERSION))

MAJOR              := $(word 1,$(VERSION_PARTS))
MINOR              := $(word 2,$(VERSION_PARTS))
MICRO              := $(word 3,$(VERSION_PARTS))

NEXT_MAJOR         := $(shell echo $$(($(MAJOR)+1)))
NEXT_MINOR         := $(shell echo $$(($(MINOR)+1)))
NEXT_MICRO          = $(shell echo $$(($(MICRO)+$(COMMITS_SINCE_TAG))))

ifeq ($(strip $(COMMITS_SINCE_TAG)),)
CURRENT_VERSION_MICRO := $(MAJOR).$(MINOR).$(MICRO)
CURRENT_VERSION_MINOR := $(CURRENT_VERSION_MICRO)
CURRENT_VERSION_MAJOR := $(CURRENT_VERSION_MICRO)
else
CURRENT_VERSION_MICRO := $(MAJOR).$(MINOR).$(NEXT_MICRO)
CURRENT_VERSION_MINOR := $(MAJOR).$(NEXT_MINOR).0
CURRENT_VERSION_MAJOR := $(NEXT_MAJOR).0.0
endif

define chdir
	$(eval _D=$(firstword $(1) $(@D)))
	$(info $(MAKE): cd $(_D)) $(eval SHELL = cd $(_D); $(CHDIR_SHELL))
endef

DATE                = $(shell date +'%d.%m.%Y')
TIME                = $(shell date +'%H:%M:%S')
COMMIT             := $(shell git rev-parse HEAD)
AUTHOR             := $(firstword $(subst @, ,$(shell git show --format="%aE" $(COMMIT))))
BRANCH_NAME        := $(shell git rev-parse --abbrev-ref HEAD)

TAG_MESSAGE         = "$(TIME) $(DATE) $(AUTHOR) $(BRANCH_NAME)"
COMMIT_MESSAGE     := $(shell git log --format=%B -n 1 $(COMMIT))
PREV_FROM_TAG_MESSAGES	:= $(shell git log $(shell git describe --tags --abbrev=0)..HEAD --pretty=format:"%s")

CURRENT_TAG_MICRO  := "v$(CURRENT_VERSION_MICRO)"
CURRENT_TAG_MINOR  := "v$(CURRENT_VERSION_MINOR)"
CURRENT_TAG_MAJOR  := "v$(CURRENT_VERSION_MAJOR)"

ifeq ($(PREFIX),)
    PREFIX := ${HOME}
endif

.PHONY: all
all: check

# --- Version commands ---

.PHONY: version
version:
	@$(MAKE) version-micro

.PHONY: version-micro
version-micro:
	@echo "$(CURRENT_VERSION_MICRO)"

.PHONY: version-minor
version-minor:
	@echo "$(CURRENT_VERSION_MINOR)"

.PHONY: version-major
version-major:
	@echo "$(CURRENT_VERSION_MAJOR)"

# --- Tag commands ---

.PHONY: tag-micro
tag-micro:
	@echo "$(CURRENT_TAG_MICRO)"

.PHONY: tag-minor
tag-minor:
	@echo "$(CURRENT_TAG_MINOR)"

.PHONY: tag-major
tag-major:
	@echo "$(CURRENT_TAG_MAJOR)"

# -- Meta info ---

.PHONY: tag-message
tag-message:
	@echo "$(TAG_MESSAGE)"

.PHONY: commit-message
commit-message:
	@echo "$(COMMIT_MESSAGE)"

.PHONY: prev-tag-commit-message
prev-tag-commit-message:
	@echo "$(PREV_FROM_TAG_MESSAGES)"

.PHONY: install-hooks
install-hooks:
	pre-commit install

.PHONY: test
test:
	@echo "test"

.PHONY: check
check:
	pre-commit run --all-files

.PHONY: makestaging
makestaging:
	@git checkout main
	@git pull
# ifeq ($(shell git show-ref --verify --quiet "refs/heads/staging_$(CURRENT_VERSION_MICRO)"),)
# 	@git branch -D staging_$(CURRENT_VERSION_MICRO)
# endif
	@git checkout -b staging_$(CURRENT_VERSION_MICRO)

.PHONY: maketagmicro
maketagmicro: makestaging
	@git tag $(CURRENT_TAG_MICRO) -m "$(PREV_FROM_TAG_MESSAGES)"
	@git push --tags

.PHONY: maketagminor
maketagminor: makestaging
	@git tag $(CURRENT_TAG_MINOR) -m "$(PREV_FROM_TAG_MESSAGES)"
	@git push --tags

.PHONY: pushmerge
pushmerge:
	@git push -o merge_request.create -o merge_request.target=main -o merge_request.remove_source_branch origin $(BRANCH_NAME)
