
subject=1;
epoch=2;
label=1;
channel=1;


%signal=globalaverages{subject}{trial}{1}.rmean;

fprintf('s.%d.e.%d.l.%d.c.%d.tif\n',subject,epoch,label,channel);
I1 = imread(sprintf('%ss.%d.e.%d.l.%d.c.%d.tif',getimagepath(),subject,epoch,label,channel));
%img1=imtool(I1);
%figure;
fprintf('Image Size: %d,%d \n',size(I1,1),size(I1,2));

patternimage = I1;

[patternframes, descriptors] = PlaceDescriptorsByImage(patternimage, patternDOTS,[st sv], siftdescriptordensity,qKS,zerolevel,true);

figure;DisplayDescriptorImageByImage(patternframes,descriptors,patternimage,1,false);

%descriptors = single(descriptors);

% Pick only one descriptor for following analysis.
descriptors = descriptors(:,1);

% Display Descriptor Values
reshape(descriptors, [8 16] )


%I = A(:,3)';
%I = reshape(I,size(patternimage));
%imshow(I)

figure;DisplayDescriptorGradient('baseimageonscale.txt');

figure;[I,A] = DisplayDescriptorGradient('grads.txt');

figure;
DisplayDescriptorImageByImageAndGradient(patternframes,descriptors,patternimage,1,A);
