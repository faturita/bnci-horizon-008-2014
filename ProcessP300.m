% Signal Averaging x Selection classification of P300 008-2014 dataset.

% run('/Users/rramele/work/vlfeat/toolbox/vl_setup')
% run('D:/workspace/vlfeat/toolbox/vl_setup')
% run('C:/vlfeat/toolbox/vl_setup')
% P300 for ALS patients.

%clear all;
%close all;

rng(396544);

globalnumberofepochspertrial=10;
globalaverages= cell(2,1);
globalartifacts = 0;
globalreps=10;
globalnumberofepochs=(2+10)*globalreps-1;
%for globalnumberofsamples=12*[10:-1:1]-1

clear mex;clearvars  -except global*;close all;clc;

nbofclassespertrial=(2+10)*(10/globalreps);
breakonepochlimit=(2+10)*10-1;

% Clean all the directories where the images are located.
cleanimagedirectory();


% NN.NNNNN
% data.X(sample, channel)
% data.y(sample)  --> 0: no, 1:nohit, 2:hit
% data.y_stim(sample) --> 1-12, 1-6 cols, 7-12 rows

%     'Fz'    'Cz'    'Pz'    'Oz'    'P3'    'P4'    'PO7'    'PO8'

channels={ 'Fz '  ,  'Cz ',    'Pz ' ,   'Oz '  ,  'P3 '  ,  'P4 '   , 'PO7'   , 'PO8'};


% Parameters ==========================
subjectRange=1:8;
epochRange = 1:120*7*5;
channelRange=1:8;
labelRange = [];
siftscale = [4*3 8];  % Determines lamda length [ms] and signal amp [microV]
imagescale=5*4;    % Para agarrar dos decimales NN.NNNN
timescale=4*4;
qKS=128-13;
%qKS=ceil(0.29*Fs*imagescale):floor(0.29*Fs*imagescale+Fs*imagescale/4-1);

siftscale = [3 3];  % Determines lamda length [ms] and signal amp [microV]
imagescale=4;    % Para agarrar dos decimales NN.NNNN
timescale=4;
qKS=32-3;
minimagesize=floor(sqrt(2)*15*siftscale(2)+1);
amplitude=3;
adaptative=false;
k=7;

siftdescriptordensity=1;
Fs=256;
windowsize=5;
expcode=2400;
show=0;
% =====================================
downsize=16;


% EEG(subject,trial,flash)
EEG = loadEEG(Fs,windowsize,downsize,120,1:8,1:8);

% CONTROL
%EEG = randomizeEEG(EEG);

trainingRange = 1:nbofclassespertrial*15;


tic
Fs=Fs/downsize;

sqKS = [37; 19; 37; 38; 33; 35; 35; 37];

