function glmmodel(filestring,savepath,usedsamples,sampleID)
load(filestring);
htmax = 60;
win=3;
history = win:win:htmax;
% A new pieces added by Karth and we will not use these. 
% spkmat = X;
% spkmat = spkmat(:, 2000:3000, :);
% Following what Karth has done for Nature Comm manuscript 
spkmat = spkmat(:, 501:1500, find(usedsamples)); 

[totneurons, samples, trial] = size(spkmat);

% disp(strcat('Number of Neurons:', num2str(totneurons)));

for n = 1:totneurons
    disp(strcat(num2str(n),'_of_', num2str(totneurons)));
    for h = history
        [beta_new,devnew] = glmtrial5_2(spkmat,n,h,win,htmax);
        LLK = -0.5*devnew;
        aic = -2*LLK+2*(totneurons*h/win+1);
        bic = -2*LLK+(totneurons*h/win + 1)*log((samples-htmax)*trial);
        result{n,h} = {beta_new, devnew, aic, bic, LLK, h};
        clear beta_new devnew
    end
end
[~, name, ~] = fileparts(filestring);

currentfile = [savepath,name,'_#',num2str(sampleID),'GLM.mat']
% disp(size(result));
% whos('result');
save(currentfile, 'result', 'spkmat', '-v7.3');
% clear spkmat
