#!/bin/bash 

function printError {
  ec=$?
  : Exiting with exit code $ec 
  exit $ec 
}

trap printError EXIT

set -xe -o pipefail 

OCI_REGISTRY=ghcr.io
OCI_REGISTRY_USER=dee0
OCI_REGISTRY_P_A_S_S_WO_R_D=
ocm --cred :type=OCIRegistry --cred :hostname=$OCI_REGISTRY --cred "username=$OCI_REGISTRY_USER" --cred "password=$OCI_REGISTRY_P_A_S_S_WO_R_D" add componentversions --create --file ./ocm/component-archive ./ocm/component.yaml 
