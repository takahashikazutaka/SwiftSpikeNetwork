function [beta_new,devnew,stats] = glmtrialcausal(Y,y,trigger,ht,htmax)
 
%================================================================
%                GLM fitting based on submatrices
%================================================================
%
%  This code is made for the case when input matrix Y is too huge
%  Y is partioned into many small submatrices of (k x p)-dimension
%  This code is based on bnlrCG.m (Demba) and
%
%   References:
%      Dobson, A.J. (1990), "An Introduction to Generalized Linear
%         Models," CRC Press.
%      McCullagh, P., and J.A. Nelder (1990), "Generalized Linear
%         Models," CRC Press.
%
% Input arguments:
%        stim: stimulus
%           Y: measurement data (K x Q)
%           y: index number of input (neuron) to analyze
%           h: model order (using AIC or BIC)
%           k: one of divisors for K
%           p: one of divisors for P
%      prflag: 1: MAP estimation with
%              0: ML estimation
%
% Output arguments:
%     beta_new: estimated GLM parameters (p x 1)
%
% [bhat,devnew,stats] = bnlrCG(X,yframe,0) is equivalent to [bhat,devnew,stats] = glmsbm(X,yframe,K,P,0);
%
%================================================================
% SangGyun Kim
% Neuroscience Statistics Research Lab (BCS MIT)
% April 13. 2009
%================================================================
 
% Counting window
w = 3;
WIN = zeros(ht/w,ht);
for iwin = 1:ht/w
    WIN(iwin,(iwin-1)*w+1:iwin*w) = 1;
end
 
% CG parameters
cgeps = 1e-3;
cgmax = 30;
 
% LR parameters
Irmax = 100;
Ireps = 0.05;
 
% Ynew = Y(:,ht+1:end,:);
[CHN SAM TRL] = size(Y);
for itrial = 1:TRL       % kk = 1:K/k
    %for isample = ht+1:SAM  % ii = 1:k
    temp = ones(SAM-htmax,1);
    
    for ichannel = 1:CHN 
        if ichannel == trigger
        else
            for hh = 0:3:ht-3
                temp0 = Y(ichannel,htmax-hh:SAM-1-hh,itrial)' + Y(ichannel,htmax-1-hh:SAM-2-hh,itrial)' + Y(ichannel,htmax-2-hh:SAM-3-hh,itrial)';
                temp = [temp temp0];
            end
        end
    end
    
    BIGXsub{itrial} = temp;
    %end
    int_leng = fix((SAM-htmax)/10);
    for isplit = 1:10
        Xsub{isplit+(itrial-1)*10} = BIGXsub{itrial}(int_leng*(isplit-1)+1:int_leng*isplit,:);
    end
end
 
for itrial = 1:TRL
    BIGYsub{itrial} = Y(y,htmax+1:SAM,itrial)';
    for isplit = 1:10
        Ysub{isplit+(itrial-1)*10} = BIGYsub{itrial}(int_leng*(isplit-1)+1:int_leng*isplit);
    end
end
 
% Logistic regression
i = 0;
% Initialization
P = length(Xsub{1});
 
p = (CHN-1)*ht/w + 1;
beta_old = zeros(p,1);
% W = {Wsub{kk}} & z = {zsub{kk}}
for iepoch = 1:TRL*10
    eta{iepoch} = Xsub{iepoch}*beta_old;
    musub{iepoch} = exp(eta{iepoch})./(1+exp(eta{iepoch}));
    Wsub{iepoch} = diag(musub{iepoch}).*diag(1-musub{iepoch});
    zsub{iepoch} = eta{iepoch} + (Ysub{iepoch}-musub{iepoch}).*(1./diag(Wsub{iepoch}));
end
 
% Scaled deviance
devold = 0;
for iepoch = 1:TRL*10
    devold = devold - 2*(Ysub{iepoch}'*log(musub{iepoch})+(1-Ysub{iepoch})'*log(1-musub{iepoch}));
end
devnew = 0;
devdiff = abs(devnew - devold);
 
% Iterative weighted least-squares
while (i < Irmax && devdiff > Ireps)
 
    A = zeros(p,p);
    for iepoch = 1:TRL*10
        A = A + Xsub{iepoch}'*Wsub{iepoch}*Xsub{iepoch};
    end
    %A = A + A' - diag(diag(A));
 
    b = zeros(p,1);
    for iepoch = 1:TRL*10
        b = b + Xsub{iepoch}'*Wsub{iepoch}*zsub{iepoch};
    end
 
    % Conjugate gradient method for symmetric postive definite matrix A
    beta_new = cgs(A,b,cgeps,cgmax,[],[],beta_old);
    beta_old = beta_new;
 
    for iepoch = 1:TRL*10
        eta{iepoch} = Xsub{iepoch}*beta_old;
        musub{iepoch} = exp(eta{iepoch})./(1+exp(eta{iepoch}));
        Wsub{iepoch} = diag(musub{iepoch}).*diag(1-musub{iepoch});
        zsub{iepoch} = eta{iepoch} + (Ysub{iepoch}-musub{iepoch}).*(1./diag(Wsub{iepoch}));
    end
 
    % Scaled deviance
    devnew = 0;
    for iepoch = 1:TRL*10
        devnew = devnew - 2*(Ysub{iepoch}'*log(musub{iepoch})+(1-Ysub{iepoch})'*log(1-musub{iepoch}));
    end
    devdiff = abs(devnew - devold);
    devold = devnew;
 
    i = i+1;
 
end
 
% Compute additional statistics
stats.dfe = 0;
stats.s = 0;
stats.sfit = 0;
stats.covb = inv(A);
stats.se = sqrt(diag(stats.covb));
stats.coeffcorr = stats.covb./sqrt((repmat(diag(stats.covb),1,p).*repmat(diag(stats.covb)',p,1)));
stats.t = 0;
stats.p = 0;
stats.resid = 0;
stats.residp = 0;
stats.residd = 0;
stats.resida = 0;

