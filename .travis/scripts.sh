#!/bin/bash

set -e

#
# Update Docker to the latest version.
#
# Examples:
#
#   update_docker
#
update_docker() {
  echo '{"experimental":true}' | sudo tee /etc/docker/daemon.json

  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo apt-key add -

  sudo add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable"

  sudo apt-get update
  sudo apt-get -y -o Dpkg::Options::="--force-confnew" install docker-ce
}

#
# Build multi-platform Docker image.
#
# $1 - The image name.
# $2 - The image tag or commit.
# $3 - The target platforms.
# $4 - Additional buildx arguments.
#
# Examples:
#
#   build_images "foo/bar"
#                "master" or "v1.2.3"
#                "linux/amd64,linux/arm64/v8"
#                "--push --build-arg FOO"
build_images() {
  declare -r image="${1}"
  declare -r tag="${2}"
  declare -r platforms="${3}"
  declare -r build_args="${@:4}"

  if [[ "${tag}" =~ ^v?([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
    local major="${BASH_REMATCH[1]}"
    local minor="${BASH_REMATCH[2]}"
    local patch="${BASH_REMATCH[3]}"

    # The manifests are listed on Docker Hub in reverse order.
    tags="${tags} --tag ${image}:${major}"
    tags="${tags} --tag ${image}:${major}.${minor}"
    tags="${tags} --tag ${image}:${major}.${minor}.${patch}"
    tags="${tags} --tag ${image}:latest"
  else
    tags="${tags} --tag ${image}:${tag}"
  fi

  docker buildx create --use
  docker buildx build \
    --progress=plain \
    --platform="${platforms}" \
    ${tags} \
    ${build_args} \
    .
}

#
# Pushes README file to Docker Hub.
#
# $1 - The image name.
# $2 - The file name.
# $3 - Docker user name.
# $4 - Docker user password.
#
# Examples:
#
#   pushReadme "foo/bar"
#              "README.md"
#              "username"
#              "password"
#
push_readme() {
  declare -r image="${1}"
  declare -r file_name="${2}"
  declare -r user_name="${3}"
  declare -r user_pswd="${4}"

  local token=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d '{"username": "'"${user_name}"'", "password": "'"${user_pswd}"'"}' \
    https://hub.docker.com/v2/users/login/ | jq -r .token)

  local code=$(jq -n --arg msg "$(<${file_name})" \
    '{"registry":"registry-1.docker.io","full_description": $msg }' | \
        curl -s -o /dev/null  -L -w "%{http_code}" \
           https://hub.docker.com/v2/repositories/"${image}"/ \
           -d @- -X PATCH \
           -H "Content-Type: application/json" \
           -H "Authorization: JWT ${token}")

  if [[ "${code}" = "200" ]]; then
    printf "Successfully pushed %s to Docker Hub\n" "${file_name}"
  else
    printf "Unable to push %s to Docker Hub, the response code: %s\n" "${file_name}" "${code}"
    exit 1
  fi
}

export DOCKER_CLI_EXPERIMENTAL=enabled

"$@"
