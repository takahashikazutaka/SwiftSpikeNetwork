function glmaicv4f(filestring, ix)
htmax = 60;
win=3;

load(filestring);

[numN, ~] = size(result);
Llk = zeros(htmax,numN); 
Aic = zeros(htmax,numN); 
Bic = zeros(htmax,numN); 
Ht.aic  = zeros(1,numN); 
Ht.bic  = zeros(1,numN); 
for neuron = 1:numN
    for ht = win:win:htmax
%         eval(['load result_neuron_',num2str(neuron),'_ht_',num2str(ht),'.mat']); 
        Aic(ht,neuron) = result{neuron,ht}{3}; 
        Bic(ht,neuron) = result{neuron,ht}{4}; 
        Llk(ht,neuron) = result{neuron,ht}{5}; 
        Bhat{ht,neuron} = result{neuron,ht}{1}; 
        Devnew{ht,neuron} = result{neuron,ht}{2};  
        % Stats{ht,neuron} = stats; 
%         clear aic bic LLK bhat devnew stats 
    end
    [blah,Ht.aic(neuron)] = min(Aic(win:win:htmax,neuron)); 
    [blah,Ht.bic(neuron)] = min(Bic(win:win:htmax,neuron)); 
end

clear ht  
bhat = Bhat; 
LLK = Llk; 
aic = Aic; 
bic = Bic; 
ht = Ht;
% stats = Stats; 
devnew = Devnew;

[~, name, ~] = fileparts(filestring);
currentfile = sprintf('/lustre/beagle2/bkintex/glmmodel/data/glmaicou/%s_AIC.mat', name);
save(currentfile, 'bhat', 'LLK', 'aic', 'bic', 'ht', 'devnew', 'filestring', '-v7.3');
