#!/bin/bash

set -e

declare -r proj_tmp="$PWD/tmp"

pre_install() {
  clone_source "git://git.osmocom.org/rtl-sdr.git" "0.6.0" "$proj_tmp/rtl-sdr" 
  clone_source "git://github.com/merbanan/rtl_433.git" "20.02" "$proj_tmp/rtl_433"

  # Registering file format recognizers since RUN command is used
  sudo docker run --privileged linuxkit/binfmt:v0.8
  # Update docker to the latest version and enable BuildKit
  bash ./.travis/scripts.sh update_docker
  sudo apt-get -y install jq git
}

clone_source() {
  declare -r url="${1}"
  declare -r tag="${2}"
  declare -r out_dir="${3}"
  declare -r user="$(id -u ${USER}):$(id -g ${USER})"

  echo "Cloning $url $tag"
  mkdir -p "$out_dir"
  git -c advice.detachedHead=false clone -b $tag --depth 1 "$url" "$out_dir"

}

post_install() {
  rm -rf $proj_tmp
}

build() {
  bash ./.travis/scripts.sh build_images "$@"
}

build_and_deploy() {
  echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin
  build "$@" --push
}


"$@"
