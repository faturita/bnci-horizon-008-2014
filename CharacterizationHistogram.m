clear amplitudehistogram
clear locationhistogram


for i=1:2 amplitudehistogram{i}=[]; end
for i=1:2 locationhistogram{i}=[]; end

channel=2;

for subject=1:1
    for trial=1:35
        for flash=1:120
            [amplitude,location] = findpeaks(EEG(subject,trial,flash).EEG(:,channel));
            amplitudehistogram{EEG(subject,trial,flash).label} = [amplitudehistogram{EEG(subject,trial,flash).label}; amplitude];
            locationhistogram{EEG(subject,trial,flash).label} = [locationhistogram{EEG(subject,trial,flash).label}; location];
        end
    end
end
%%
figure
[nb,xb]=hist(amplitudehistogram{1});
bh=bar(xb,nb);
set(bh,'facecolor',[1 1 0]);
figure;
[nb,xb]=hist(amplitudehistogram{2});
bh=bar(xb,nb);
set(bh,'facecolor',[1 0 1]);

figure;
[nb,xb]=hist(locationhistogram{1});
bh=bar(xb,nb);
set(bh,'facecolor',[1 1 0]);
figure;
[nb,xb]=hist(locationhistogram{2});
bh=bar(xb,nb);
set(bh,'facecolor',[1 0 1]);
