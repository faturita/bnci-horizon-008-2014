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

clear mex;clearvars  -except global*;close all;clc;

nbofclassespertrial=(2+10)*(10/globalreps);
breakonepochlimit=(2+10)*globalrepetitions-1;

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
siftscale = [3 3];  % Determines lamda length [ms] and signal amp [microV]
imagescale=4;    % Para agarrar dos decimales NN.NNNN
timescale=4;
qKS=32-3;
minimagesize=floor(sqrt(2)*15*siftscale(2)+1);
amplitude=3;
adaptative=false;
k=7;
artifactcheck=true;

siftdescriptordensity=1;
Fs=256;
windowsize=1;
expcode=2400;
show=0;
downsize=16;
applyzscore=true;
featuretype=1;
distancetype='cosine';
classifier=6;

% featuretype=2;
% timescale=1;
% applyzscore=false;
% classifier=1;
% amplitude=1;
% windowsize=1;
% =====================================

% EEG(subject,trial,flash)
EEG = loadEEG(Fs,windowsize,downsize,120,1:8,channelRange);

% CONTROL
%EEG = randomizeEEG(EEG);

trainingRange = 1:nbofclassespertrial*15;

tic
Fs=Fs/downsize;

sqKS = [37; 19; 37; 38; 33; 35; 35; 37];

%%
% Build routput pasting epochs toghether...
for subject=subjectRange
    for trial=1:35
        for i=1:12 hit{subject}{trial}{i} = 0; end
        for i=1:12 routput{subject}{trial}{i} = []; end
        processedflashes=0;
        for flash=1:120
            if ((breakonepochlimit>0) && (processedflashes > breakonepochlimit))
                break;
            end            
            % Skip artifacts
            if (artifactcheck && EEG(subject,trial,flash).isartifact)
                continue;
            end
            processedflashes = processedflashes+1;
            output = EEG(subject,trial,flash).EEG;
            routput{subject}{trial}{EEG(subject,trial,flash).stim} = [routput{subject}{trial}{EEG(subject,trial,flash).stim} ;output];
            hit{subject}{trial}{EEG(subject,trial,flash).stim} = EEG(subject,trial,flash).label;
        end
    end
end

for subject=subjectRange
    for trial=1:35
        for i=1:12 rcounter{subject}{trial}{i} = 0; end
        for flash=1:120 
            rcounter{subject}{trial}{EEG(subject,trial,flash).stim} = rcounter{subject}{trial}{EEG(subject,trial,flash).stim}+1;
        end
        % Check if all the epochs contain 10 repetitions.
        for i=1:12
            assert( rcounter{subject}{trial}{i} == 10 );
        end
    end
end

for subject=subjectRange
    h=[];
    Word=[];
    for trial=1:35
        hh = [];
        for i=1:12
            rput{i} = routput{subject}{trial}{i};
            channelRange = (1:size(rput{i},2));
            channelsize = size(channelRange,2);

            assert( globalrepetitions<10 || artifactcheck || size(rput{i},1)/(Fs*windowsize) == rcounter{subject}{trial}{i}, 'Something wrong with PtP average. Sizes do not match.');

            rput{i}=reshape(rput{i},[(Fs*windowsize) size(rput{i},1)/(Fs*windowsize) channelsize]); 

            %dly = de2bi(globaldelays,10);
            %rput{i} = TimeWarping(rput{i},dly,channelRange);
            
            %rput{i} = DynamicTimeWarping(rput{i},channelRange);
            
            %rput{i}= rput{i}(size(rput{i},1)/4+1:size(rput{i},1)/4+1+size(rput{i},1)/2-1,:,:);
            
            for channel=channelRange
                rmean{i}(:,channel) = mean(rput{i}(:,:,channel),2);
            end

            if (hit{subject}{trial}{i} == 2)
                h = [h i];
                hh = [hh i];
            end    
            routput{subject}{trial}{i} = rmean{i};
        end
        Word = [Word SpellMeLetter(hh(1),hh(2))];
    end
