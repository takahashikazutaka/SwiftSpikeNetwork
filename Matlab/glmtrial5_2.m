function [beta_new devnew] = glmtrial5_2(X, n, ht, w, htmax, trigger, initialCond)
% n = index for the target neuron spkmat,n,h,win,htmax
% Parse inputs
if nargin < 7
    initialCond = [];
end;
if nargin < 6
    trigger = [];
end;
if nargin < 5
    htmax = ht;
end;

% if we're doing causal testing, remove the trigger neuron
if trigger
    
    if (n>trigger)
        X = X(setdiff(1:length(X(:,1,1)), trigger), :, :);
        n = n-1; 
        % Build the design matrix
        [Xs, Ys] = makeDesignMatrix(X, n, ht, w, htmax);
    elseif (n==trigger) 
        [Xs, Ys] = makeDesignMatrix1(X, n, ht, w, htmax,trigger);
    else
        X = X(setdiff(1:length(X(:,1,1)), trigger), :, :);
        % Build the design matrix
        [Xs, Ys] = makeDesignMatrix(X, n, ht, w, htmax);
    end
else 
    [Xs, Ys] = makeDesignMatrix(X, n, ht, w, htmax);

end;



% Now do logistic regression either with prespecified init conds or 0's.  
if initialCond
    [beta_new devnew] = logisticRegression(Xs, Ys, initialCond);
else
    [beta_new devnew] = logisticRegression(Xs, Ys);
end;

function [Xs, Ys] = makeDesignMatrix(X, n, ht, w, htmax)
% This function generates the design matrix X, and the response matrix, Y.
WIN = zeros(ht/w, ht);
for iwin = 1:ht/w
    WIN(iwin, (iwin-1)*w+1:iwin*w) = 1;
end

[CHN SAM TRL] = size(X);
int_leng = fix((SAM-htmax)/10);

BXs = ones(TRL, SAM-htmax, (ht/w)*CHN + 1);
Xs = zeros(TRL*10, int_leng, (ht/w)*CHN + 1);

BYs = zeros(TRL, SAM-htmax);
Ys = zeros(TRL*10, int_leng);

X = permute(X, [2 1 3]);
for itrial = 1:TRL
    % New Method
    
    X2 = zeros(ht, CHN, SAM-htmax);
    for ichannel = 1:CHN
        X2(:,ichannel,:) = toeplitz(X(htmax:-1:htmax-ht+1,ichannel,itrial), ...
            X(htmax:end-1,ichannel,itrial));
    end;

    sx = size(X2); 
    sy = size(WIN); 
    Z = reshape(WIN * X2(:,:), [sy(1) sx(2:end)]);
    BXs(itrial, :, :) = [ones(1,SAM-htmax); reshape(Z, ht/w*CHN, SAM-htmax)]';
    % Old Method
    %{
    for isample = ht+1:SAM 
        %MM = (X(:, isample-1:-1:isample-ht, itrial)*WIN)';
        %BXs(itrial, isample-ht, 2:(ht/w)*CHN+1) = MM(:);
        BXs(itrial, isample-ht, 2:(ht/w)*CHN+1) = reshape(...
            WIN*X(isample-1:-1:isample-ht, :, itrial), (ht/w)*CHN, 1);
    end
    %}
    BYs(itrial, :) = X(htmax+1:SAM,n,itrial)';
    
    for isplit = 1:10
        Xs(isplit+(itrial-1)*10, :, :) = BXs(itrial, ...
            int_leng*(isplit-1)+1:int_leng*isplit,:);

        Ys(isplit+(itrial-1)*10, :, :) = BYs(itrial, ...
            int_leng*(isplit-1)+1:int_leng*isplit);    
    end
end


function [Xs, Ys] = makeDesignMatrix1(X, n, ht, w, htmax,trigger)
% This function generates the design matrix X, and the response matrix, Y, 
%for the case when the trigger and target are the same.  
WIN = zeros(ht/w, ht);
for iwin = 1:ht/w
    WIN(iwin, (iwin-1)*w+1:iwin*w) = 1;
end

[CHN SAM TRL] = size(X);
int_leng = fix((SAM-htmax)/10);

BXs = ones(TRL, SAM-htmax, (ht/w)*(CHN-1) + 1);
Xs = zeros(TRL*10, int_leng, (ht/w)*(CHN-1) + 1);

BYs = zeros(TRL, SAM-htmax);
Ys = zeros(TRL*10, int_leng);

