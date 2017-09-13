function Speller = SpellMe(F,channelRange,trialRange,labelRange, trainingRange,testRange,SC)
%
% Returns the selected keystrokes based on binary classification selected
% predictions (on SC(channel).predicted) on a channel-by-channel basis.

SPELLERMATRIX = { { 'A','B','C','D','E','F'},
                { 'G','H','I','J','K','L'},
                { 'M','N','O','P','Q','R'},
                { 'S','T','U','V','W','X'},
                { 'Y','Z','1','2','3','4'},
                { '5','6','7','8','9','_'}};


%%
Speller = cell(size(channelRange,2),1);

for channel=channelRange
    predicted=SC(channel).predicted;
    AF = [];
    mind = 1;
    maxd = 6;
    for trial=trialRange
        Mx = zeros(1,2);
        
        % Show predicted value for this repetition.
        predicted(mind:mind+12-1);
        for i=1:12
            if (1<=i && i<=6 && predicted(mind+i-1)==2)
                Mx(1) = i;
            elseif (7 <=i && i<=12 && predicted(mind+i-1)==2)
                Mx(2) = i;
            end
        end       
        
        % @FIXME Try not to produce an error but it should fail here.
        if (Mx(1) == 0) Mx(1) = randi(6);end
        if (Mx(2) == 0) Mx(2) = randi(6)+6;end
        
        Speller{channel}{end+1} = SPELLERMATRIX{Mx(1)}{Mx(2)-6};
        
        mind=mind+12;
        maxd=maxd+12;        
    end
end

end