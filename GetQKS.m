function qKS = GetQKS(rsignal,channel,Fs,timescale,qKS)

signal=rsignal(:,channel);
[amplitudes,locations] = findpeaks(signal);

if (size(locations,1)~=0)

    [maxamplitude,maxamplocation] = max(amplitudes);
    amplitude=maxamplitude;
    location=locations(maxamplocation);

    qKS = floor(location * timescale);

end

end