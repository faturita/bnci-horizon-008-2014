function totals = DisplayTotals(globalaccij,globalsigmaaccij1,channels)

informedinpaper =   [  0.845  
    0.863    
    0.872    
    0.859    
    0.862    
    0.886    
    0.886    
    0.923 ];

totals = [];
fid = fopen('output.txt','a');
{'Subject','mokuhyou','Cz','Avg','Best Channel','Value','Stdv'}
for subject=1:8
    [ChAcc,ChNum] = max(globalaccij(subject,:));
    Stdv = globalsigmaaccij1(subject,ChNum);
    
    CMean = mean(globalaccij(subject,:));
    
    % Classification rate @?Cz (channel 2)
    Cz = globalaccij(subject,2);
    
    totals = [totals ;subject informedinpaper(subject) [ Cz CMean ChNum ChAcc  Stdv]];
    
    fprintf(fid,'%d     & %6.2f & %6.2f', [ subject informedinpaper(subject) Cz]);
    fprintf(fid,'& %s', channels{ChNum});
    fprintf(fid,'& %6.2f $\\pm$ %4.4f \\\\\n', [ChAcc Stdv]);
end
totals
fclose(fid);

end
