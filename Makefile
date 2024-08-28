# See https://tech.davis-hansson.com/p/make/
SHELL := bash
.DELETE_ON_ERROR:
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := all
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-print-directory
BIN := .tmp/bin
export PATH := $(BIN):$(PATH)
export GOBIN := $(abspath $(BIN))

LICENSE_YEAR_RANGE := 2024

BUF_VERSION := 1.39.0

.PHONY: help
help: ## Describe useful make targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "%-30s %s\n", $$1, $$2}'

.PHONY: all
all: ## Generate, build, and lint (default)
	$(MAKE) generate
	$(MAKE) build
	$(MAKE) lint

.PHONY: clean
clean: ## Delete intermediate build artifacts
	@# -X only removes untracked files, -d recurses into directories, -f actually removes files/dirs
	git clean -Xdf

.PHONY: build
build: $(BIN)/buf ## Build all APIs
	buf build

.PHONY: lint
lint: $(BIN)/buf ## Lint all APIs
	buf lint
	buf format -d --exit-code

.PHONY: upgrade
upgrade: $(BIN)/buf ## Upgrade dependencies
	buf dep update

.PHONY: generate
generate: $(BIN)/buf $(BIN)/license-header ## Format and regenerate license headers
	license-header \
		--license-type apache \
		--copyright-holder "Buf Technologies, Inc." \
		--year-range "$(LICENSE_YEAR_RANGE)"
	buf format -w

.PHONY: checkgenerate
checkgenerate:
	@# Used in CI to verify that `make generate` doesn't produce a diff.
	test -z "$$(git status --porcelain | tee /dev/stderr)"

$(BIN)/buf: Makefile
	@mkdir -p $(@D)
	go install github.com/bufbuild/buf/cmd/buf@v$(BUF_VERSION)

$(BIN)/license-header: Makefile
	@mkdir -p $(@D)
	go install github.com/bufbuild/buf/private/pkg/licenseheader/cmd/license-header@v$(BUF_VERSION)
