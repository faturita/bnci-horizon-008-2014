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

    for channel=channelRange
        rmean{i}(:,channel) = mean(routput{i}(:,:,channel),2);
    end

    routput{i}=[]; 
    rcounter{i}=0;
    
    if (hit{i} == 2)
        h = [h i];
    end
    
end

% Inject signals to rebalance the dataset.
rebalancedataset=false;
if (rebalancedataset)
    for channel=channelRange

        hitsignals = smoteeeg(rmean{h(1)},rmean{h(2)},Fs,8);

        for i=13:20
            rmean{i}(:,channel) = hitsignals(:,i-12);
            hit{i} = 2;
        end

    end
end


for i=1:12

    for c=channelRange
        rsignal{i}(:,c) = resample(rmean{i}(:,c),size(rmean{i},1)*4,16);
    end

    rsignal{i} = zscore(rsignal{i})*3; 
    timescale = 1;
    
    [n,m]=size(rmean{i});
    rmean{i}=rmean{i} - ones(n,1)*mean(rmean{i},1);
            
    globalaverages{subject}{trial}{i}.rmean = rmean{i};
    
    if ( (hit{i} == 2 && hitcounter{2}<20) || (hit{i}==1 && hitcounter{1}<20) )
        hitcounter{hit{i}}=hitcounter{hit{i}}+1;
        epoch=epoch+1;    
        label = hit{i};
        labelRange(epoch) = label;
        stimRange(epoch) = i;
        for channel=channelRange
            [eegimg, DOTS, zerolevel] = eegimage(channel,rsignal{i},imagescale,timescale, false,minimagesize);

            saveeegimage(subject,epoch,label,channel,eegimg);
            zerolevel = size(eegimg,1)/2;

            [frames, desc] = PlaceDescriptorsByImage(eegimg, DOTS,siftscale, siftdescriptordensity,qKS,zerolevel);

            desc = single(desc);

            F(channel,label,epoch).hit = hit{i};
            F(channel,label,epoch).descriptors = desc;
            F(channel,label,epoch).frames = frames;   
            F(channel,label,epoch).stim = i;
             
        end
        EP = [EP; [epoch subject trial 1]];
    end
end

            