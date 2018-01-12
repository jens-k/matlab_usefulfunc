function [average,sem,ci] = weighted(values,weights,method,fillna)
%% compute weighted average and weighted SEM
% INPUT: values, weights ... same length of vectors. 'values' can be
%                            a matrix
%        method ... 'none' (no weighting for errorbars)
%                   'standard' (default; weighted errorbars)
%                   'bootstrap' (resampling for errorbars)
%        fillna ... 0 (omit rows with nan), 1 (replace rows with nan with
%        its columns' median)
%
% OUTPUT: weighted average, weighted SEM and weighted 95% CI
%
% example: [me, sem, ci] = weighted(randn(10,3), randn(10,1));
% ++++++++++++++++++++++++++++++++++++++++++++++++++++++++

if nargin < 1
     error('At least a matrix has to be given as an input argument.')
end
if nargin < 2
    weights = ones(size(values));
end
if nargin < 3
    method = 'standard';
end
if nargin < 4
    fillna = 1;
end

% transpose if necessary
if size(weights,1)==1 && size(weights,2) > 1
    weights = weights';
    values = values';
end

% deal with nans
nancol = find(all(isnan(values),1));
nanw = isnan(weights);
if fillna==1
    weights(nanw) = nanmedian(weights);   
    for n = 1:length(nancol)
        v = values(:,n);
        v(isnan(v)) = nanmedian(v);
        values(:,n) = v;
    end
elseif fillna==0
    values(nancol | nanw, :) = [];
    weights(nancol | nanw) = [];
end
    
% matrix for weights
weimat = nan(size(values));
lenwei = nan(1,size(values,2));
for c = 1:size(values,2)        
    okpos = find(~isnan(values(:,c)));
    lenwei(c) = length(okpos);
    if lenwei(c) < size(values,1)
            new_weight = nan(size(values,1),1);
            new_weight(okpos) = weights(okpos)/sum(weights(okpos));
    else
            new_weight = weights/sum(weights);
    end
    weimat(:,c) = new_weight;
end

len_w = size(values,1);

% compute weighted average
switch method
    case 'none'  % standard error of the mean without weighting
            average = mean(values,1);
            sem = std(values,[],1)/sqrt(size(values,1));

    case 'standard'  % compute weighted standard error of the mean
            average = nansum(values.*weimat,1);               
            sem = sqrt(nansum(weimat.*(values - ones(size(values,1),1)*average).^2,1)./lenwei);            

    case 'bootstrap' % bootstrap
            mat = zeros(size(values));
            for i = 1:len_w
                    mat(i,:) = values(i,:).*weights(i);
            end
            average = sum(mat,1)/sum(weights);                

            mat = mat/sum(weights);
            repeats = 1000;
            aves = zeros(repeats, size(values,2));
            for r = 1:repeats
                    res = zeros(size(values));
                    for k = 1:size(values,1)
                            shu = randperm(size(values,1));
                            res(k,:) = mat(shu(1),:);
                    end
                    aves(r,:) = mean(res,1);
            end
            sem = std(aves,[],1);                     
end

% compute weighted 95% confidence interval of the mean
ci = sem*tinv(0.975, len_w-1); 

