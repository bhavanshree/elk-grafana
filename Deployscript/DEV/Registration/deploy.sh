#!/bin/bash

APP_NAME=registration

IMAGE_NAME=$(docker inspect --format='{{.Config.Image}}' $APP_NAME)
docker stop $APP_NAME
docker rm $APP_NAME
docker rmi $IMAGE_NAME


DOCKER_USERNAME=<user_name>
DOCKER_PASSWORD=<password>
DOCKER_REPO=<Repo_name>


DOCKER_ACCESS_TOKEN=$(curl -s -H "Content-Type: application/json" -X POST -d '{"username": "'$DOCKER_USERNAME'", "password": "'$DOCKER_PASSWORD'"}' https://hub.docker.com/v2/users/login/ | jq -r .token)

VERSION=$(curl -s -H "Authorization: Bearer $DOCKER_ACCESS_TOKEN" https://registry.hub.docker.com/v2/repositories/decoders10/$DOCKER_REPO/tags | jq -r '.results | max_by(.last_updated) | .name')

docker pull decoders10/$DOCKER_REPO:$VERSION

docker run -d --name $APP_NAME --network dedalus-dev -p 7776:8082 \
-e SPRING_PROFILES_ACTIVE=dev \
decoders10/$DOCKER_REPO:$VERSION
