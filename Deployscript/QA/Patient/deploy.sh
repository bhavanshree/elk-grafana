#!/bin/bash

APP_NAME=patient

IMAGE_NAME=$(docker inspect --format='{{.Config.Image}}' $APP_NAME)
docker stop $APP_NAME
docker rm $APP_NAME
docker rmi $IMAGE_NAME


DOCKER_USERNAME=<User_name>
DOCKER_PASSWORD=<Password>
DOCKER_REPO=<Repo_name>


DOCKER_ACCESS_TOKEN=$(curl -s -H "Content-Type: application/json" -X POST -d '{"username": "'$DOCKER_USERNAME'", "password": "'$DOCKER_PASSWORD'"}' https://hub.docker.com/v2/users/login/ | jq -r .token)

VERSION=$(curl -s -H "Authorization: Bearer $DOCKER_ACCESS_TOKEN" https://registry.hub.docker.com/v2/repositories/decoders10/$DOCKER_REPO/tags | jq -r '.results | max_by(.last_updated) | .name')

docker pull decoders10/$DOCKER_REPO:$VERSION

docker run -d --name $APP_NAME --network dedalus-qa -p 8083:8083 \
-e SPRING_PROFILES_ACTIVE=qa \
decoders10/$DOCKER_REPO:$VERSION
