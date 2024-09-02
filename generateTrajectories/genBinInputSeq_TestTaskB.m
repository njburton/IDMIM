%% TestTask_2 - setup phases 7_BABA Aphases are 40trials long
pPhase1  = 0.3; %B1
lPhase1  = 20; %B1
pPhase2  = 0.7; %B2
lPhase2  = 20;%B2
pPhase3  = 0.2; %A2
lPhase3  = 40; %A2
pPhase4  = 0.7; %B3
lPhase4  = 20; %B3
pPhase5  = 0.3; %B4
lPhase5  = 20; %B4
pPhase6  = 0.8; %A3
lPhase6  = 40; %A3
pPhase7  = 0.3; %B5
lPhase7  = 20; %B5
pPhase8  = 0.7; %B6
lPhase8  = 20; %B6
pPhase9 = 0.2; %A4 
lPhase9 = 40; %A4
pPhase10  = 0.7; %B7
lPhase10  = 20; %B7
pPhase11  = 0.3; %B8
lPhase11  = 20; %B8


% TestTask_2 outcomes 
phase1  = ones(1,lPhase1);
iIncIdx = randperm(37,floor((1-pPhase1)*lPhase1))+3; % ! first 3 trials need to be "1" trials
phase1(1,iIncIdx) = 0;

phase2  = ones(1,lPhase2);
iIncIdx = randperm(lPhase2,floor((1-pPhase2)*lPhase2));
phase2(1,iIncIdx) = 0;

phase3  = ones(1,lPhase3);
iIncIdx = randperm(lPhase3,floor((1-pPhase3)*lPhase3));
phase3(1,iIncIdx) = 0;

phase4  = ones(1,lPhase4);
iIncIdx = randperm(lPhase4,floor((1-pPhase4)*lPhase4));
phase4(1,iIncIdx) = 0;

phase5  = ones(1,lPhase5);
iIncIdx = randperm(lPhase5,floor((1-pPhase5)*lPhase5));
phase5(1,iIncIdx) = 0;

phase6  = ones(1,lPhase6);
iIncIdx = randperm(lPhase6,floor((1-pPhase6)*lPhase6));
phase6(1,iIncIdx) = 0;

phase7  = ones(1,lPhase7);
iIncIdx = randperm(lPhase7,floor((1-pPhase7)*lPhase7));
phase7(1,iIncIdx) = 0;

phase8  = ones(1,lPhase8);
iIncIdx = randperm(lPhase8,floor((1-pPhase8)*lPhase8));
phase8(1,iIncIdx) = 0;

phase9  = ones(1,lPhase9);
iIncIdx = randperm(lPhase9,floor((1-pPhase9)*lPhase9));
phase9(1,iIncIdx) = 0;

phase10  = ones(1,lPhase10);
iIncIdx = randperm(lPhase10,floor((1-pPhase10)*lPhase10));
phase10(1,iIncIdx) = 0;

phase11  = ones(1,lPhase11);
iIncIdx = randperm(lPhase11,floor((1-pPhase11)*lPhase11));
phase11(1,iIncIdx) = 0;

% TestTask_2 - create input trajectory
u = [phase1,phase2,phase3,phase4,phase5,phase6,phase7,phase8,phase9,phase10,phase11];
%TeskTask_2 -  underlying probability structure
probStr = [pPhase1*ones(1,lPhase1),pPhase2*ones(1,lPhase2),pPhase3*ones(1,lPhase3),pPhase4*ones(1,lPhase4),pPhase5*ones(1,lPhase5),...
     pPhase6*ones(1,lPhase6),pPhase7*ones(1,lPhase7),pPhase8*ones(1,lPhase8),pPhase9*ones(1,lPhase9),pPhase10*ones(1,lPhase10),...
     pPhase11*ones(1,lPhase11)];


%% PLOTTING
figure;
fig = plot(u, '.', 'MarkerSize', 20); ylim([-0.1, 1.1]);
hold on;
stairs(probStr, '-.', 'Color', 'r', 'LineWidth', 2);
legend({'RewardingLeverSide', 'Prob(Reward)'});
title('binInputSeq_TestTaskB', 'FontWeight', 'bold', 'FontSize', 12);
figdir = fullfile("binInputSeq_TestTaskB_TrajPlot");
save([figdir,'.fig'])
print([figdir,'.png'], '-dpng')
writematrix(u, [pwd,filesep, 'binInputSeq_TestTaskB.txt'],"Delimiter",',')
