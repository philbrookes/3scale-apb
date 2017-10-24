DOCKERHOST = docker.io
DOCKERORG = feedhenry
TAG = latest
USER=$(shell id -u)
PWS=$(shell pwd)

build_and_push: apb_build docker_push apb_push

.PHONY: build
build: apb_build

.PHONY: apb_build
apb_build:
	docker run --rm --privileged -v $(PWD):/mnt:z -v $(HOME)/.kube:/.kube -v /var/run/docker.sock:/var/run/docker.sock -u $(USER) docker.io/ansibleplaybookbundle/apb:latest prepare
	docker build -t $(DOCKERHOST)/$(DOCKERORG)/3scale-apb:$(TAG) .

.PHONY: docker_push
docker_push:
	docker push $(DOCKERHOST)/$(DOCKERORG)/3scale-apb:$(TAG)

.PHONY: apb_push
apb_push:
	docker run --rm --privileged -v $(PWD):/mnt:z -v $(HOME)/.kube:/.kube -v /var/run/docker.sock:/var/run/docker.sock -u $(USER) docker.io/ansibleplaybookbundle/apb:latest push

