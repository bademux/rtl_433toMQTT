#!/bin/bash

set -e

build_crtl() {
 $(dirname "$BASH_SOURCE")/scripts.sh $@
}

pre_install() {
  echo "--- start"
  # Registering file format recognizers since RUN command is used
  sudo docker run --privileged linuxkit/binfmt:v0.8
  # Update docker to the latest version and enable BuildKit
  build_crtl update_docker
}

post_install() {
  echo "--- end"
}

test_build() {
  declare -r image="${1}"
  declare -r tag="${2}"

  build_crtl build_images $image $tag "linux/amd64" 
}

build_and_deploy() {
  declare -r image="${1}"
  declare -r tag="${2}"

  echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin
  build_crtl build_images $image $tag "linux/amd64,linux/386,linux/arm/v6,linux/arm/v7,linux/arm64/v8" --push
}


"$@"
