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

siftdescriptordensity=1;
Fs=256;
windowsize=1;
expcode=2400;
show=0;
downsize=16;
applyzscore=true;
featuretype=1;
distancetype='cosine';
classifier=5;

featuretype=2;
timescale=1;
applyzscore=false;
% =====================================

% EEG(subject,trial,flash)
EEG = loadEEG(Fs,windowsize,downsize,120,1:8,1:8);

% CONTROL
%EEG = randomizeEEG(EEG);

trainingRange = 1:nbofclassespertrial*15;

tic
Fs=Fs/downsize;

sqKS = [37; 19; 37; 38; 33; 35; 35; 37];


% Epoching
globalnumberofsamples=1200000;
globalnumberofepochs=12000000;

for subject=subjectRange
    epoch=0;
    labelRange=[];
    epochRange=[];
    stimRange=[];
    routput = [];
    boutput = [];
    rcounter = 0;
    bcounter = 0;
    processedflashes = 0;    
    for trial=1:35
        for flash=1:120
            
            % Skip artifacts
            if (EEG(subject,trial,flash).isartifact)
                continue;
            end

            label = EEG(subject,trial,flash).label;
            output = EEG(subject,trial,flash).EEG;
            
            processedflashes = processedflashes+1;
            
            if ((label==2) && (rcounter<globalnumberofepochs))
                routput = [routput; output];
                rcounter=rcounter+1;
            end
            if ((label==1) && (bcounter<globalnumberofepochs))
                boutput = [boutput; output];
                bcounter=bcounter+1;
            end

        end
    end 
    if (size(routput,1) >= 2)
        %assert( bcounter == rcounter, 'Averages are calculated from different sizes');
    
        %assert( size(boutput,1) == size(routput,1), 'Averages are calculated from different sizes.')
    
        assert( (size(routput,1) >= 2 ), 'There arent enough epoch windows to average.');
   
        routput=reshape(routput,[Fs size(routput,1)/Fs 8]);
        boutput=reshape(boutput,[Fs size(boutput,1)/Fs 8]);

        for channel=channelRange
            rmean(:,channel) = mean(routput(:,:,channel),2);
            bmean(:,channel) = mean(boutput(:,:,channel),2);
        end

        subjectaverages{subject}.rmean = rmean;
        subjectaverages{subject}.bmean = bmean;  
 
    end
end

%%
for subject=1:8
    rmean = subjectaverages{subject}.rmean;
    bmean = subjectaverages{subject}.bmean;
    
    %[n,m]=size(rmean);
    %rmean=rmean - ones(n,1)*mean(rmean,1);
            
    %[n,m]=size(bmean);
    %bmean=bmean - ones(n,1)*mean(bmean,1);
    
    fig = figure(3);

    subplot(4,2,subject);
    
    hold on;
    Xi = 0:0.1:size(rmean,1);
    Yrmean = pchip(1:size(rmean,1),rmean(:,2),Xi);
    Ybmean = pchip(1:size(rmean,1),bmean(:,2),Xi);
    plot(Xi,Yrmean,'r','LineWidth',2);
    plot(Xi,Ybmean,'b--','LineWidth',2);
    %plot(rmean(:,2),'r');
    %plot(bmean(:,2),'b');
    axis([0 Fs -6 6]);
    set(gca,'XTick', [Fs/4 Fs/2 Fs*3/4 Fs]);
    set(gca,'XTickLabel',{'0.25','.5','0.75','1s'});
    set(gca,'YTick', [-5 0 5]);
    set(gca,'YTickLabel',{'-5 uV','0','5 uV'});
    set(gcf, 'renderer', 'opengl')
    %hx=xlabel('Repetitions');
    %hy=ylabel('Accuracy');
    set(0, 'DefaultAxesFontSize',18);
    text(0.5,4.5,sprintf('Subject %s',subject),'FontWeight','bold');
    %set(hx,'fontSize',20);
    %set(hy,'fontSize',20);
end
legend('Target','NonTarget');
hold off
