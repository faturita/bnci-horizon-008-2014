% Check what you have
assert( size(unique(cell2mat(rcounter)),2)==1, 'PtP Averages were calculated from different sizes.');

% Hit counter regula cuantos elementos se ponen en cada bolsa.
for i=1:2 hitcounter{i}=0; end

A = zeros(1,2);
for i=1:12
    if (1<=i && i<=6 && hit{i}==2)
        A(1) = i;
    elseif (7 <=i && i<=12 && hit{i}==2)
        A(2) = i;
    end
end

CF = [CF;A];

h = [];


for i=1:12
    channelRange = (1:size(routput{i},2));
    channelsize = size(channelRange,2);
        
    assert( size(routput{i},1)/Fs == rcounter{i}, 'Something wrong with PtP average. Sizes do not match.');
    
    routput{i}=reshape(routput{i},[Fs size(routput{i},1)/Fs channelsize]);
end

for i=1:36 loutput{i}=[];end
for i=1:36 lhit{i}=0;end

for k=1:rcounter{1}  
    for s=1:6
        for p=1:6
            loutput{(s-1)*6+p} = [loutput{(s-1)*6+p}; routput{s}(:,k,:)];
            loutput{(s-1)*6+p} = [loutput{(s-1)*6+p}; routput{6+p}(:,k,:)];
        end
    end
end

for s=1:6
    for p=1:6
        if (hit{s}==2 && hit{6+p}==2)
            lhit{(s-1)*6+p} = 2;
        else
            lhit{(s-1)*6+p} = 1;
        end
    end
end

for i=1:12
    routput{i}=[]; 
    rcounter{i}=0;
    
    if (hit{i} == 2)
        h = [h i];
    end    
end

for i=1:36
    loutput{i}=reshape(loutput{i},[Fs size(loutput{i},1)/Fs channelsize]);
end
  
for i=1:36
    for channel=channelRange
        rmean{i}(:,channel) = mean(loutput{i}(:,:,channel),2);
    end
end

for i=1:36

    for c=channelRange
        rsignal{i}(:,c) = resample(rmean{i}(:,c),size(rmean{i},1)*4,16);
    end

    rsignal{i} = zscore(rsignal{i})*3; 
    timescale = 1;
    
    %[n,m]=size(rsignal{i});
    %rsignal{i}=rsignal{i} - ones(n,1)*mean(rsignal{i},1);
            
    globalaverages{subject}{trial}{i}.rmean = rsignal{i};
    
    if ( (lhit{i} == 2 && hitcounter{2}<=20) || (lhit{i}==1 && hitcounter{1}<=20) )
        hitcounter{lhit{i}}=hitcounter{lhit{i}}+1;
        epoch=epoch+1;    
        label = lhit{i};
        labelRange(epoch) = label;
        stimRange(epoch) = i;
        DS = [];
        for channel=channelRange
            [eegimg, DOTS, zerolevel] = eegimage(channel,rsignal{i},imagescale,timescale, false,minimagesize);

            saveeegimage(subject,epoch,label,channel,eegimg);
            zerolevel = size(eegimg,1)/2;

            %qKS = GetQKS(rsignal{i},channel,Fs,timescale,qKS)

            [frames, desc] = PlaceDescriptorsByImage(eegimg, DOTS,siftscale, siftdescriptordensity,qKS,zerolevel);

            F(channel,label,epoch).hit = lhit{i};
            F(channel,label,epoch).descriptors = desc;
            F(channel,label,epoch).frames = frames;   
            F(channel,label,epoch).stim = i;
        end
        
        EP = [EP; [epoch subject trial 1]];
    end
end