end

for subject=subjectRange
    for trial=1:35
        
        for i=1:12

            rmean{i} = routput{subject}{trial}{i};
            
            if (timescale ~= 1)
                for c=channelRange
                    %rsignal{i}(:,c) = resample(rmean{i}(:,c),size(rmean{i},1)*timescale,size(rmean{i},1));
                    rsignal{i}(:,c) = resample(rmean{i}(:,c),1:size(rmean{i},1),timescale);
                end
            else
                rsignal{i} = rmean{i};
            end

            if (applyzscore)
                rsignal{i} = zscore(rsignal{i})*amplitude;
            else
                rsignal{i} = rsignal{i}*amplitude;
            end
            
            routput{subject}{trial}{i} = rsignal{i};
        end
    end
end




if (featuretype == 1)
    for subject=subjectRange
        epoch=0;
        labelRange=[];
        epochRange=[];
        stimRange=[];
        for trial=1:35        
            for i=1:12
            epoch=epoch+1;    
            label = hit{subject}{trial}{i};
            labelRange(epoch) = label;
            stimRange(epoch) = i;
            DS = [];
            rsignal{i}=routput{subject}{trial}{i};
            for channel=channelRange
                %minimagesize=1;
                [eegimg, DOTS, zerolevel] = eegimage(channel,rsignal{i},imagescale,1, false,minimagesize);
                %siftscale(1) = 11.7851;
                %siftscale(2) = (height-1)/(sqrt(2)*15);
                saveeegimage(subject,epoch,label,channel,eegimg);
                zerolevel = size(eegimg,1)/2;

    %             if ((size(find(trainingRange==epoch),2)==0))
    %                qKS=ceil(0.20*(Fs)*timescale):floor(0.20*(Fs)*timescale+(Fs)*timescale/4-1);
    %             else
                    qKS=sqKS(subject);
                    %qKS=125;
    %             end

                [frames, desc] = PlaceDescriptorsByImage(eegimg, DOTS,siftscale, siftdescriptordensity,qKS,zerolevel,false,distancetype);            
                F(channel,label,epoch).stim = i;
                F(channel,label,epoch).hit = hit{subject}{trial}{i};


                F(channel,label,epoch).descriptors = desc;
                F(channel,label,epoch).frames = frames; 
            end
            end
        end
        
        epochRange=1:epoch;
        trainingRange = 1:nbofclassespertrial*15;
        testRange=nbofclassespertrial*15+1:min(nbofclassespertrial*35,epoch);

        %trainingRange=1:nbofclasses*35;

        SBJ(subject).F = F;
        SBJ(subject).epochRange = epochRange;
        SBJ(subject).labelRange = labelRange;
        SBJ(subject).trainingRange = trainingRange;
        SBJ(subject).testRange = testRange;
        
    end
else
    for subject=subjectRange
        epoch=0;
        labelRange=[];
        epochRange=[];
        stimRange=[];
        for trial=1:35        
            for i=1:12
                epoch=epoch+1;    
                label = hit{subject}{trial}{i};
                labelRange(epoch) = label;
                stimRange(epoch) = i;
                DS = [];
                rsignal{i}=routput{subject}{trial}{i};

                feature = [];

                for channel=channelRange
                    feature = [feature ; rsignal{i}(:,channel)];
                end  

                for channel=channelRange
                    F(channel,label,epoch).hit = hit{subject}{trial}{i};
                    F(channel,label,epoch).descriptors = feature;
                    F(channel,label,epoch).frames = [];   
                    F(channel,label,epoch).stim = i;
                end    
            end
        end
        epochRange=1:epoch;
        trainingRange = 1:nbofclassespertrial*15;
        testRange=nbofclassespertrial*15+1:min(nbofclassespertrial*35,epoch);

        %trainingRange=1:nbofclasses*35;

        SBJ(subject).F = F;
        SBJ(subject).epochRange = epochRange;
        SBJ(subject).labelRange = labelRange;
        SBJ(subject).trainingRange = trainingRange;
        SBJ(subject).testRange = testRange;        
    end
    channelRange = 1:1;
