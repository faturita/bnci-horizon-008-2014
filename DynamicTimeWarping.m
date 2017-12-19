function rput = DynamicTimeWarping(rput, channelRange)

dly=zeros(10,1);

kpos=1:10;
kpos=kpos(randperm(size(kpos,2)));

for i=2:10
    output1 = reshape( rput(:,kpos(i-1),:), [size(rput,1) 8]);
    output2 = reshape( rput(:,kpos(i),:), [size(rput,1) 8]);

    d=[];
    dlayrange=-8:8;
    for dlay=dlayrange
        %d(end+1)=dtw(output1(9:9+16-1,:) , output2(9+dlay:9+dlay+16-1,:), 8);
        a=finddelay(output1(9:9+16-1,:) , output2(9+dlay:9+dlay+16-1,:), 8);
        d(end+1)=mean(a);
        %[d(end+1),~]=cdtw(output1(9:9+16-1,:),output2(9+dlay:9+dlay+16-1,:),false);
    end

    [a,delay] = min(d);

    dly(kpos(i)) = dlayrange(delay);
end
%dly


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