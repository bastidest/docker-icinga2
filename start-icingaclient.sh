#!/bin/bash

COMPOSE_PROJECT_NAME=icingaclient

if [ "$1" == "reset" ]; then
    docker-compose -f icinga-client.yml down &&\
    sudo rm -rf data-client &&\
    docker-compose -f icinga-client.yml up --build
else
    docker-compose -f icinga-client.yml up --build
fi

