function CheckDistances(F,DE,channel,testRange,labelRange)

[DE] = MahalanobisPrunning(DE)

K = size(DE.C(2).M,2);

for i=1:2:K
   ni=floor(i/2)+1;
   %Z= pdist2(DE.C(1).M(:,(ni-1)*10+1:(ni-1)*10+10)',DE.C(2).M(:,i:i+1)','euclidean');
   Z= pdist2(DE.C(1).M(:,i:i+1)',DE.C(2).M(:,i:i+1)','euclidean');
   Di = sum(Z) 
    
end


end



function [DE] = MahalanobisPrunning(DE)
X = DE.C(2).M';
Y = DE.C(1).M';

size(X)
size(Y)

n=size(X,1);
m=size(Y,1);
d=zeros(1,m);
% media 
muX=mean(X,1);
% inversa covarianza
CX_inv=inv(cov(X));
for i=1:m
    % dist. Mahalanobis
    d(i)=(Y(i,:)-muX)*CX_inv*(Y(i,:)-muX)';
end
[~,ind]=sort(d,'descend');
% descriptores elegidos
ind_ch=ind(1:n);
Y_ch=Y(ind_ch,:);

ind_ch

DE.C(1).M=DE.C(1).M(:,ind_ch);
DE.C(1).IX=DE.C(1).IX(ind_ch,:);

end
