#!/bin/bash 


function printError {
  ec=$?
  : Exiting with exit code $ec 
  exit $ec 
}

trap printError EXIT

set -xe -o pipefail 

TMP=./tmp
ROOT=${TMP}/test/toi
INPUTS=${ROOT}/inputs

rm -rf $ROOT || :
mkdir -p $INPUTS || :

# Perform step #2 of the TOI process 
spiff++ --features control merge <(yq '.configTemplate'  ./toiExecutor/toiExecutorOne.yaml) \
  <(yq '.executors[0].config' ./toiPackage/toiPackageOne.yaml) \
  ./toiExecutor/toiExecutorTemplateLibraryOne.yaml \
  ./toiExecutor/toiExecutorTemplateLibraryTwo.yaml |& tee ${INPUTS}/config

# Perform step #5 of the TOI process 
spiff++ --features control merge <(yq '.configTemplate' toiPackage/toiPackageOne.yaml) \
  ./userInput/parametersFromCLI.yaml \
  ./toiPackage/toiPackageTemplateLibraryOne.yaml \
  ./toiPackage/toiPackageTemplateLibraryTwo.yaml |& tee ${TMP}/ocm-toi-step5-output.yaml

# Perform step #6 of the TOI process 
spiff++ --features control merge <(yq '.executors[0].parameterMapping' toiPackage/toiPackageOne.yaml) \
  ${TMP}/ocm-toi-step5-output.yaml \
  ./toiPackage/getCredentials.yaml |& tee ${INPUTS}/parameters


