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

run script as 

../Matlab/run_glmaic.sh $MCRPath /lustre/beagle2/NeuralCausal/z20130830_SPK_6_CNA.mat