EP=[];CF=[];
for subject=subjectRange
    epoch=0;
    dotest=false;
    for trial=1:35
        for i=1:12 routput{i}=[]; end
        for i=1:12 rcounter{i}=0; end
        processedflashes = 0;
        bpickercounter = 0;
        bwhichone = [0 1];%bwhichone=sort(randperm(10,2)-1);
        for flash=1:120
            if ((breakonepochlimit>0) && (processedflashes > breakonepochlimit))
                break;
            end
            % Process one epoch if the number of flashes has been reached.
            if (processedflashes>globalnumberofepochs)
                P300ProcessSegment;
                processedflashes=0;
            end
            
            % Skip artifacts
            if (EEG(subject,trial,flash).isartifact)
                %continue;
            end
            
            if (mod(flash-1,12)==0)
                bpickercounter = 0;
                bwhichone = [0 1];%bwhichone=sort(randperm(10,2)-1);
            end
            
            labelh = EEG(subject,trial,flash).label;
            output = EEG(subject,trial,flash).EEG;
            stim = EEG(subject,trial,flash).stim;
            
            processedflashes = processedflashes+1;
            
            hit{stim} = labelh;
            
            if (rcounter{stim}<globalnumberofepochspertrial)
                routput{stim} = [routput{stim}; output];
                rcounter{stim}=rcounter{stim}+1;
            end
            
        end
        P300ProcessSegment;
        
    end
    toc
    
    %%
    epochRange=1:epoch;
    trainingRange = 1:nbofclassespertrial*15;
    testRange=nbofclassespertrial*15+1:min(nbofclassespertrial*35,epoch);
    
    %trainingRange=1:nbofclasses*35;
    
    SBJ(subject).F = F;
    SBJ(subject).epochRange = epochRange;
    SBJ(subject).labelRange = labelRange;
    SBJ(subject).trainingRange = trainingRange;
    SBJ(subject).testRange = testRange;
    
    
    %%
    for channel=channelRange
        fprintf('Channel %d\n', channel);
        fprintf('Building Test Matrix M for Channel %d:', channel);
        [TM, TIX] = BuildDescriptorMatrix(F,channel,labelRange,testRange);
        fprintf('%d\n', size(TM,2));
        
        DE = NBNNFeatureExtractor(F,channel,trainingRange,labelRange,[1 2],false);
        
        iterate=true;
        balancebags=false;
        while(iterate)
            fprintf('Bag Sizes %d vs %d \n', size(DE.C(1).IX,1),size(DE.C(2).IX,1));
            %[ACC, ERR, AUC, SC] = LDAClassifier(F,DE,channel,trainingRange,testRange,labelRange,false);
            [ACC, ERR, AUC, SC] = NBNNClassifier4(F,DE,channel,testRange,labelRange,false,'cosine',k);
            %[ACC, ERR, AUC, SC] = NNetClassifier(F,DE,labelRange,trainingRange,testRange,channel)
            P = SC.TN / (SC.TN+SC.FN);
            globalaccij1(subject,channel)=1-ERR/size(testRange,2);
            globalaccij2(subject,channel)=AUC;
            
            iterate=false;
            
            if (adaptative)
                [reinf1, reinf2] = RetrieveMisleadingDescriptors(F,testRange,SC,DE,TIX);

                if ((balancebags==false))
                    iterate=true;
                    exclude{1}=reinf1;
                    exclude{2}=reinf2;

                    if ((size(reinf1,2)==0) && (size(reinf2,2)==0) )
                        balancebags=true;
                    end

                    DE = NBNNIterativeFeatureExtractor(DE,[1 2],exclude,balancebags);
                    
                    assert( size(DE.C(1).IX,1) > 0, 'No more descriptors to prune');
                    assert( size(DE.C(2).IX,1) > 0, 'No more descriptors to prune');
                else
                    fprintf('Nothing more to update.\n');
                    iterate=false;
                end
            else
                % Just one iteration.  I wonder why matlab do not have do
                % until.
                iterate = false;
            end
        end
        SBJ(subject).DE(channel) = DE;
        SBJ(subject).SC(channel) = SC;
    end


    % '2'    'B'    'A'    'C'    'I'    '5'    'R'    'O'    'S'    'E'    'Z'  'U'    'P'    'P'    'A'   
    % 'G' 'A' 'T' 'T' 'O'    'M' 'E' 'N''T' 'E'   'V''I''O''L''A'  'R''E''B''U''S'
    Speller = SpellMe(F,channelRange,16:35,labelRange,trainingRange,testRange,SBJ(subject).SC);

    S = 'GATTOMENTEVIOLAREBUS';

    SpAcc = [];
    for channel=channelRange
        counter=0;
        for i=1:size(S,2)
            if Speller{channel}{i}==S(i)
                counter=counter+1;
            end
        end
        SpAcc(end+1) = counter/size(S,2);
    end
    [a,b] = max(SpAcc)


    %SpellerDecoder
    
    %savetemplate(subject,globalaverages,channelRange);
    %save(sprintf('subject.%d.mat', subject));
end

%%
for subject=subjectRange
    % '2'    'B'    'A'    'C'    'I'    '5'    'R'    'O'    'S'    'E'    'Z'  'U'    'P'    'P'    'A'   
    % 'G' 'A' 'T' 'T' 'O'    'M' 'E' 'N''T' 'E'   'V''I''O''L''A'  'R''E''B''U''S'
    Speller = SpellMe(F,channelRange,16*nbofclassespertrial/12:35*nbofclassespertrial/12+(nbofclassespertrial/12-1),labelRange,trainingRange,testRange,SBJ(subject).SC);

    S = 'GATTOMENTEVIOLAREBUS';
    S = repmat(S,nbofclassespertrial/12);
    S = reshape( S, [1 size(S,1)*size(S,2)]);
    S=S(1:size(S,2)/(nbofclassespertrial/12));
    
    SpAcc = [];
    for channel=channelRange
        counter=0;
        for i=1:size(S,2)
            if Speller{channel}{i}==S(i)
                counter=counter+1;
            end
        end
        spellingacc = counter/size(S,2);
        SpAcc(end+1) = spellingacc;
        globalspeller(subject,channel) = spellingacc;
    end
    [a,b] = max(SpAcc);
end


%%
% hold on
% for subject=1:1
%     for trial=1:1
%         for i=1:12
%             plot(globalaverages{subject}{trial}{i}.rmean(:,channel));
%         end
%     end
% end
% hold off



%%
subject=1;
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

%%
experiment=sprintf('Hellinger. Butter de 3 a 4, K = %d, upsampling a 16, zscore a 3,NBNN con artefactos, cosine float, unweighted without artifacts ',k);
fid = fopen('experiment.log','a');
fprintf(fid,'Experiment: %s \n', experiment);
fprintf(fid,'st %f sv %f scale %f timescale %f qKS %d\n',siftscale(1),siftscale(2),imagescale,timescale,qKS);
totals = DisplayTotals(subjectRange,globalaccij1,globalspeller,globalaccij2,globalspeller,channels)
totals(:,6)
fclose(fid)
%%
DisplayDescriptorImageFull(F,1,2,1,1,1,false);
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