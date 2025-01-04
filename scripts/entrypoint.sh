
function printError {
  ec=$?
  : Exiting with exit code $ec 
  exit $ec 
}

trap printError EXIT

set -xe -o pipefail 

echo start 
cp -r /toi/inputs/. /toi/outputs/inputs
cp /proc/$$/cmdline /toi/outputs
cp /proc/$$/environ /toi/outputs 
echo end 

exit 0

