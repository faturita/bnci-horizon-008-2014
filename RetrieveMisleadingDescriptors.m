function [reinf1, reinf2] = RetrieveMisleadingDescriptors(F,testRange,SC,DE,TIX)

show=false;
reinf1=zeros(1,size(DE.C(1).IX,1));
reinf2=zeros(1,size(DE.C(2).IX,1));

ID1 = [];
ID2 = [];

% First get the list of descriptors that were used to classify
for test=testRange    
   ID1 = [ID1 SC.CLSF{test}.IDX{1}];
   ID2 = [ID2 SC.CLSF{test}.IDX{2}];
    
end

if (show)
    figure; histogram(ID1);
    figure; histogram(ID2);
end

% First lets find where is the difference.
diffs = SC.expected-SC.predicted;

% IDs has the id list to testRange where the classification failed.
IDs = find(diffs~=0);

%fprintf('Wrong pedictions...');
%SC.predicted(IDs)

[reinf1, reinf2] = ReinforceDescriptors(F,testRange,reinf1,reinf2,IDs,SC, DE,TIX,(-1)); 
   
% IDs has the id list to testRange where the classification failed.
IDs = find(diffs==0);

%fprintf('Good predictions...');
%SC.predicted(IDs)

[reinf1, reinf2] = ReinforceDescriptors(F,testRange,reinf1,reinf2,IDs,SC, DE,TIX,(+1)); 

reinf1=find(reinf1<0);
reinf2=find(reinf2<0);

reinf1=sort(reinf1,'descend');
reinf2=sort(reinf2,'descend');
 
%dlmwrite('reinf1.dat',reinf1);
%dlmwrite('reinf2.dat',reinf2);

end

function [reinf1, reinf2] = ReinforceDescriptors(F,testRange,reinf1, reinf2,IDs, SC,DE,TIX, reinforcement)
show=false;
for ID=IDs    
    IDX=SC.CLSF{testRange(ID)}.IDX;

    d1=DE.C(1).IX(IDX{1},:);
    d2=DE.C(2).IX(IDX{2},:);    
    dT=TIX(ID,:);
    
    if (show)
        figure;DisplayDescriptorImageFull(F,dT(3),dT(2),dT(1),dT(4),true);

        figure('Name','Class 1','NumberTitle','off')
        setappdata(gcf, 'SubplotDefaultAxesLocation', [0, 0, 1, 1]);
        fcounter=1;
        for i=1:size(d1,1)
            ah=subplot_tight(5,1,fcounter,[0 0]);
            DisplayDescriptorImageFull(F,d1(i,3),d1(i,2),d1(i,1),d1(i,4),true);
            fcounter=fcounter+1;
        end


        figure('Name','Class 2 P300','NumberTitle','off')
        setappdata(gcf, 'SubplotDefaultAxesLocation', [0, 0, 1, 1]);
        fcounter=1;
        for i=1:size(d2,1)
            ah=subplot_tight(5,1,fcounter,[0 0]);
            DisplayDescriptorImageFull(F,d2(i,3),d2(i,2),d2(i,1),d2(i,4),true);
            fcounter=fcounter+1;
        end 
    end
    

    sums = [];
    for i=1:size(d1,1)
        n = norm( F(dT(1),dT(2),dT(3)).descriptors - F(d1(i,1),d1(i,2),d1(i,3)).descriptors );
        sums = [sums n];
    end
    %sums
    
    sums = [];
    for i=1:size(d2,1)
        n = norm( F(dT(1),dT(2),dT(3)).descriptors - F(d2(i,1),d2(i,2),d2(i,3)).descriptors );
        sums = [sums n];
    end
    %sums
    
    % Reinf contains the histogram for each descriptor telling me how well
    % or how bad the descriptor were used to classify.
    if (SC.predicted(testRange(ID) == 1))
        for id=IDX{1}
            reinf1(id) = reinf1(id) + 1 * reinforcement ;
        end
    else
        for id=IDX{2}
            reinf2(id) = reinf2(id) + 1 * reinforcement;
        end
    end
    
end

end