#!/bin/bash
# Generete input for the EMEWS run
# NOTE: the mask here is all "1" meaning that all samples in the input file  will be selected
# USAGE: <script> $rootdir $ntrials > input.txt
rootDir=$1 # root directory under which all the *.mat files are
nTrials=$2 # number of trials of the file

rootDir=$(readlink -f $rootDir)
mask=$(bash -c "printf '1%.0s' {1..${nTrials}}")
instance=1
for infile in $(find $rootDir -name \*.mat); do
echo $infile $mask $instance
instance=$((instance+1))
done
