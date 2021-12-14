## Docker Build Versions
DOCKER_BUILD_IMAGE = golang:1.16.6
DOCKER_BASE_IMAGE = alpine:3.14
#######################################
# Docker
TAG ?= test
REGISTRY ?= spirosoik
CH06_IMAGE ?= ${REGISTRY}/ch06:${TAG}
################################################################################

.PHONY: build-linux
build-linux: # Building linux binaries
	@echo Building ${APP_VERSION} binary for linux
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -tags='${APP_VERSION}' -o bin/server ./cmd

.PHONY: build-mac
build-mac: # Building mac binaries
	@echo Building ${APP_VERSION} binary for linux
	GOOS=darwin GOARCH=amd64 CGO_ENABLED=0 go build -tags='${APP_VERSION}' -o bin/server ./cmd

.PHONY: build-image
build-image:  ## Build the docker image for mattermost-cloud
	@echo Building App Docker
	docker build \
	--build-arg DOCKER_BUILD_IMAGE=$(DOCKER_BUILD_IMAGE) \
	--build-arg DOCKER_BASE_IMAGE=$(DOCKER_BASE_IMAGE) \
	--build-arg APP_VERSION=$(TAG) \
	. -f Dockerfile -t $(CH06_IMAGE)

.PHONY: deploy-argo-app
deploy-argo-app:
	@echo Deploying Argo App
    argocd app \
	create ${APP} \
	--repo https://github.com/spirosoik/argocd-rollouts-cicd.git \
	--path deployments/argo --dest-namespace team-demo \
	--dest-server https://kubernetes.default.svc \
	--project ${PROJ} \
	--auth-token ${JWT} \
	--upsert

.PHONY: download-argo-cli
download-argo-cli:
	@echo Downloading Argo CLI
	curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
	chmod +x /usr/local/bin/argocd
	
.PHONY: check-linet
check-lint: ## Checks if golangci-lint exists
	@if ! [ -x "$$(command -v golangci-lint)" ]; then \
		echo "Downloading golangci-lint..."; \
		go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest; \
	fi;

.PHONY: lint
lint: check-lint # Run lint in go
	golangci-lint run ./...

.PHONY: push-image
push-image: build-image # Docker push
	@echo Pushing docker image
	docker push ${CH06_IMAGE}
