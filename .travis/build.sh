#!/bin/bash

set -e

#
# Builds platform-specific Docker images.
#
# $1 - The image name.
# $2 - The image tag.
# $3 - The target platforms.
#
# Examples:
#
#   build_images "foo/bar" "1.0.0" "linux/amd64" "linux/armhf,linux/arm64"
#   build_images "foo/bar" "12bc34" "linux/amd64" "linux/armhf,linux/arm64"
#
build_images() {
  declare -r image="${1}"
  declare -r tag="${2}"
  declare -r platforms=($(echo "${3}" | tr ',' '\n'))

  # A workaround for https://github.com/moby/buildkit/issues/863
  mkfifo fifo.tar
  trap 'rm fifo.tar' EXIT

  for platform in "${platforms[@]}"; do

    # Form a platform tag, e.g. "1.0.0-linux-amd64".
    local platform_tag="${tag}-${platform//\//-}"
    printf "building image '%s' with tag '%s' for platforms '%s', target '%s'\n" "${image}" "${tag}" "${platform}" "${platform_tag}"

    # Build a platform spceific Docker image
    # and load it back to the local Docker.
    buildctl build --frontend dockerfile.v0 \
      --frontend-opt platform="${platform}" \
      --local dockerfile=. \
      --local context=. \
      --exporter docker \
      --exporter-opt name="${image}:${platform_tag}" \
      --exporter-opt output=fifo.tar \
      & docker -D load < fifo.tar & wait

  done
}

build_images "${1}" "${2}" "${3}"
