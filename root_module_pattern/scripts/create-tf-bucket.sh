#!/bin/bash -e

function usage {
    cat <<EOF
$(basename ${0}) is a script for creating backend GCP bucket.

Usage:
    $(basename ${0}) [env] [project_id]
Arguments:
    env            Environment to create (e.g. "prod" | "dev")
    project_id     GCP Project ID
EOF
}

readonly ENV_NAME=${1}
readonly BUCKET_NAME="kaito2-flat-pattern-${ENV_NAME}"
readonly BUCKET_URI=gs://${BUCKET_NAME}/
readonly PROJECT_ID=${2}

if [ -z "${ENV_NAME}" ] || [ -z "${PROJECT_ID}" ]; then
  echo "Missing arguments"
  usage
  exit 1
fi

gsutil mb -p "${PROJECT_ID}" -c multi_regional -l asia "${BUCKET_URI}"
gsutil versioning set on "${BUCKET_URI}"
