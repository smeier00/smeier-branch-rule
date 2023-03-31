SHELL         := /bin/bash
VERSION       := $(shell git describe --always --long --dirty)
SHORT_VERSION := $(shell git describe --always --abbrev=0)
BRANCH        := $(shell git symbolic-ref --short -q HEAD)

# If branch is empty we are pushing a tag so PROD = yes
BRANCH ?= main
ifeq ($(BRANCH),main)
export ENV         := production
DESTINATIONDATASETID := $(ENV)_th_adversary
DESTINATIONTABLE     := $(ENV)_dwell_sigsci

else
export ENV         := development
DESTINATIONDATASETID := $(ENV)_th_adversary
DESTINATIONTABLE     := $(ENV)_dwell_sigsci
endif

########################################
# Common Targets
########################################

.PHONY: install
install: bqd

.PHONY: bqd
bqd:
ifeq (, $(shell which bqd))
	pip3 install --upgrade 'bq-deploy @ git+ssh://git@github.intuit.com/KAOS/bq-deploy@vLatest' 
endif

########################################
# Functions
########################################


define seed_data
  echo "creating seed data: ENV=$(ENV) DESTINATIONDATASETID=$(DESTINATIONDATASETID), DESTINATIONTABLE=$(DESTINATIONTABLE)"
endef

########################################
# Shell Specific Configuration
########################################

SED_CMD  = sed -i ''
ifeq ($(OSTYPE),Darwin)
SED_CMD = sed -i ''
endif 

########################################
# Deployment targets
########################################

.PHONY: debug
debug:
	$(call seed_data)

	#Example passing ENV to python
	#python3 scripts/example_python_env.py

.PHONY: validate
validate:
	bqd validate ./queries/kaos-data-plane-001/huntsmen_views/TI:th_adversary:dwell_sigsci.yaml

# Example deployment
.PHONY: deploy
deploy:
ifeq (,$(findstring dirty,$(VERSION)))
	$(SED_CMD) -e "s;DESTINATIONDATASETID;$(DESTINATIONDATASETID);" \
	           -e "s;DESTINATIONTABLE;$(DESTINATIONTABLE);" \
	           ./queries/kaos-data-plane-001/huntsmen_views/TI:th_adversary:dwell_sigsci.yaml
	echo "bqd deploy ./queries/kaos-data-plane-001/huntsmen_views/TI:th_adversary:dwell_sigsci.yaml"
	@git reset --hard
else
	$(error Current branch is dirty.  Not deploying)
endif