end


for subject=subjectRange  
    
    F=SBJ(subject).F;
    epochRange=SBJ(subject).epochRange;
    labelRange=SBJ(subject).labelRange;
    trainingRange=SBJ(subject).trainingRange;
    testRange=SBJ(subject).testRange;
        
    switch classifier
        case 5
            for channel=channelRange
                [DE(channel), ACC, ERR, AUC, SC(channel)] = LDAClassifier(F,labelRange,trainingRange,testRange,channel);
                globalaccij1(subject,channel)=ACC;
                globalsigmaaccij1 = globalaccij1;
                globalaccij2(subject,channel)=AUC;
            end  
        case 4
            for channel=channelRange
                [DE(channel), ACC, ERR, AUC, SC(channel)] = SVMClassifier(F,labelRange,trainingRange,testRange,channel);
                globalaccij1(subject,channel)=ACC;
                globalsigmaaccij1 = globalaccij1;
                globalaccij2(subject,channel)=AUC;
            end            
        case 1
            for channel=channelRange
                [DE(channel), ACC, ERR, AUC, SC(channel)] = NNetClassifier(F,labelRange,trainingRange,testRange,channel);
                globalaccij1(subject,channel)=ACC;
                globalsigmaaccij1 = globalaccij1;
                globalaccij2(subject,channel)=AUC;
            end
        case 2
            [AccuracyPerChannel, SigmaPerChannel] = CrossValidated(F,epochRange,labelRange,channelRange, @IterativeNBNNClassifier,1);
            globalaccij1(subject,:)=AccuracyPerChannel
            globalsigmaaccij1(subject,:)=SigmaPerChannel;
            globalaccijpernumberofsamples(globalnumberofepochs,subject,:) = globalaccij1(subject,:);
        case 3
            for channel=channelRange
                [DE(channel), ACC, ERR, AUC, SC(channel)] = IterativeNBNNClassifier(F,channel,trainingRange,labelRange,testRange,false,false);

                globalaccij1(subject,channel)=1-ERR/size(testRange,2);
                globalaccij2(subject,channel)=AUC;
                globalsigmaaccij1 = globalaccij1;
            end
        case 6
            for channel=channelRange
                DE(channel) = NBNNFeatureExtractor(F,channel,trainingRange,labelRange,[1 2],false); 
   
                %[ACC, ERR, AUC, SC(channel)] = NBMultiClass(F,DE(channel),channel,testRange,labelRange,distancetype,k);
                [ACC, ERR, AUC, SC(channel)] = NBNNClassifier4(F,DE(channel),channel,testRange,labelRange,false,distancetype,k);                                                        
                
                globalaccij1(subject,channel)=1-ERR/size(testRange,2);
                globalaccij2(subject,channel)=AUC;
                globalsigmaaccij1 = globalaccij1;
            end

    end
    SBJ(subject).DE = DE;
    SBJ(subject).SC = SC;
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
        %globalspeller(subject,channel,globaldelays+1) = spellingacc;
        globalspellerrep(subject,channel,globalrepetitions) = spellingacc;
    
    end
    [a,b] = max(SpAcc);
end

experiment=sprintf('Hellinger. Butter de 3 a 4, K = %d, upsampling a 16, zscore a 3,NBNN con artefactos, cosine float, unweighted without artifacts ',k);
fid = fopen('experiment.log','a');
fprintf(fid,'Experiment: %s \n', experiment);
fprintf(fid,'st %f sv %f scale %f timescale %f qKS %d\n',siftscale(1),siftscale(2),imagescale,timescale,qKS);
totals = DisplayTotals(subjectRange,globalaccij1,globalspeller,globalaccij2,globalspeller,channels)
totals(:,6)
fclose(fid)

