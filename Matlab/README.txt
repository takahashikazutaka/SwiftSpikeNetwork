Matlab root file names to be compiled
package=glmaic  
package=glmcausal  
package=glmmodel 
#To compile each, use
mcc -R -singleCompThread -R -nojvm -R -nodisplay -mv ${package}.m -o ${package}

use script ./change.pl to modify file as explained below:
#Need to modify the shell scripts to prevent them from locking each other up
#after #! and comments
#Added to run on Beagle after June 2017 
"TMP=/tmp/
umask 0000
tmp=`mktemp -d $TMP/matlabcachedir.XXXXXXXXXXX`
echo $tmp
export MCR_CACHE_ROOT=$tmp"
#Add the following before 
#fi
#exit
rm -rf $tmp

#Location of the run time environment
MCRPath="/soft/matlab/R2015b"

# Initial fit on the entirety of the mat file run script as 
# MCRPath simply tells the script where the runtime environment for Matlab it
# <spike file> contains the 01... sequence of spikes for the 3D array times trials
../Matlab/run_glmmodel.sh $MCRPath <spike file>
# Call to make a subsample of the set (for estimating errors or other purposes
#<trial mask> is a sequence of 0s and 1s that established which trial
#<mask id> is a number that allows to easily rename files specifically for this mask run 
../Matlab/run_glmmodel.sh $MCRPath <spike file> <trial mask> <mask id>
#E.g.
../Matlab/run_glmmodel.sh $MCRPath /lustre/beagle2/NeuralCausal/data/inpu/z20130830_SPK_6_CNA.mat 11111111101111111111111111011111111110111111110111111100111111111111011111111111111111101010111111111111111111111100111111111111111101111111111111110111111110101111110111111111111101111111111111111111011001111111111111111111110111011111111101111111111111101011111111010111 1






