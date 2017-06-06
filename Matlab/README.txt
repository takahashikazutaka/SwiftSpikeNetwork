Matlab root file names to be compiled
package=glmaic  
package=glmcausal  
package=glmmodel 
#To compile each, use
mcc -R -singleCompThread -R -nojvm -R -nodisplay -mv ${package}.m -o ${package}

#Location of the run time environment
MCRPath = "/soft/matlab/R2015b"
