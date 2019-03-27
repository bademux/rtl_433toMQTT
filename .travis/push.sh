#!/bin/bash

set -e

#
# Creates and pushes a multi-platform manifest.
#
# $1 - The image name.
# $2 - The image tag.
# $3 - The platform-spceific manifests.
#
# Examples:
#
#   push_manifest "foo/bar" "1.0.0" "foo/bar:12bc34-linux-amd64"
#
push_manifest() {
  declare -r image="${1}"
  declare -r tag="${2}"
  declare -r manifests=(${3})

  docker manifest create --amend "${image}:${tag}" ${manifests[@]}
  docker manifest push --purge "${image}:${tag}"
}

#
# Creates and pushes multi-platform manifests using semantic versioning.
#
# $1 - The image name.
# $2 - The commit.
# $3 - The version.
# $4 - The target platforms.
#
# Examples:
#
#   push_manifests "foo/bar" "12bc34" "1.0.0" "linux/amd64,linux/arm64"
#
push_manifests() {
  declare -r image="${1}"
  declare -r commit="${2}"
  declare -r version="${3}"
  declare -r platforms=($(echo "${4}" | tr ',' '\n'))

  local manifests
  for platform in "${platforms[@]}"; do
    local platform_tag="${commit}-${platform//\//-}"
    manifests="${manifests} ${image}:${platform_tag}"
  done

  if [[ "${version}"  =~ ^([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
    local major="${BASH_REMATCH[1]}"
    local minor="${BASH_REMATCH[2]}"
    local patch="${BASH_REMATCH[3]}"

    push_manifest "${image}" "${major}" "${manifests}"
    push_manifest "${image}" "${major}.${minor}" "${manifests}"
    push_manifest "${image}" "${major}.${minor}.${patch}" "${manifests}"
    push_manifest "${image}" latest "${manifests}"
  else
    printf "Version %s is not a semantic version\n" "${version}"
    exit 1
  fi
}

#
# Deletes a tag on a remote server using Docker API v2.
#
# $1 - The image name.
# $2 - The image tag.
# $3 - The JWT.
#
# Examples:
#
#   delete_tag "foo/bar" "12bc34-linux-amd64" "token"
#
delete_tag() {
  declare -r image="${1}"
  declare -r tag="${2}"
  declare -r token="${3}"
  
  printf "deleting tag '%s' for image '%s'" "${tag}" "${image}"

  local code=$(curl -s -o /dev/null -LI -w "%{http_code}" \
    https://hub.docker.com/v2/repositories/"${image}"/tags/"${tag}"/ \
    -X DELETE \
    -H "Authorization: JWT ${token}")

  if [[ "${code}" = "204" ]]; then
    printf "Successfully deleted %s\n" "${image}:${tag}"
  else
    printf "Unable to delete %s, response code: %s\n" "${image}:${tag}" "${code}"
    exit 1
  fi
}

#
# Deletes platform-spceific image tags.
#
# $1 - The image name.
# $2 - The commit.
# $3 - The JWT.
# $4 - The target platforms.
#
# Examples:
#
#   delete_tags "foo/bar" "12bc34" "token" "linux/amd64,linux/arm64"
#
delete_tags() {
  declare -r image="${1}"
  declare -r commit="${2}"
  declare -r token="${3}"
  declare -r platforms=($(echo "${4}" | tr ',' '\n'))

  printf "deleting tags"

  for platform in "${platforms[@]}"; do
    local platform_tag="${commit}-${platform//\//-}"
    delete_tag "${image}" "${platform_tag}" "${token}"
  done
}

#
# Pushes README.md content to Docker Hub.
#
# $1 - The image name.
# $2 - The JWT.
#
# Examples:
#
#   push_readme "foo/bar" "token"
#
push_readme() {
  declare -r image="${1}"
  declare -r token="${2}"

  printf "pushing readme to docker hub"
    
  local code=$(jq -n --arg msg "$(<README.md)" \
    '{"registry":"registry-1.docker.io","full_description": $msg }' | \
        curl -s -o /dev/null  -L -w "%{http_code}" \
           https://cloud.docker.com/v2/repositories/"${image}"/ \
           -d @- -X PATCH \
           -H "Content-Type: application/json" \
           -H "Authorization: JWT ${token}")

  if [[ "${code}" = "200" ]]; then
    printf "Successfully pushed README to Docker Hub"
  else
    printf "Unable to push README to Docker Hub, response code: %s\n" "${code}"
    exit 1
  fi
}

#
# Pushes multi-platfomrm set of images and creates manifests.
#
# $1 - The image name.
# $2 - The commit.
# $3 - The tag.
# $4 - The target platforms.
#
# Examples:
#
#   push_images "foo/bar" "12bc34" "1.0.0" "linux/amd64,linux/arm64"
#
push() {
  declare -r image="${1}"
  declare -r commit="${2}"
  declare -r tag="${3}"
  declare -r platforms=($(echo "${4}" | tr ',' '\n'))

  printf "preparing to push '%s' with commit '%s' and tag '%s' for platforms '%s'\n" "${image}" "${commit}" "${tag}" "${platforms}"

  # Login into Docker repository
  echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

  if [[ "${tag}" =~ ^v?([0-9]+\.[0-9]+\.[0-9]+) ]]; then
    local version="${BASH_REMATCH[1]}"
  else
    printf "Tag %s is not a semantic version\n" "${tag}"
    exit 1
  fi

  for platform in "${platforms[@]}"; do
    local commit_tag="${commit}-${platform//\//-}"
    local docker_image_name="${image}:${commit_tag}"
    printf "pushing '%s'\n" "${docker_image_name}"
    docker -D push "${docker_image_name}"
  done

  local token=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d '{"username": "'"$DOCKER_USERNAME"'", "password": "'"$DOCKER_PASSWORD"'"}' \
    https://hub.docker.com/v2/users/login/ | jq -r .token)

  push_manifests "${image}" "${commit}" "${version}" "${4}"
  delete_tags "${image}" "${commit}" "${token}" "${4}"
  push_readme "${image}" "${token}"
}

push "${1}" "${2}" "${3}" "${4}"
