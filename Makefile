UNAME := $(shell uname)

RM := rm -rf
DOWNLOAD_DIR := /tmp

# alp
ifeq ($(UNAME), Linux)
	ALP_FILE := alp_linux_amd64.tar.gz
else
	ALP_FILE := alp_darwin_arm64.tar.gz
endif
ALP_PATH := https://github.com/tkuchiki/alp/releases/download/v1.0.10/$(ALP_FILE)

# pt-query-digest
PT_QUERY_DIGEST_FILE := percona-toolkit_3.4.0-3.focal_amd64.deb
PT_QUERY_DIGEST_PATH := https://downloads.percona.com/downloads/percona-toolkit/3.4.0/binary/debian/focal/x86_64/$(PT_QUERY_DIGEST_FILE)

# node_exporter
ifeq ($(UNAME), Linux)
	NODE_EXPORTER_FILE := node_exporter-1.3.1.linux-amd64.tar.gz
else
	NODE_EXPORTER_FILE := node_exporter-1.3.1.darwin-arm64.tar.gz
endif
NODE_EXPORTER_DIR := $(subst .tar.gz,,$(NODE_EXPORTER_FILE))
NODE_EXPORTER_PATH := https://github.com/prometheus/node_exporter/releases/download/v1.3.1/$(NODE_EXPORTER_FILE)
.DEFAULT_GOAL := help

.PHONY: init
init: setup-alp setup-pt-query-digest setup-node-exporter ## Set up the necessary tools (Run only once in the environment)

.PHONY: setup-alp
setup-alp: ## Set up alp
	@echo -e "\033[32mInstalling alp...\033[0m"
	curl -o $(DOWNLOAD_DIR)/$(ALP_FILE) -OL $(ALP_PATH)
	tar -xvf $(DOWNLOAD_DIR)/$(ALP_FILE) -C /tmp
	sudo install $(DOWNLOAD_DIR)/alp /usr/local/bin/alp
	$(RM) $(DOWNLOAD_DIR)/$(ALP_FILE) $(DOWNLOAD_DIR)/alp

.PHONY: setup-pt-query-digest
setup-pt-query-digest: ## Set up pt-query-digest
	@echo -e "\033[32mInstalling pt-query-digest...\033[0m"
	curl -o $(DOWNLOAD_DIR)/$(PT_QUERY_DIGEST_FILE) -OL $(PT_QUERY_DIGEST_PATH)
	sudo apt-get install -y gdebi
	sudo gdebi -n $(DOWNLOAD_DIR)/$(PT_QUERY_DIGEST_FILE)
	$(RM) $(DOWNLOAD_DIR)/$(PT_QUERY_DIGEST_FILE)

.PHONY: setup-node-exporter
setup-node-exporter: --make-system-dir ## Set up node_exporter
	@echo -e "\033[32mInstalling node_exporter...\033[0m"
	curl -o $(DOWNLOAD_DIR)/$(NODE_EXPORTER_FILE) -OL $(NODE_EXPORTER_PATH)
	tar -xvf $(DOWNLOAD_DIR)/$(NODE_EXPORTER_FILE) -C /tmp
	sudo install $(DOWNLOAD_DIR)/$(NODE_EXPORTER_DIR)/node_exporter /usr/local/bin/node_exporter
	$(RM) $(DOWNLOAD_DIR)/$(NODE_EXPORTER_FILE) $(DOWNLOAD_DIR)/$(NODE_EXPORTER_DIR)
	sudo cp ~/node_exporter/node_exporter.service /usr/lib/systemd/system/node_exporter.service
	sudo systemctl daemon-reload
	sudo systemctl enable --now node_exporter.service

.PHONY: help
help: ## Display this help screen
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-26s\033[0m %s\n", $$1, $$2}'

# Private Targets
--make-system-dir:
	mkdir -p /usr/lib/systemd/system
