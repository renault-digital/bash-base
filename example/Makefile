SHELL := $(shell which bash)
! = @source ../bin/bash-base &&
# Note: if run in Alpine on pipeline, run 'apk add --no-cache bash make' if bash/make is not ready


# import env variable from dotenv if need
#include .env


.EXPORT_ALL_VARIABLES:

KEYCLOAK_USER := admin
KEYCLOAK_PASSWORD := pwdrd
SERVER_PORT_MAP_TO ?= 8089


.DEFAULT_GOAL := help
.PHONY: help start stop


help:  ## print this list
	@egrep -h '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


start:  ## start keycloak
	$!print_header "start keycloak ..." && \
	confirm_to_continue KEYCLOAK_USER KEYCLOAK_PASSWORD SERVER_PORT_MAP_TO

	@# this command will start the keycloak server
	docker run -e KEYCLOAK_USER=${KEYCLOAK_USER} -e KEYCLOAK_PASSWORD=${KEYCLOAK_PASSWORD} -i -p ${SERVER_PORT_MAP_TO}:8080 jboss/keycloak:10.0.1 &

	@$!wait_for 'curl -sL -o /dev/null -w "%{http_code}" "http://localhost:${SERVER_PORT_MAP_TO}/auth" | grep -q "200"' keycloak && \
	prc_filter_by_port ${SERVER_PORT_MAP_TO} && \
	print_success "now you can open http://localhost:${SERVER_PORT_MAP_TO}"


stop:  ## stop keycloak
	$!print_header "stop keycloak ..."

	$(eval container_id := $(shell docker ps | grep ":${SERVER_PORT_MAP_TO}->" | cut -d' '  -f1 ))
	@if [ -n "${container_id}" ]; then docker kill ${container_id}; fi

	$!print_success "The keycloak stopped."
