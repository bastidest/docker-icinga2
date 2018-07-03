#!/bin/bash

export COMPOSE_PROJECT_NAME=icingafull

if [ "$1" == "reset" ]; then
    docker-compose -f icinga-full.yml down &&\
    sudo rm -rf data-full &&\
    docker-compose -f icinga-full.yml up --build
else
    docker-compose -f icinga-full.yml up --build
fi

