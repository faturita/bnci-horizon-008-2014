function DE = NBNNFeatureExtractor(F,channel,trainingRange,labelRange,labels, balancebags)
% Labels should be 1,2,3,... and so on but try to start from one.

DE.CLSTER = [];

for i=1:size(labels,2)
    exclude{i}=[];
end

% These are the sizes of the images, not the descriptors.
a(1) = size(find(labelRange(trainingRange)==labels(1)),2);
a(2) = size(find(labelRange(trainingRange)==labels(2)),2);


for label=labels
    [M, IX] = BuildDescriptorMatrix(F,channel,labelRange,trainingRange(find(labelRange(trainingRange)==label)));
    DE.C(label).M = M;
    DE.C(label).IX = IX;

    a(label) = size(M,2);
end

[val, lb] = max(a);

for label=labels
    fprintf('Building Descriptor Matrix M for Channel %d:', channel);
    [M, IX] = BuildDescriptorMatrix(F,channel,labelRange,trainingRange(find(labelRange(trainingRange)==label)));
    fprintf('%d\n', size(M,2)); 
    
    exclude{label} = sort(exclude{label},'descend');
    
    for i=1:size(exclude{label})
        M(:,exclude{label}(i)) = [];
        IX(exclude{label}(i),:) = [];        
    end

    % Unbalance training dataset.
    if (balancebags && label==lb)
        pperm = randperm(size(M,2),min(a));
        M=M(:,pperm);
        IX=IX(pperm,:);
    end
    
    assert ( balancebags == false ||( balancebags  && size(M,2) == min(a) ) );

end


M = [DE.C(1).M DE.C(2).M ];
IX = [DE.C(1).IX ;DE.C(2).IX ];

H = double(M);
lbs = labelRange(trainingRange);
lbs = lbs-1;

%[b,se,pval,inmodel,stats,nextstep,history] =  stepwisefit(H',lbs');

% mdl=stepwiseglm(H',lbs','constant','upper','linear','distr','binomial')


% if (mdl.NumEstimatedCoefficients>1)
%     
%     inmodel = [];
%     for i=2:mdl.NumEstimatedCoefficients
%        inmodel = [inmodel  str2num(mdl.CoefficientNames{i}(2:end))];
%     end
%     
%     
%     DE.C(1).M = DE.C(1).M(inmodel,:);
%     DE.C(2).M = DE.C(2).M(inmodel,:);
% 
%     DE.inmodel = inmodel;
% else 
    DE.inmodel = 1:size(DE.C(1).M,1);
% end

if (balancebags)
    DE = MahalanobisPrunning(DE);
end

for label=labels    
    M = DE.C(label).M;
    IX = DE.C(label).IX;

    % Creating a KDTree.

    kdtree = vl_kdtreebuild(M) ;

    DE.C(label).M = M;
    DE.C(label).Label = label;
    DE.C(label).IX = IX;
    DE.C(label).KDTree = kdtree;

    DE.CLSTER = [DE.CLSTER DE.C(label).Label];
end

end



function [DE] = MahalanobisPrunning(DE)
X = DE.C(2).M';
Y = DE.C(1).M';

size(X)
size(Y)

n=size(X,1);
m=size(Y,1);
d=zeros(1,m);
% media 
muX=mean(X,1);
% inversa covarianza
CX_inv=inv(cov(X));
for i=1:m
    % dist. Mahalanobis
    d(i)=(Y(i,:)-muX)*CX_inv*(Y(i,:)-muX)';
end
[~,ind]=sort(d,'descend');
% descriptores elegidos
ind_ch=ind(1:n);
Y_ch=Y(ind_ch,:);

ind_ch

DE.C(1).M=DE.C(1).M(:,ind_ch);
DE.C(1).IX=DE.C(1).IX(ind_ch,:);

end
