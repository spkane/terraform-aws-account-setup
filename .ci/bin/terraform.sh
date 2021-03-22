#!/usr/bin/env bash

set -e -u

TARGET_DIR="${HOME}/bin"
PATH=${PATH}:${TARGET_DIR}

TERRAFORM_VERSION=${1:-"0.14.8"}
OS=${2:-"darwin"}
TERRAFORM_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_${OS}_amd64.zip"
TERRAFORM_COMMAND="${TARGET_DIR}/terraform-${TERRAFORM_VERSION}"

installTerraform() {
  echo "Downloading terraform: ${TERRAFORM_URL}"

  cd /tmp || exit
  rm -f /tmp/terraform
  rm -f /tmp/terraform.zip
  curl '-#' -fL -o /tmp/terraform.zip ${TERRAFORM_URL}
  unzip -q -d /tmp /tmp/terraform.zip
  cp /tmp/terraform ${TARGET_DIR}/terraform-${TERRAFORM_VERSION}
  ${TARGET_DIR}/terraform-${TERRAFORM_VERSION} --version
}

verifyModulesAndPlugins() {
  echo "Verify plugins and modules can be resolved in $PWD"
  ${TERRAFORM_COMMAND} init -get -backend=false -input=false
}

formatCheck() {
  RESULT=$(${TERRAFORM_COMMAND} fmt -write=false)
  if [[ ! -z ${RESULT} ]] ; then
    echo The following files are formatted incorrectly: $RESULT
    exit 1
  fi
}

validate() {
  echo "Validating and checking format of terraform code in $PWD"
  ${TERRAFORM_COMMAND} validate -check-variables=false
  formatCheck
}
