% EEG(subject,trial,flash)
function EEG = loadEEG(Fs, windowsize, downsize, flashespertrial, subjectRange,channelRange)

%EEG = zeros(size(subjectRange,2),size(datatrial,2),flashespertrial);
artifactcount = 0;            
            
for subject=subjectRange
    clear data.y_stim
    clear data.y
    clear data.X
    clear data.trial
    load(sprintf('%s%s008-2014%sA%02d.mat',getdatasetpath(),filesep,filesep,subject));

    dataX = notchsignal(data.X, channelRange, Fs);
    datatrial = data.trial;

    
    dataX = bandpasseeg(dataX, channelRange,Fs);
    dataX = decimatesignal(dataX,channelRange,downsize); 
    
    
    %dataX = decimateaveraging(dataX,channelRange,downsize);
    %dataX = downsample(dataX,downsize);
    
    
    
    %l=randperm(size(data.y,1));
    %data.y = data.y(l);
       
    for trial=1:size(datatrial,2)
        for flash=1:flashespertrial
            
            % Mark this 12 repetition segment as artifact or not.
            if (mod((flash-1),12)==0)
                iteration = extract(dataX, (ceil(data.trial(trial)/downsize)+64/downsize*(flash-1)),64/downsize*12);
                artifact=isartifact(iteration,70);        
            end         
            
            %EEG(subject,trial,flash).EEG = zeros((Fs/downsize)*windowsize,size(channelRange,2));

            if (windowsize>=2)
                output = baselineremover(dataX,(ceil(datatrial(trial)/downsize)+ceil(64/downsize)*(flash-1))-floor((Fs/downsize)*windowsize/4),...
                    ceil((Fs/downsize)*windowsize),...
                    channelRange,...
                    downsize);
            else
                output = baselineremover(dataX,(ceil(datatrial(trial)/downsize)+ceil(64/downsize)*(flash-1)),...
                    ceil((Fs/downsize)*windowsize),...
                    channelRange,...
                    downsize);
                
                output = baselineremover(dataX,ceil(datatrial(trial)/downsize+64/downsize*(flash-1)),...
                    ceil((Fs/downsize)*windowsize),...
                    channelRange,...
                    downsize);
            end

            EEG(subject,trial,flash).label = data.y(data.trial(trial)+64*(flash-1));
            EEG(subject,trial,flash).stim = data.y_stim(data.trial(trial)+64*(flash-1));
            
            % Enrich signal with a previous stored p300 signature.
            if (EEG(subject,trial,flash).label==20)
               p300 = dlmread(sprintf('realp300s.%d.t.%d.mat',subject,trial)); 

               output = output + p300*4;
               
               output = zeros((Fs/downsize)*windowsize,size(channelRange,2));
               output = fakeeegoutput(4, EEG(subject,trial,flash).label, 1:8,16);
            end
             
            
            EEG(subject,trial,flash).isartifact = false;
            if (artifact)
                artifactcount = artifactcount + 1;
                EEG(subject,trial,flash).isartifact = true;
            end
            
            % This is a very important step, do not forget it.
            % Rest the media from the epoch.
            % It only works to move the second from 80 -> 85.
            [n,m]=size(output);
            output=output - ones(n,1)*mean(output,1); 
            
            %output = zscore(output)*2;

            EEG(subject,trial,flash).EEG = output;

        end
    end
end

end