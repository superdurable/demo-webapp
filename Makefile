MAKEFLAGS += --no-builtin-rules
.SUFFIXES:

APP := bin/dataset-deal-webapp
IMAGE ?= dataset-deal-webapp:local

.PHONY: build docker-build postgres-down postgres-up run test

build:
	@mkdir -p bin
	GOWORK=off go build -o $(APP) ./cmd/server

run: build
	./scripts/run-local.sh

postgres-up:
	docker compose up -d --wait postgres

postgres-down:
	docker compose down

docker-build:
	docker build --tag $(IMAGE) .

test:
	GOWORK=off go test ./...
