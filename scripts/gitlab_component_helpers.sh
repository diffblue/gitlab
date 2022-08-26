#!/usr/bin/env bash

set -euo pipefail

export CURL_TOKEN_HEADER="${CURL_TOKEN_HEADER:-"JOB-TOKEN"}"

# We only want to store/retrieve packages from the canonical `gitlab.org/gitlab` project
export CANONICAL_PACKAGES_PROJECT_ID="278964"

# Workhorse constants
export GITLAB_WORKHORSE_BINARIES_LIST="gitlab-resize-image gitlab-zip-cat gitlab-zip-metadata gitlab-workhorse"
export GITLAB_WORKHORSE_PACKAGE_FILES_LIST="${GITLAB_WORKHORSE_BINARIES_LIST} WORKHORSE_TREE"
export GITLAB_WORKHORSE_TREE=${GITLAB_WORKHORSE_TREE:-$(git rev-parse HEAD:workhorse)}
export GITLAB_WORKHORSE_PACKAGE="workhorse-${GITLAB_WORKHORSE_TREE}.tar.gz"
export GITLAB_WORKHORSE_PACKAGE_URL="https://gitlab.com/api/v4/projects/${CANONICAL_PACKAGES_PROJECT_ID}/packages/generic/${GITLAB_WORKHORSE_FOLDER}/${GITLAB_WORKHORSE_TREE}/${GITLAB_WORKHORSE_PACKAGE}"

# Assets constants
export GITLAB_ASSETS_PATHS_LIST="assets-hash.txt app/assets/javascripts/locale/ public/assets/ tmp/cache/assets/sprockets/ tmp/cache/babel-loader/ tmp/cache/vue-loader/"

if [[ "${FOSS_ONLY:-no}" = "1" ]]; then
  export GITLAB_EDITION="foss"
else
  export GITLAB_EDITION="ee"
fi
export GITLAB_ASSETS_HASH="${GITLAB_ASSETS_HASH:-"NO_HASH"}"
export GITLAB_ASSETS_PACKAGE="assets-${NODE_ENV}-${GITLAB_EDITION}-${GITLAB_ASSETS_HASH}.tar.gz"
export GITLAB_ASSETS_PACKAGE_URL="https://gitlab.com/api/v4/projects/${CANONICAL_PACKAGES_PROJECT_ID}/packages/generic/assets/${NODE_ENV}-${GITLAB_EDITION}-${GITLAB_ASSETS_HASH}/${GITLAB_ASSETS_PACKAGE}"

# Generic helper functions
function archive_doesnt_exist() {
  local package_url="${1}"

  status=$(curl -I --silent --retry 3 --output /dev/null -w "%{http_code}" "${package_url}")

  [[ "${status}" != "200" ]]
}

function create_package() {
  local archive_filename="${1}"
  local paths_to_archive="${2}"
  local tar_working_folder="${3:-.}"

  echoinfo "Running 'tar -czvf ${archive_filename} -C ${tar_working_folder} ${paths_to_archive}'"
  tar -czf ${archive_filename} -C ${tar_working_folder} ${paths_to_archive}
  du -h ${archive_filename}
}

function upload_package() {
  local archive_filename="${1}"
  local package_url="${2}"
  local token_header="${CURL_TOKEN_HEADER}"
  local token="${CI_JOB_TOKEN}"

  # We only want to upload artifacts to GitLab.com/gitlab-org/gitlab
  if [[ "${CI_SERVER_HOST:-gitlab.com}" != "gitlab.com" ]] || [[ "${CI_PROJECT_ID}" != "${CANONICAL_PACKAGES_PROJECT_ID}" ]]; then
    exit 1
  fi

  echoinfo "Uploading ${archive_filename} to ${package_url} ..."
  curl --fail --silent --retry 3 --header "${token_header}: ${token}" --upload-file "${archive_filename}" "${package_url}"
}

function read_curl_package() {
  local package_url="${1}"
  local token_header="${CURL_TOKEN_HEADER}"
  local token="${CI_JOB_TOKEN}"

  echoinfo "Downloading from ${package_url} ..."

  curl --fail --silent --retry 3 --header "${token_header}: ${token}" "${package_url}"
}

function extract_package() {
  local tar_working_folder="${1:-.}"
  mkdir -p "${tar_working_folder}"

  echoinfo "Extracting archive to ${tar_working_folder}"

  tar -xz -C ${tar_working_folder} < /dev/stdin
}

# Workhorse functions
function gitlab_workhorse_archive_doesnt_exist() {
  archive_doesnt_exist "${GITLAB_WORKHORSE_PACKAGE_URL}"
}

function create_gitlab_workhorse_package() {
  create_package "${GITLAB_WORKHORSE_PACKAGE}" "${GITLAB_WORKHORSE_FOLDER}" "${TMP_TEST_FOLDER}"
}

function upload_gitlab_workhorse_package() {
  upload_package "${GITLAB_WORKHORSE_PACKAGE}" "${GITLAB_WORKHORSE_PACKAGE_URL}"
}

function download_and_extract_gitlab_workhorse_package() {
  read_curl_package "${GITLAB_WORKHORSE_PACKAGE_URL}" | extract_package "${TMP_TEST_FOLDER}"
}

function select_gitlab_workhorse_essentials() {
  local tmp_path="${CI_PROJECT_DIR}/tmp/${GITLAB_WORKHORSE_FOLDER}"
  local original_gitlab_workhorse_path="${TMP_TEST_GITLAB_WORKHORSE_PATH}"

  mkdir -p ${tmp_path}
  cd ${original_gitlab_workhorse_path} && mv ${GITLAB_WORKHORSE_PACKAGE_FILES_LIST} ${tmp_path} && cd -
  rm -rf ${original_gitlab_workhorse_path}

  # Move the temp folder to its final destination
  mv ${tmp_path} ${TMP_TEST_FOLDER}
}

# Assets functions
function gitlab_assets_archive_doesnt_exist() {
  archive_doesnt_exist "${GITLAB_ASSETS_PACKAGE_URL}"
}

function download_and_extract_gitlab_assets() {
  read_curl_package "${GITLAB_ASSETS_PACKAGE_URL}" | extract_package
}

function create_gitlab_assets_package() {
  create_package "${GITLAB_ASSETS_PACKAGE}" "${GITLAB_ASSETS_PATHS_LIST}"
}

function upload_gitlab_assets_package() {
  upload_package "${GITLAB_ASSETS_PACKAGE}" "${GITLAB_ASSETS_PACKAGE_URL}"
}
