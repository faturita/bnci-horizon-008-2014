function [ACC, ERR, AUC, SC] = NBNNClassifier4(F,DE,channel,testRange,labelRange,graphics,distancetype,kparam)

fprintf('Channel %d\n', channel);
fprintf('Building Test Matrix M for Channel %d:', channel);
[TM, TIX] = BuildDescriptorMatrix(F,channel,labelRange,testRange);
fprintf('%d\n', size(TM,2));

TM = TM(DE.inmodel,:);

%DE = NBNNFeatureExtractor(F,channel,trainingRange,labelRange,[1 2], false);

% Este metodo toma en consideracion que la clasificacion binaria se usa
% para un speller de p300.

assert( mod(size(testRange,2),12)==0, 'This method only works for P300 spellers');

mind = 1;
maxd = 6;

SC.CLSF = {};
predicted=[];
score=[];

% W contiene los pesos de los descriptores de la bolsa de hit
% K = size(DE.C(2).M,2);
% 
% D=[];
% for i=1:2:K
%    ni=floor(i/2)+1;
%    Z= pdist2(DE.C(1).M(:,(ni-1)*10+1:(ni-1)*10+10)',DE.C(2).M(:,i:i+1)',distancetype);
%    %Z= pdist2(DE.C(1).M(:,i:i+1)',DE.C(2).M(:,i:i+1)','euclidean');
%    Di = sum(Z) ;
%    D(end+1)=Di(1);
%    D(end+1)=Di(2);
% end
% 
% DR=(D-min(D))/range(D);
% 
% Wdi = normpdf(DR,0,1);


for f=1:size(testRange,2)/12
    
    K = size(DE.C(2).M,2);

    [Z,I] = pdist2(DE.C(2).M',(TM(:,mind:maxd+6)'),distancetype,'Smallest',K );
    
    k = kparam;

    %Wi = Wdi(I(1:k,1:6)) ./ repmat( sum(Wdi(I(1:k,1:6))),k,1);     
    Wi = ones(k,6);
    if (k==1)
        sumsrow = Z(1:k,1:6).*Wi(1:k,1:6);
    else
        sumsrow = dot(Z(1:k,1:6),Wi(1:k,1:6));
    end
    
    
    %Wi = Wdi(I(1:k,7:12)) ./ repmat( sum(Wdi(I(1:k,7:12))),k,1); 
    Wi = ones(k,6);
    if (k==1)
        sumscol = Z(1:k,7:12).*Wi(1:k,1:6);
    else
        sumscol = dot(Z(1:k,7:12),Wi(1:k,1:6));
    end

    % Me quedo con aquel que la suma contra todos, dio menor.
    [c, row] = min(sumsrow);
    [c, col] = min(sumscol);
    %col=col+6;

    % I(1:3,1:6) Me da en cada columna los ids de los descriptores de M mas
    % cercaos a cada uno de los descriptores de 1 a 6.
    
    assert( sum(sumsrow)>0, 'Problem with distance function for this feature.');
    assert( sum(sumscol)>0, 'Problem with distance function for this feature.');
    

    % Las predicciones son 1 para todos excepto para row y col.
    for i=1:6
        if (i==row)
            predicted(end+1) = 2;
        else
            predicted(end+1) = 1;
        end
        score(end+1) = 1-sumsrow(i)/sum(sumsrow);
    end
    for i=1:6
        if (i==col)
            predicted(end+1) = 2;
        else
            predicted(end+1) = 1;
        end
        score(end+1) = 1-sumscol(i)/sum(sumscol);
    end

    mind=mind+12;
    maxd=maxd+12;
end
score=score';

%for channel=channelRange
fprintf ('Channel %d -------------\n', channel);

%M = MM(channel).M;
%IX = MM(channel).IX;

expected = labelRange(testRange);


%predicted=randi(unique(labelRange),size(expected))

C=confusionmat(expected, predicted)


%if (C(1,1)+C(2,2) > 65)
%    error('done');
%end

%[X,Y,T,AUC] = perfcurve(expected,single(predicted==2),2);
[X,Y,T,AUC] = perfcurve(expected,score,2);

%figure;plot(X,Y)
%xlabel('False positive rate')
%ylabel('True positive rate')
%title('ROC for Classification of P300')

ACC = (C(1,1)+C(2,2)) / size(predicted,2);
ERR = size(predicted,2) - (C(1,1)+C(2,2));

SC.FP = C(2,1);
SC.TP = C(2,2);
SC.FN = C(1,2);
SC.TN = C(1,1);

[ACC, (SC.TP/(SC.TP+SC.FP))]

SC.expected = expected;
SC.predicted = predicted;    

end

