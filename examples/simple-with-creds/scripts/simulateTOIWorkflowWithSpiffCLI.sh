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
: Step 2 of the TOI process skipped cause no template or config  

: ======================
: Step 3 of the TOI process skipped cause no template or config  

: ======================
: Perform step 6 of the TOI process 
spiff++ --features control merge ./userInput/parametersFromCLI.yaml \
  ./toiPackage/toiPackageTemplateLibraryOne.yaml |& tee ${TMP}/ocm-toi-step6-output.yaml

: ======================
: Step 7 of the TOI process skipped cause no template or config  

: ======================
: Perform step 8 of the TOI process 
spiff++ --features control merge <(yq '.executors[0].parameterMapping' toiPackage/toiPackageOne.yaml) \
  ${TMP}/ocm-toi-step6-output.yaml \
  ./toiPackage/getCredentials.yaml |& tee ${INPUTS}/parameters


