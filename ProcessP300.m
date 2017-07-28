% Signal Averaging x Selection classification of P300 008-2014 dataset.

% run('/Users/rramele/work/vlfeat/toolbox/vl_setup')
% run('D:\MATLAB\vlfeat-0.9.18\toolbox\vl_setup');
% run('C:/vlfeat/toolbox/vl_setup')
% P300 for ALS patients.

clear all;
close all;

rng(396544);

globalnumberofepochs=10;
globalaverages= cell(2,1);
globalartifacts = 0;
globalnumberofsamples=(2+10)*1-1;
%for globalnumberofsamples=12*[10:-1:1]-1

clear mex;clearvars  -except global*;close all;clc;

nbofclasses=(2+10)*10;

% Clean all the directories where the images are located.
cleanimagedirectory();


% NN.NNNNN
% data.X(sample, channel)
% data.y(sample)  --> 0: no, 1:nohit, 2:hit
% data.y_stim(sample) --> 1-12, 1-6 cols, 7-12 rows

%     'Fz'    'Cz'    'Pz'    'Oz'    'P3'    'P4'    'PO7'    'PO8'

channels={ 'Fz'  ,  'Cz',    'Pz' ,   'Oz'  ,  'P3'  ,  'P4'   , 'PO7'   , 'PO8'};


% Parameters ==========================
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
qKS=32-4;
minimagesize=floor(sqrt(2)*15*siftscale(2)+1);
adaptative=false;

siftdescriptordensity=1;
Fs=256;
windowsize=1;
expcode=2400;
show=0;
% =====================================
downsize=16;

% EEG(subject,trial,flash)
EEG = loadEEG(Fs,windowsize,downsize,120,1:8,1:8);

% CONTROL
%EEG = randomizeEEG(EEG);

tic
Fs=Fs/downsize;
%qKS=ceil(0.29*Fs*timescale):floor(0.29*Fs*timescale+Fs*timescale/4-1);
EP=[];CF=[];
for subject=1:8
    epoch=0;
    for trial=1:35
        for i=1:12 routput{i}=[]; end
        for i=1:12 rcounter{i}=0; end
        processedflashes = 0;
        bpickercounter = 0;
        bwhichone = [0 1];%bwhichone=sort(randperm(10,2)-1);
        for flash=1:120
            
            % Process one epoch if the number of flashes has been reached.
            if (processedflashes>globalnumberofsamples)
                P300ProcessSegment;
                processedflashes=0;
            end
            
            % Skip artifacts
            if (EEG(subject,trial,flash).isartifact)
                continue;
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
            
            if (rcounter{stim}<globalnumberofepochs)
                routput{stim} = [routput{stim}; output];
                rcounter{stim}=rcounter{stim}+1;
            end
            
        end
        P300ProcessSegment;
        
    end
    toc
    
    
    %%
    epochRange=1:epoch;
    trainingRange = 1:nbofclasses*15;
    testRange=nbofclasses*15+1:min(nbofclasses*35,epoch);
    
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
            [ACC, ERR, AUC, SC] = NBNNClassifier(F,DE,channel,testRange,labelRange,false);
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
    
    %SpellerDecoder
    
    %savetemplate(subject,globalaverages,channelRange);
    %save(sprintf('subject.%d.mat', subject));
end


%%
for subject=1:8
    
    for channel=channelRange
        acce = 0;
        for i=1:20
            ri = globalspeller{subject}{channel};
            if (ri(i,1)==ri(i,5) && ri(i,2)==ri(i,6))
                acce = acce+1;
            end
        end
        globalaccij3(subject,channel)=acce/20;
    end
end

totals = DisplayTotals(globalaccij3,channels)
totals(:,6)


%%
hold on
for subject=1:1
    for trial=1:1
        for i=1:12
            plot(globalaverages{subject}{trial}{i}.rmean(:,channel));
        end
    end
end
hold off


%%
subject=3;
channel=2;
SC=SBJ(subject).SC(channel);
ML=SBJ(subject).DE(channel);
F=SBJ(subject).F;
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

%%
fid = fopen('output.txt','a');
fprintf(fid,'Experiment\n');
fprintf(fid,'st %f sv %f scale %f timescale %f qKS %d\n',siftscale(1),siftscale(2),imagescale,timescale,qKS);
totals = DisplayTotals(globalaccij2,globalaccij1,channels)
totals(:,6)
fclose(fid)