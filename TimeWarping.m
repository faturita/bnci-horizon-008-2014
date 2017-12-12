function rput = TimeWarping(rput, dly, channelRange)
for channel=channelRange
    output=reshape(rput(:,:,channel), [size(rput,1) 10]);

    xoutput=[zeros(10,10); output; zeros(10,10)];
    xoutput = output;

    for i=1:10
        xoutput(:,i) = delayseq(xoutput(:,i), dly(i));
    end

    %xoutput = xoutput(11:11+size(rput,1)-1,:);

    rput(:,:,channel) = reshape(xoutput, [size(rput,1) 1 10]);
end

end
