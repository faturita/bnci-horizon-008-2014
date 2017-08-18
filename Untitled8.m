a=[];
for k=1:30

    [ACC, ERR, AUC, SC] = NBNNClassifier5(F,DE,channel,testRange,labelRange,k);


    a(end+1) = AUC;

end


plot(a);

