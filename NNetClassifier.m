function [DE, ACC, ERR, AUC, SC] = NNetClassifier(F,labelRange,trainingRange,testRange,channel)
    DE = NBNNFeatureExtractor(F,channel,trainingRange,labelRange,[1 2],false); 

    fprintf('Channel %d\n', channel);
    fprintf('Building Test Matrix M for Channel %d:', channel);
    [TM, TIX] = BuildDescriptorMatrix(F,channel,labelRange,testRange);
    fprintf('%d\n', size(TM,2));
    
    fprintf('Bag Sizes %d vs %d \n', size(DE.C(1).IX,1),size(DE.C(2).IX,1)); 
 
    expected=labelRange(testRange);
    %try
    %predicted = classify(TM',M',labelRange(trainingRange),'linear');
    %net = feedforwardnet([64],'trainbr');
    net = fitnet([128 64],'traincgb');%'traingdx');128 64
    net.trainParam.showWindow=0;
    net.layers{1}.transferFcn = 'logsig';
    net.layers{2}.transferFcn = 'logsig';
    net = train(net, [DE.C(1).M DE.C(2).M], [DE.C(1).IX(:,2); DE.C(2).IX(:,2)]');

    predicted = net( TM );

    pd = zeros(size(predicted));

    pd(find(predicted>=1.5)) = 2;
    pd(find(predicted<1.5))  = 1;

    predicted = pd;

    %catch
    %predicted = ones(1,size(expected,2))';
    %end

    predicted=predicted;

    C=confusionmat(labelRange(testRange), predicted)

    [X,Y,T,AUC] = perfcurve(expected,predicted,2);

    ACC = (C(1,1)+C(2,2)) / size(predicted,2);
    

    SC.CLSF = {};
    
    ERR = size(predicted,2) - (C(1,1)+C(2,2));

    SC.FP = C(2,1);
    SC.TP = C(2,2);
    SC.FN = C(1,2);
    SC.TN = C(1,1);

    [ACC, (SC.TP/(SC.TP+SC.FP))]

    SC.expected = expected;
    SC.predicted = predicted;  

end