for itrial = 1:TRL
%for isample = ht+1:SAM  % ii = 1:k
    temp = ones(SAM-htmax,1);
    
    for ichannel = 1:CHN 
        if ichannel == trigger
        else
            for hh = 0:3:ht-3
                temp0 = X(ichannel,htmax-hh:SAM-1-hh,itrial)' + X(ichannel,htmax-1-hh:SAM-2-hh,itrial)' + X(ichannel,htmax-2-hh:SAM-3-hh,itrial)';
                temp = [temp temp0];
            end
        end
    end
    
    BIGXsub{itrial} = temp;
    %end
    int_leng = fix((SAM-htmax)/10);
    for isplit = 1:10
        Xs(isplit+(itrial-1)*10,:,:) = BIGXsub{itrial}(int_leng*(isplit-1)+1:int_leng*isplit,:);
    end
end

%X = permute(X, [2 1 3]);

for itrial = 1:TRL
    BIGYsub{itrial} = X(n,htmax+1:SAM,itrial)';
    for isplit = 1:10
        Ys(isplit+(itrial-1)*10,:) = BIGYsub{itrial}(int_leng*(isplit-1)+1:int_leng*isplit);
    end
end

clear BIGY* BIGX* BX* BY* 

function [beta_new devnew] = logisticRegression(Xs, Ys, beta_old)
i = 0;
p = length(Xs(1,1,:));
TRL = size(Xs, 1)/10;

% CG parameters
cgeps = 1e-3;
cgmax = 30;

% LR parameters
Irmax = 100;
Ireps = 0.05;

% Initialization
if nargin < 3
    beta_old = zeros(p,1);
end;

eta = cell(TRL*10, 1);
musub = cell(TRL*10, 1);
Wsub = cell(TRL*10, 1);
zsub = cell(TRL*10, 1);

% Let's rely on some strange aspects of MATLAB's multiplication algorithm.
% Generally speaking, we can't multiple arbitrary 3-D arrays; that's why we
% love the squeeze function.  If we place singleton dimensions at the end
% of the array tho, e.g. X(:,:,1), then we can use standard matrix
% multiplications.  Let's try this out.  

Xs = shiftdim(Xs, 1);

for iepoch = 1:TRL*10
    eta{iepoch} = Xs(:,:, iepoch)*beta_old;
    musub{iepoch} = exp(eta{iepoch})./(1+exp(eta{iepoch}));
    Wsub{iepoch} = musub{iepoch} .* (1-musub{iepoch});
    zsub{iepoch} = eta{iepoch} + (Ys(iepoch,:)'-musub{iepoch}).*(1./Wsub{iepoch});
end

% Scaled deviance
devold = 0;
for iepoch = 1:TRL*10
    devold = devold - 2*(Ys(iepoch, :)*log(musub{iepoch})+(1-Ys(iepoch, :))*log(1-musub{iepoch}));
end
devnew = 0;
devdiff = abs(devnew - devold);

% Iterative weighted least-squares
while (i < Irmax && devdiff > Ireps)

    A = zeros(p,p);
    b = zeros(p,1);
    for iepoch = 1:TRL*10
        % This matrix multiplication is replaced by using bsxfun
        % Q = Xs(:,:,iepoch)'*diag(Wsub{iepoch});
        Q = bsxfun(@times, Xs(:,:,iepoch), Wsub{iepoch})';
        A = A + Q*Xs(:,:,iepoch);
        b = b + Q*zsub{iepoch};
    end
 clear Q 
    % Conjugate gradient method for symmetric postive definite matrix A
    beta_new = cgs(A,b,cgeps,cgmax,[],[],beta_old);
clear A b 
    
    beta_old = beta_new;
    
    devnew = 0;
    for iepoch = 1:TRL*10
        eta{iepoch} = Xs(:, :, iepoch)*beta_old;
        eeta = exp(eta{iepoch});
        musub{iepoch} = eeta./(1+eeta);
        Wsub{iepoch} = musub{iepoch} .* (1-musub{iepoch});
        zsub{iepoch} = eta{iepoch} + (Ys(iepoch, :)'-musub{iepoch}).* ...
            (1./Wsub{iepoch});
        % Scaled deviance
        devnew = devnew - 2*(Ys(iepoch, :)*log(musub{iepoch})+(1-Ys(iepoch, :))*log(1-musub{iepoch}));
    end
    devdiff = abs(devnew - devold);
    devold = devnew;

    i = i+1;
end
clear Wsub musub eta zsub

%{
if nargout > 1
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
end;
%}

