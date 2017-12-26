%colores
C(1,:)=[1 0 1];
C(2,:)=[1 0 0];
C(3,:)=[0 0.5 0];
C(4,:)=[0 0 1];
C(5,:)=[0.5 0.5 0.5];
C(6,:)=[0.5 0 0.5];
C(7,:)=[0 0.75 0.2];
C(8,:)=[0.65 0.30 0];


% tipos de l?neas
linea=':';

% markers
mark=cell(8,1);
mark{1}='o';
mark{2}='s';
mark{3}='^';
mark{4}='v';
mark{5}='>';
mark{6}='<';
mark{7}='p';
mark{8}='d';

linestyles={'-','--',':','-.',':','--','-','-.'};

% datos (para graficar algo...)
ncomp=2*(1:11);
K3=[88.19    54.17    95.14    67.36    59.72    62.50    75.00    93.06 
   86.11    53.47    95.14    72.92    59.72    57.64    72.92    95.14 
   88.89    52.08    96.53    68.75    55.56    66.67    72.22    93.75 
   89.58    52.08    96.53    69.44    52.78    68.06    72.22    95.14 
   88.89    51.39    96.53    68.06    52.08    63.89    70.14    95.83 
   90.28    54.86    94.44    70.83    52.78    62.50    72.92    96.53 
   90.97    52.78    95.14    70.14    52.08    62.50    70.83    95.83 
   90.97    57.64    93.75    73.61    50.69    61.11    69.44    95.14 
   88.89    57.64    93.75    74.31    50.69    63.89    67.36    95.14 
   88.89    56.94    93.06    70.83    50.69    59.72    62.50    95.14 
   90.97    56.25    92.36    69.44    52.78    59.72    63.19    95.14]; 

for subject=1:8
    [val, ord] = max(globalspellerrep(subject,:,10))
    y=globalspellerrep(subject,ord,:);
    y=reshape(y, [1 10])
    y=y*100;
    %Xi = 0:0.1:size(y,2);
    %Yi = pchip(1:size(y,2),y,Xi);
    plot(1:10,y,':','linestyle',linestyles{subject},'marker',mark{subject},...
        'color',C(subject,:),'MarkerSize',3,'linewidth',2);
    axis([1 10 0 100]);
    set(gca,'YTick',[0 30 70 90]);
    hold on
end
grid on
xlabel('Intensification Sequences');
ylabel('Percent Correct')
%title({'K=3';'CSP'},'color',C(4,:),'fontsize',14,'fontweight','normal',...
    %'fontname','Courier');
legend('1','2','3','4','5','6','7','8','location','best')
