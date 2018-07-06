%
subject=8;
channel=7;
SC=SBJ(subject).SC(channel);
ML=SBJ(subject).DE(channel);
F=SBJ(subject).F;

for i=1:30
   figure;DisplayDescriptorImageFull(F,subject,ML.C(2).IX(i,3),ML.C(2).IX(i,2),ML.C(2).IX(i,1),ML.C(2).IX(i,4),false);
end

%%

figure('Name','Class 2 P300','NumberTitle','off');
setappdata(gcf, 'SubplotDefaultAxesLocation', [0, 0, 1, 1]);
fcounter=1;
for i=1:30
    ah=subplot_tight(6,5,fcounter,[0 0]);
    DisplayDescriptorImageFull(F,subject,ML.C(2).IX(i,3),ML.C(2).IX(i,2),ML.C(2).IX(i,1),ML.C(2).IX(i,4),true);
    fcounter=fcounter+1;
end
figure('Name','Class 1','NumberTitle','off');
setappdata(gcf, 'SubplotDefaultAxesLocation', [0, 0, 1, 1]);
fcounter=1;
for i=1:30
    ah=subplot_tight(6,5,fcounter,[0 0]);
    DisplayDescriptorImageFull(F,subject,ML.C(1).IX(i,3),ML.C(1).IX(i,2),ML.C(1).IX(i,1),ML.C(1).IX(i,4),true);
    fcounter=fcounter+1;
end
[TM, TIX] = BuildDescriptorMatrix(F,channel,labelRange,testRange(labelRange(testRange)==2));
fcounter=1;
figure('Name','P300 Query','NumberTitle','off');
setappdata(gcf, 'SubplotDefaultAxesLocation', [0, 0, 1, 1]);
for i=1:30
    ah=subplot_tight(6,5,fcounter,[0 0]);
    DisplayDescriptorImageFull(F,subject,TIX(i,3),TIX(i,2),TIX(i,1),TIX(i,4),true);
    fcounter=fcounter+1;
end
figure('Name','P300 Query (resto)','NumberTitle','off');
setappdata(gcf, 'SubplotDefaultAxesLocation', [0, 0, 1, 1]);
fcounter=1;
for i=30:40
    ah=subplot_tight(2,5,fcounter,[0 0]);
    DisplayDescriptorImageFull(F,subject,TIX(i,3),TIX(i,2),TIX(i,1),TIX(i,4),true);
    fcounter=fcounter+1;
end

%DisplayDescriptorImageFull(F,1,2,1,1,1,false);
%%
figure
hold on
for i=1:size(ML.C(2).M,2)
    plot(ML.C(2).M(:,i),'x');
end
hold off
figure
hold on
pp=randperm(size(ML.C(1).M,2),size(ML.C(2).M,2));
for i=1:size(ML.C(2).M,2)
    plot(ML.C(1).M(:,pp(i)),'x');
end
hold off