type file;

string MCRPath = "/soft/matlab/R2015b";

app(file outdata, file result, file err) generateGLM(string mcr, file neuraldatafile, string index)
{
	rungenerateGLM mcr filename(neuraldatafile) index @result stdout=@outdata stderr=@err;
}

app(file outdata, file result, file err) generateAIC(string mcr, file glmmodelfile, string index)
{
	rungenerateAIC mcr filename(glmmodelfile) index @result stdout=@outdata stderr=@err;
}

app(file outdata, file result, file err) generateGLMC(string mcr, file neuraldatafile, string index, file glmaicfile)
{
	rungenerateGLMC mcr filename(neuraldatafile) index filename(glmaicfile) @result stdout=@outdata stderr=@err;
}

file neuraldata[] <filesys_mapper; location="/lustre/beagle2/bkintex/glmmodel/data/inpu", prefix="F_MS_", suffix="_a.mat">;
trace(neuraldata);
foreach f, ix in neuraldata{
  file glmmodelout <single_file_mapper; file=@strcat("/lustre/beagle2/bkintex/glmmodel/data/glmmodelou/glmmodel_out_",ix,".out")>;
  file glmmodelres <single_file_mapper; file=@strcat("/lustre/beagle2/bkintex/glmmodel/data/glmmodelou/",@strcut(@filename(f),"u/([^*.]+)"),"_GLM.mat")>; 
  file glmmodelerr <single_file_mapper; file=@strcat("/lustre/beagle2/bkintex/glmmodel/data/glmmodelou/glmmodel_out_",ix,".err")>;
  
  file glmaicout <single_file_mapper; file=@strcat("/lustre/beagle2/bkintex/glmmodel/data/glmaicou/glmaic_out_",ix,".out")>;
  file glmaicres <single_file_mapper; file=@strcat("/lustre/beagle2/bkintex/glmmodel/data/glmaicou/",@strcut(@filename(f),"u/([^*.]+)"),"_AIC.mat")>; 
  file glmaicerr <single_file_mapper; file=@strcat("/lustre/beagle2/bkintex/glmmodel/data/glmaicou/glmaic_out_",ix,".err")>;
  
  file glmcausalout <single_file_mapper; file=@strcat("/lustre/beagle2/bkintex/glmmodel/data/glmcausalou/glmcausal_out_",ix,".out")>;
  file glmcausalres <single_file_mapper; file=@strcat("/lustre/beagle2/bkintex/glmmodel/data/glmcausalou/",@strcut(@filename(f),"u/([^*.]+)"),"_CNA.mat")>; 
  file glmcausalerr <single_file_mapper; file=@strcat("/lustre/beagle2/bkintex/glmmodel/data/glmcausalou/glmcausal_out_",ix,".err")>;
  
  (glmmodelout,glmmodelres,glmmodelerr) = generateGLM(MCRPath, f, @toString(ix));
  (glmaicout,glmaicres,glmaicerr) = generateAIC(MCRPath, glmmodelres, @toString(ix));
  (glmcausalout,glmcausalres,glmcausalerr) = generateGLMC(MCRPath, f, @toString(ix), glmaicres);
}
