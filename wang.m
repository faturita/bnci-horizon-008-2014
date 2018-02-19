function wang(angle)

v=[0, 45, 90, 135, 180, 225, 270, 315];

for i=v
    wang2(angle,i)
end

end

function a = wang2(angle,v)

%{0, 45, 90, 135, 180, 225, 270, 315}

%v=90;
val = angle*2*pi/360-v*2*pi/360;

s=-10:10;
ssum = sum(w((8/(2*pi))*val + s*8));
a = ssum;

end


function value = w(z)

value = max(0,1-abs(z));

end
