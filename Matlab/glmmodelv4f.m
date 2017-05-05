function glmmodelv4f(filestring, ix)
load(filestring);
% loadevents = load('/project/nicho/BMI/glmmodel/data/selectedevents.mat');
% selevents = loadevents.caseinclude{43};
htmax = 60;
win=3;
history = win:win:htmax;

spkmat = X;

spkmat = spkmat(:, 2000:3000, :);
[totneurons, samples, trial] = size(spkmat);

disp(strcat('Number of Neurons:', num2str(totneurons)));

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
currentfile = sprintf('/lustre/beagle2/bkintex/glmmodel/data/glmmodelou/%s_GLM.mat', name);
disp(size(result));
whos('result');
save(currentfile, 'result', 'filestring', '-v7.3');
clear spkmat
