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
        
    assert( size(routput{i},1)/(Fs*windowsize) == rcounter{i}, 'Something wrong with PtP average. Sizes do not match.');
    
    routput{i}=reshape(routput{i},[(Fs*windowsize) size(routput{i},1)/(Fs*windowsize) channelsize]); 

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

% if ((size(find(trainingRange==epoch+1),2)==0))
%    for c=channelRange
%        DEKZ(c) = NBNNFeatureExtractor(F,c,trainingRange,labelRange,[1 2],false);
%    end
% end


for i=1:12

    for c=channelRange
        %rsignal{i}(:,c) = resample(rmean{i}(:,c),size(rmean{i},1)*timescale,size(rmean{i},1));
        rsignal{i}(:,c) = resample(rmean{i}(:,c),1:size(rmean{i},1),timescale);
    end

    if (1==1)
        rsignal{i} = zscore(rsignal{i})*amplitude; 
    else
    
        [n,m]=size(rsignal{i});
        rsignal{i}=rsignal{i} - ones(n,1)*mean(rsignal{i},1);

        rsignal{i} = rsignal{i}*amplitude;
    end
            
    globalaverages{subject}{trial}{i}.rmean = rsignal{i};
    
    if ( (hit{i} == 2 && hitcounter{2}<20) || (hit{i}==1 && hitcounter{1}<20) )
        hitcounter{hit{i}}=hitcounter{hit{i}}+1;
        epoch=epoch+1;    
        label = hit{i};
        labelRange(epoch) = label;
        stimRange(epoch) = i;
        DS = [];
        for channel=channelRange
            [eegimg, DOTS, zerolevel] = eegimage(channel,rsignal{i},imagescale,1, false,minimagesize);

            saveeegimage(subject,epoch,label,channel,eegimg);
            zerolevel = size(eegimg,1)/2;

%             if ((size(find(trainingRange==epoch),2)==0))
%                qKS=ceil(0.20*(Fs)*timescale):floor(0.20*(Fs)*timescale+(Fs)*timescale/4-1);
%             else
                qKS=sqKS(subject);
%             end

            [frames, desc] = PlaceDescriptorsByImage(eegimg, DOTS,siftscale, siftdescriptordensity,qKS,zerolevel,false,'cosine');

%figure;DisplayDescriptorGradient('baseimageonscale.txt');

%figure;[I,A] = DisplayDescriptorGradient('grads.txt');

%figure;
%DisplayDescriptorImageByImageAndGradient(frames,desc,eegimg,1,A,false);

%DisplayDescriptorImageByImage(frames,desc,eegimg,1,true);

            
%fdsfds            
            
            
            F(channel,label,epoch).stim = i;
            F(channel,label,epoch).hit = hit{i};
            
%             if ((size(find(trainingRange==epoch),2)==0))
%                 
%                 DKE = DEKZ(c);
%                 
%                 Z= pdist2(DKE.C(2).M(:,:)',desc','cosine');
%                 
%                 sumsrow = dot(Z(1:size(DKE.C(2).M,2),1:size(desc,2)),ones(size(DKE.C(2).M,2),size(desc,2)));
%         
%                 [mval, minx] = min(sumsrow);
%                 
%                 F(channel,label,epoch).descriptors = desc(:,minx);
%                 F(channel,label,epoch).frames = frames(:,minx);   
%             else
                 F(channel,label,epoch).descriptors = desc;
                 F(channel,label,epoch).frames = frames;   
%             end
            
        end
        
        EP = [EP; [epoch subject trial 1]];
    end
end

            