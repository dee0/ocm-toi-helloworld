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
spiff++ merge ./toiExecutor/toiExecutorConfig.yaml ./toiExecutor/toiPackageExecutorConfig.yaml ./toiExecutor/toiExecutorTemplateLibrary1.yaml ./toiExecutor/toiExecutorTemplateLibrary2.yaml |& tee ${INPUTS}/config

# Perform step #5 of the TOI process 
spiff++ merge ./toiPackage/toiPackageConfigTemplate.yaml ./userInput/parametersFromCLI.yaml ./toiPackage/toiPackageTemplateLibrary1.yaml ./toiPackage/toiPackageTemplateLibrary2.yaml ./toiPackage/getCredentials.yaml |& tee ${TMP}/ocm-toi-step5-output.yaml




