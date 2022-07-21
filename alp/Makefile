UNAME := $(shell uname)

ALP_PATH = https://github.com/tkuchiki/alp/releases/download/v1.0.10/$(ALP_FILE)

ifeq ($(UNAME), Linux)
	# Linux
	ALP_FILE := alp_linux_amd64.tar.gz
else
	# M1Mac
	ALP_FILE := alp_darwin_arm64.tar.gz
endif

all:
	@echo $(ALP_PATH)

.PHONY: set-up-alp
set-up-alp:
	@echo -e "\033[32mInstalling alp...\033[0m"
	curl -o /tmp/$(ALP_FILE) -OL $(ALP_PATH)
	tar -xvf /tmp/$(ALP_FILE) -C /tmp
	sudo install /tmp/alp /usr/local/bin/alp
	rm /tmp/$(ALP_FILE) /tmp/alp
