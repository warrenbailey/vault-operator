CHART_REPO := http://jenkins-x-chartmuseum:8080
CURRENT=$(pwd)
NAME := vault-operator
OS := $(shell uname)

CHARTMUSEUM_CREDS_USR := $(shell cat /builder/home/basic-auth-user.json)
CHARTMUSEUM_CREDS_PSW := $(shell cat /builder/home/basic-auth-pass.json)

init:
	helm init --client-only

setup: init
	helm repo add jenkins-x-api https://chartmuseum.build.cd.jenkins-x.io 	
	helm repo add jenkinsxio https://chartmuseum.jx.cd.jenkins-x.io 

build: clean setup
	helm dependency build vault-operator
	helm lint vault-operator

install: clean setup build
	helm install vault-operator --name ${NAME}

upgrade: clean setup build
	helm upgrade ${NAME} vault-operator

delete:
	helm delete --purge ${NAME} vault-operator

clean:
	rm -rf vault-operator/charts
	rm -rf vault-operator/${NAME}*.tgz
	rm -rf vault-operator/requirements.lock

release: clean build
	sed -i -e "s/version:.*/version: $(VERSION)/" vault-operator/Chart.yaml
	sed -i -e "s/tag:.*/tag: $(VERSION)/" vault-operator/values.yaml
	helm package vault-operator
	curl --fail -u $(CHARTMUSEUM_CREDS_USR):$(CHARTMUSEUM_CREDS_PSW) --data-binary "@$(NAME)-$(VERSION).tgz" $(CHART_REPO)/api/charts