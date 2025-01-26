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

: ======================
: Perform step 2 of the TOI process 
spiff++ --features control merge <(yq '.executors[0].config' ./toiPackage/toiPackageOne.yaml) \
  ./toiExecutor/toiExecutorTemplateLibraryOne.yaml \
  ./toiExecutor/toiExecutorTemplateLibraryTwo.yaml |& tee ${INPUTS}/ocm-toi-step2-output.yaml

: ======================
: Perform step 3 of the TOI process 
spiff++ --features control merge <(yq '.configTemplate'  ./toiExecutor/toiExecutorOne.yaml) \
  ${INPUTS}/ocm-toi-step2-output.yaml \
  ./toiExecutor/toiExecutorTemplateLibraryOne.yaml \
  ./toiExecutor/toiExecutorTemplateLibraryTwo.yaml |& tee ${INPUTS}/config

: ======================
: Perform step 6 of the TOI process 
spiff++ --features control merge ./userInput/parametersFromCLI.yaml \
  ./toiPackage/toiPackageTemplateLibraryOne.yaml \
  ./toiPackage/toiPackageTemplateLibraryTwo.yaml |& tee ${TMP}/ocm-toi-step6-output.yaml

: ======================
: Perform step 7 of the TOI process 
spiff++ --features control merge <(yq '.configTemplate' toiPackage/toiPackageOne.yaml) \
  ${TMP}/ocm-toi-step6-output.yaml \
  ./toiPackage/toiPackageTemplateLibraryOne.yaml \
  ./toiPackage/toiPackageTemplateLibraryTwo.yaml |& tee ${TMP}/ocm-toi-step7-output.yaml

: ======================
: Perform step 8 of the TOI process 
spiff++ --features control merge <(yq '.executors[0].parameterMapping' toiPackage/toiPackageOne.yaml) \
  ${TMP}/ocm-toi-step7-output.yaml \
  ./toiPackage/getCredentials.yaml |& tee ${INPUTS}/parameters


