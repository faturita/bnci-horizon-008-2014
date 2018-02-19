for globalamplitude=1:5
    run('OfflineProcessP300.m');    
end
fdsfds

for globalrepetitions=1:10
    run('OfflineProcessP300.m');
end




%%
figure;
hold on
linestyles={'-','--',':','-.','-+','-o','-*','-.'};
for subject=1:8
    [val, ord] = max(globalspellerrep(subject,:,10))
    y=globalspellerrep(subject,ord,:);
    y=reshape(y, [1 10])
    y=y*100;
    Xi = 0:0.1:size(y,2);
    Yi = pchip(1:size(y,2),y,Xi);
    plot(Xi,Yi,linestyles{subject},'LineWidth',2);
    axis([1 10 0 100]);
    set(gca,'YTick',[0 30 70 90]);
    set(gcf,'renderer','opengl');
    set(0,'DefaultAxesFontSize',18);
    hx=xlabel('Intensification Sequences');
    hy=ylabel('Percent Correct');
    set(hx,'fontSize',20);
    set(hy,'fontSize',20);
end
legend('1','2','3','4','5','6','7','8','9','10');
hold off