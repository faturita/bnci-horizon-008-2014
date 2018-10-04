
subject=1;
epoch=2;
label=1;
channel=1;

st=3;
sv=3;

%signal=globalaverages{subject}{trial}{1}.rmean;

trial=2;
classes=1; % If there are more than twelve classes per trial.
i=1; % The first row.
rsignal{i}=routput{subject}{trial}{classes}{i};

%fprintf('s.%d.e.%d.l.%d.c.%d.tif\n',subject,epoch,label,channel);
%I1 = imread(sprintf('%ss.%d.e.%d.l.%d.c.%d.tif',getimagepath(),subject,epoch,label,channel));
%img1=imtool(I1);
%figure;
%fprintf('Image Size: %d,%d \n',size(I1,1),size(I1,2));

[eegimg, DOTS, zerolevel] = eegimage(channel,rsignal{i},imagescale,1, false,minimagesize,true);
patternimage = eegimg;
patternDOTS = DOTS;

[patternframes, descriptors] = PlaceDescriptorsByImage(patternimage, patternDOTS,[st sv], siftdescriptordensity,qKS,zerolevel,true,'euclidean');

figure;DisplayDescriptorImageByImage(patternframes,descriptors,patternimage,1,true);
CropFigure();

%descriptors = single(descriptors);

% Pick only one descriptor for following analysis.
descriptors = descriptors(:,1);

% Display Descriptor Values
reshape(descriptors, [8 16] )


%I = A(:,3)';
%I = reshape(I,size(patternimage));
%imshow(I)

figure;DisplayDescriptorGradient('baseimageonscale.txt');
CropFigure();
figure;[I,A] = DisplayDescriptorGradient('grads.txt');
CropFigure(20);
figure;
DisplayDescriptorImageByImageAndGradient(patternframes,descriptors,patternimage,1,A,true);
CropFigure(10);
print('sample','-depsc');

