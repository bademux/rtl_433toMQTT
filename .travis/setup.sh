#!/bin/bash

set -e

#
# Sets envioment for multi-platform builds.
#
# $1 - The target platforms.
#
# Examples:
#
#   setup "linux/armhf,linux/arm64"
#
setup() {
  declare -r platforms=($(echo "${1}" | tr ',' '\n'))

  # Enabling server experimental features
  echo '{"experimental":true}' | sudo tee /etc/docker/daemon.json
  sudo service docker restart

  # Registering file format recognizers
  sudo docker run --privileged linuxkit/binfmt:v0.6

  local worker_platforms
  for platform in "${platforms[@]}"; do
    worker_platforms="${worker_platforms} --oci-worker-platform ${platform}"
  done

  if [[ "${BUILDKIT_HOST}" =~ ^tcp://.*:([0-9]*) ]]; then
    local port="${BASH_REMATCH[1]}"
  else
    printf "Port is not specified in \n" "${BUILDKIT_HOST}"
    exit 1
  fi

  # Starting BuildKit in a container
  sudo docker run -d --privileged \
    -p "${port}":"${port}" \
    --name buildkit moby/buildkit:latest \
    --addr "${BUILDKIT_HOST}" \
    ${worker_platforms}

  # Extracting buildctl into /usr/bin/
  sudo docker cp buildkit:/usr/bin/buildctl /usr/bin/
}

setup "${1}"
