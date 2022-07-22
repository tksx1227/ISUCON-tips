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

ALP_SORT := sum
ALP_DUMP_NAME := alp.dump
ALP_DUMP_PATH := /tmp/$(ALP_DUMP_NAME)
ALPM := "/api/.+"
ALP_OUT_FORMAT := count,method,uri,min,max,sum,avg,p99

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

# Prometheus
ifeq ($(UNAME), Linux)
	PROMETHEUS_FILE := prometheus-2.37.0.linux-amd64.tar.gz
else
	PROMETHEUS_FILE := prometheus-2.37.0.darwin-arm64.tar.gz
endif
PROMETHEUS_DIR := $(subst .tar.gz,,$(PROMETHEUS_FILE))
PROMETHEUS_PATH := https://github.com/prometheus/prometheus/releases/download/v2.37.0/$(PROMETHEUS_FILE)
NODE_EXPORTER_PATH := https://github.com/prometheus/node_exporter/releases/download/v1.3.1/$(NODE_EXPORTER_FILE)

# Database
MYSQL_HOST := 127.0.0.1
MYSQL_PORT := 3306
MYSQL_USER := isucon
MYSQL_DBNAME := isucondition
MYSQL_PASS := isucon
MYSQL := mysql -h$(MYSQL_HOST) -P$(MYSQL_PORT) -u$(MYSQL_USER) -p$(MYSQL_PASS) $(MYSQL_DBNAME)
SLOW_LOG := /var/log/mysql/slow-query.log

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
	sudo cp $(PWD)/node_exporter/node_exporter.service /usr/lib/systemd/system/node_exporter.service
	sudo systemctl daemon-reload
	sudo systemctl enable --now node_exporter.service

.PHONY: setup-prometheus
setup-prometheus: --make-system-dir --make-prometheus-dir ## Set up Prometheus
	@echo -e "\033[32mInstalling prometheus...\033[0m"
	curl -o $(DOWNLOAD_DIR)/$(PROMETHEUS_FILE) -OL $(PROMETHEUS_PATH)
	tar -xvf $(DOWNLOAD_DIR)/$(PROMETHEUS_FILE) -C /tmp
	sudo install $(DOWNLOAD_DIR)/$(PROMETHEUS_DIR)/prometheus /usr/local/bin/prometheus
	$(RM) $(DOWNLOAD_DIR)/$(PROMETHEUS_FILE) $(DOWNLOAD_DIR)/$(PROMETHEUS_DIR)
	sudo cp $(PWD)/prometheus/prometheus.service /usr/lib/systemd/system/prometheus.service
	sudo cp $(PWD)/prometheus/prometheus_config.yml /etc/prometheus/prometheus_config.yml
	sudo systemctl daemon-reload
	sudo systemctl enable --now prometheus.service

.PHONY: alp
alp: ## Access analysis by alp
	sudo alp ltsv --file=/var/log/nginx/access.log --nosave-pos --pos /tmp/alp.pos --sort $(ALP_SORT) --reverse -o $(ALP_OUT_FORMAT) -m $(ALPM) -q

.PHONY: alpsave
alpsave: ## Access analysis by alp (Generate dump file and save read position)
	sudo alp ltsv --file /var/log/nginx/access.log --pos /tmp/alp.pos --dump $(ALP_DUMP_PATH) --sort $(ALP_SORT) --reverse -o $(ALP_OUT_FORMAT) -m $(ALPM) -q

.PHONY: alpload
alpload: ## Access analysis by alp (Load dump file)
	sudo alp ltsv --load $(ALP_DUMP_PATH) --sort $(ALP_SORT) --reverse -o $(ALP_OUT_FORMAT) -q

.PHONY: slow-on
slow-on: ## Start logging slow-queries
	sudo rm $(SLOW_LOG)
	sudo systemctl restart mysql
	$(MYSQL) -e "\
		set global slow_query_log_file='$(SLOW_LOG)'; \
		set global long_query_time=0; \
		set global slow_query_log=ON;"

.PHONY: slow-off
slow-off: ## Stop logging slow-queries
	$(MYSQL) -e "set global slow_query_log=OFF;"

.PHONY: slow-show
slow-show: ## Show metrics of slow-queries
	sudo pt-query-digest $(SLOW_LOG)

.PHONY: help
help: ## Display this help screen
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-26s\033[0m %s\n", $$1, $$2}'

# Private Targets
--make-system-dir:
	sudo mkdir -p /usr/lib/systemd/system

--make-prometheus-dir:
	sudo mkdir -p /etc/prometheus
