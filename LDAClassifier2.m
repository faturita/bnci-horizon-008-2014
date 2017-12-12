function [DE, ACC, ERR, AUC, SC] = LDAClassifier(F,labelRange,trainingRange,testRange,channel)

fprintf('Channel %d\n', channel);
fprintf('Building Test Matrix M for Channel %d:', channel);
[TM, TIX] = BuildDescriptorMatrix(F,channel,labelRange,testRange);
fprintf('%d\n', size(TM,2));

%fprintf('Channel %d\n', channel);
%fprintf('Building Test Matrix M for Channel %d:', channel);
%[M, IX] = BuildDescriptorMatrix(F,channel,labelRange,trainingRange);
%fprintf('%d\n', size(TM,2));


DE = NBNNFeatureExtractor(F,channel,trainingRange,labelRange,[1 2], false);

% Este metodo toma en consideracion que la clasificacion binaria se usa
% para un speller de p300.

assert( mod(size(testRange,2),12)==0, 'This method only works for P300 spellers');

mind = 1;
maxd = 6;

SC.CLSF = {};
predicted=[];
score=[];

M = [DE.C(1).M DE.C(2).M ];
IX = [DE.C(1).IX ;DE.C(2).IX ];


lbs= labelRange(trainingRange);
tlbs= labelRange(testRange);
H = double(M);
TH = double(TM);

H = zscore(H);
TH = zscore(TH);

% Fit a naive Bayes classifier
%mdlNB = fitcnb(pred,resp);

fprintf('Clasificando con LDA para Matlab\n');

MdlLinear = fitcdiscr(H',lbs','DiscrimType','pseudoQuadratic');

[predicted,score,cost]  = predict(MdlLinear,TH');

fprintf('Regularizacion: Pifies en la prediccion de la clase.\n');
size(find(predicted ~= tlbs'))

% Classification based on LDA

[b,se,pval,inmodel,stats,nextstep,history] =  stepwisefit(H',lbs');


if (size(find(inmodel==1),2)~=0)
    
    MdlLinear = fitcdiscr(H(inmodel,:)',lbs','DiscrimType','pseudoQuadratic');

    [predicted,score,cost] = predict(MdlLinear,TH(inmodel,:)');

    fprintf('Regularizacion: Pifies en la prediccion de la clase despues de stepwise.\n');
    size(find(predicted ~= tlbs'))
end


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
[X,Y,T,AUC] = perfcurve(expected,score(:,2)',2);

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


%%
W = LDA( H(inmodel,:)', IX(:,2)');
L = [H(inmodel,:); ones(1,420)]' * W';

W = LDA( TH(inmodel,:)', TIX(:,2)');
L = [TH(inmodel,:); ones(1,240)]' * W';

P = exp(L) ./ repmat(sum(exp(L),2),[1 2]);

[X,Y,T,AUC] = perfcurve(expected,P(:,2)',2);

figure;plot(X,Y)
xlabel('False positive rate')
ylabel('True positive rate')
title('ROC for Classification of P300')


end
