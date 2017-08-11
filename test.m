for i=1:12
    channelRange = (1:size(routput{i},2));
    channelsize = size(channelRange,2);
        
    assert( size(routput{i},1)/Fs == rcounter{i}, 'Something wrong with PtP average. Sizes do not match.');
    
    routput{i}=reshape(routput{i},[Fs size(routput{i},1)/Fs channelsize]); 


    for d=1:rcounter{i}
        %rroutput{i}(:,d,:) = [zeros(10,1,channelsize);routput{i}(:,d,:);zeros(10,1,channelsize)];
        rroutput{i}(:,d,:) = zeros(50,1,channelsize);
    end

    for channel=channelRange
        for d=1:rcounter{i}-1
            [a,b] = alignsignals(routput{i}(:,d,channel),routput{i}(:,d+1,channel),5);
            rroutput{i}(1:size(a),d,channel)=a;
            
            rroutput{i}(1:size(b),d+1,channel)=b;
        end
    end


    for channel=channelRange
        wholesignal = mean(rroutput{i}(:,:,channel),2);
        rmean{i}(:,channel) = wholesignal(1:16);
    end

    routput{i}=[]; 
    rroutput{i}=[];
    rcounter{i}=0;
    
    if (hit{i} == 2)
        h = [h i];
    end
    
end