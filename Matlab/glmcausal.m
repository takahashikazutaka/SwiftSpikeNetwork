function glmcausal(filestring, aicfile, usedsamples, sampleID)
% load(filestring);
load(aicfile);
disp([filestring aicfile]);
htmax = 60;
win=3;
history = win:win:htmax;

% We don't need to replace X with spkmat which is used already in the glm
% model construction 
% spkmat = X;
spkmat = spkmat(:, 501:1500, find(usedsamples)); 

[totneurons, samples, trial] = size(spkmat);
Aic = ht.aic;
D = zeros(totneurons,totneurons);
SGN = zeros(totneurons,totneurons);

    for target = 1:totneurons
        for trigger = 1:totneurons
            disp([target,trigger]);
            % MLE after excluding trigger neuron
            [bctmp,dctmp] = glmtrialcausal(spkmat,target,trigger,win*Aic(target),htmax);
            bhatc{target,trigger} = bctmp;
            devc{target,trigger} = dctmp;
            % Deviance difference
            D(target,trigger) = dctmp - devnew{win*Aic(target),target};
            %             % Sign of interactions from trigger to target
            SGN(target,trigger) = sign(sum(bhat{win*Aic(target),target}(Aic(target)*(trigger-1)+2:Aic(target)*trigger+1))); 
        end
    end
    
    % Without FDR
    for i = 1:totneurons
        MAP(i,:) = D(i,:) > chi2inv(0.99,15/win);
    end
    
    % With FDR
    p = 0.01;
    [GCMAP] = FDR(D,p,15/win*ones(1,totneurons));
    [~, name, ~] = fileparts(aicfile);
    name = name(1:strfind(name,'#')-2); 
    
    currentfile = ['/lustre/beagle2/NeuralCausal/data/glmcausalou/',name,'_#',num2str(sampleID),'CNA.mat']
    % currentfile = sprintf('/lustre/beagle2/NeuralCausal/data/glmcausalou/%s_CNA.mat', name);
    save(currentfile, 'spkmat','bhat','bhatc','devc','devnew','D','MAP','SGN','GCMAP', '-v7.3');