#!/bin/bash

set -eu

# Check for an optional timeout threshold in seconds. If the duration of the
# model run as executed below, takes longer that this threshhold
# then the run will be aborted. Note that the "timeout" command
# must be supported by executing OS.

# The timeout argument is optional. By default the "run_model" swift
# app fuction sends 3 arguments, and no timeout value is set. If there
# is a 4th (the TIMEOUT_ARG_INDEX) argument, we use that as the timeout value.

# !!! IF YOU CHANGE THE NUMBER OF ARGUMENTS PASSED TO THIS SCRIPT, YOU MUST
# CHANGE THE TIMEOUT_ARG_INDEX !!!
TIMEOUT_ARG_INDEX=4
TIMEOUT=""
if [[ $# ==  $TIMEOUT_ARG_INDEX ]]
then
	TIMEOUT=${!TIMEOUT_ARG_INDEX}
fi

TIMEOUT_CMD=""
if [ -n "$TIMEOUT" ]; then
  TIMEOUT_CMD="timeout $TIMEOUT"
fi

# Set param_line from the first argument to this script
# param_line is the string containing the model parameters for a run.
param_line=$1

# Set emews_root to the root directory of the project (i.e. the directory
# that contains the scripts, swift, etc. directories and files)
emews_root=$2

# Each model run, runs in its own "instance" directory
# Set instance_directory to that and cd into it.
instance_directory=$3
workDir=$(readlink -f $instance_directory)
cd $instance_directory

#Performance Log files will be produced 5% of the time unless already running on node
# in the $instance_directory
sleep $((RANDOM % 11)) # wait some random amount of time between 0 and 10 seconds 
if ps ax | grep -v grep | grep top > /dev/null
then
 echo "top is already running on this node"
else
  MOD=20
  number=$(($RANDOM % $MOD))
  if [ "$number" -eq 0 ]; then
    #Performance logs
    top -b -d 600.00 -n 60 -u $(whoami) >top.log &
  fi
fi


spikeFileRootName=$( awk '{print $1}' <<<$param_line| sed 's/\.mat//')
rootFileName=$(basename $spikeFileRootName)
inputDir=$( dirname $spikeFileRootName)
#Currenly defining workdir the same as datadir
permutationMask=$( awk '{print $2}' <<<$param_line )
permutationID=$( awk '{print $3}' <<<$param_line )
MCRPath="/soft/matlab/R2015b" 
#GCModelDir="/autonfs/home/lpesce/Taka/Matlab" 
GCModelDir="/lustre/beagle2/lpesce/Taka/Matlab"

echo PARAMLINE: $param_line

# TODO: Define the command to run the model
MODEL_CMDA=("$GCModelDir/run_glmmodel.sh $MCRPath ${spikeFileRootName}.mat $workDir/ $permutationMask $permutationID"
"$GCModelDir/run_glmaic.sh $MCRPath ${workDir}/${rootFileName}_#${permutationID}GLM.mat $workDir/ $permutationID"
"$GCModelDir/run_glmcausal.sh $MCRPath ${workDir}/${rootFileName}_#${permutationID}AIC.mat $workDir/ $permutationID"
)


# Turn bash error checking off. This is
# required to properly handle the model execution return value
# the optional timeout.
set +e

for MODEL_CMD in "${MODEL_CMDA[@]}"; do 

$TIMEOUT_CMD $MODEL_CMD
# $? is the exit status of the most recently executed command (i.e the
# line above)
RES=$?
if [ "$RES" -ne 0 ]; then
  if [ "$RES" == 124 ]; then
    echo "---> Timeout error in $MODEL_CMD"
  else
    echo "---> Error in $MODEL_CMD"
  fi
  exit 1
fi

done
