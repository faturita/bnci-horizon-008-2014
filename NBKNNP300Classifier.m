function [ACC, ERR, AUC, SC] = NBKNNP300Classifier(F,DE,channel,testRange,labelRange,distancetype,kparam)

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

assert( mod(size(TM,2),12)==0, 'This method assumes that the set of descriptors from the Query image is fixed.');

% Cantidad de descriptores en Q x imagen.
qKS = size(TM,2)/size(testRange,2);

for f=1:size(testRange,2)/12
    
    K = size(DE.C(2).M,2);

    [Z,I] = pdist2(DE.C(2).M',(TM(:,mind:mind+12*qKS-1)'),distancetype,'Smallest',K );
    
    k = kparam;

    %Wi = Wdi(I(1:k,1:6)) ./ repmat( sum(Wdi(I(1:k,1:6))),k,1);     
    Wi = ones(k,6*qKS);
    if (k==1)
        sumsrow = Z(1:k,1:6*qKS).*Wi(1:k,1:6*qKS);
    else
        sumsrow = dot(Z(1:k,1:6*qKS),Wi(1:k,1:6*qKS));
    end
    
    % I(1:7,108) son los 7 vecinos mas cercanos ordenados del mas cercano
    % arriba del descriptor 108 que es uno de los 9 de la ultima columna,
    % la 12.
    
    %Wi = Wdi(I(1:k,7:12)) ./ repmat( sum(Wdi(I(1:k,7:12))),k,1); 
    Wi = ones(k,6*qKS);
    if (k==1)
        sumscol = Z(1:k,6*qKS+1:12*qKS).*Wi(1:k,1:6*qKS);
    else
        sumscol = dot(Z(1:k,6*qKS+1:12*qKS),Wi(1:k,1:6*qKS));
    end
    
    if (qKS>1)
        sumsrow = reshape(sumsrow,[6 qKS]);
        sumsrow = sum(sumsrow,2);
        
        sumscol = reshape(sumscol,[6 qKS]);
        sumscol = sum(sumscol,2);
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

    mind=mind+12*qKS;
    maxd=maxd+12*qKS;
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