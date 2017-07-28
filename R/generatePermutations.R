#!/usr/bin/env Rscript
# Creates list of permutations specific to a spike file
# Specifically, one would need to change the name of the file and the number of trials
#SpikeFileName<-'~/Taka/data/ziTest.mat'
#totalSamples<-100
#SpikeFileName='/lustre/beagle2/NeuralCausal/data/z20130830_SPK_6_CNA.mat'
#totalSamples<-105
#SpikeFileName='/lustre/beagle2/NeuralCausal/data/z20130909_SPK_11_CNA.mat'
SpikeFileName='/lustre/beagle2/lpesce/Taka/data/Exp196/trans11/Win1/X.mat'
totalSamples<-833
percentSelected <-.07

nrOf1 <- as.integer(percentSelected*totalSamples)
nrOf0 <- totalSamples - nrOf1
nrPermutations <- 1000
V <- c(rep(0,nrOf0),rep(1,nrOf1))

set.seed(001)

outFile <- "runs.list"

sink(outFile, append=FALSE, split=FALSE)

for (i in seq(1,nrPermutations)) { 
  outList=paste(c(SpikeFileName," ",sample(V)," ",i),collapse="")
  cat(outList,"\n",sep = "")
}

