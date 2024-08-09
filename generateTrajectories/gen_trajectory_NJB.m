function [probStr,savepath] = gen_trajectory
%% SOCIAL EMOTIONAL PROCESSING under AFFECTIVE BLUNTING Task Trajectory 
%
% script to generate different possible task trajectories that are suitable
% for fitting a binary eHGF to (enhanced Hierarchical Gaussian Filter). The
% choice of the input structure is both informed by informed reasoning
% about how individuals may learn about the stimuli used here together with
% how well the trajectory can be estimated by the HGF during model
% inversion

%% Modified from Katharina Wellstein  8/8/2024
date     = char(datetime('today'));
savepath = ['C:\Users\c3200098\Desktop\projects\IDMIM\generateTrajectories',date];
%savepath = [pwd,'/simulations_',date];
mkdir(savepath)

% setup phases

pPhase1  = 0.8; %A1  probability of "1" in curr phase
lPhase1  = 50;  %A1 n trials of curr phase
pPhase2  = 0.3; %B1
lPhase2  = 15; %B1
pPhase3  = 0.55; %B2
lPhase3  = 20;%B2
pPhase4  = 0.45; %B3
lPhase4  = 15; %B3
pPhase5  = 0.20; %A2
lPhase5  = 50; %A2
pPhase6  = 0.6; %B4
lPhase6  = 15; %B4
pPhase7  = 0.3; %B5
lPhase7  = 20; %B5
pPhase8  = 0.5; %B6
lPhase8  = 16; %B6
pPhase9  = 0.8; %A3
lPhase9  = 50; %A3
pPhase10 = 0.4; %B7 
lPhase10 = 15; %B7
pPhase11  = 0.60; %B8
lPhase11  = 16; %B8
pPhase12  = 0.3; %B9
lPhase12  = 15; %B9
pPhase13  = .20; %A4
lPhase13  = 50; %A4
pPhase14  = 0.55; %B10
lPhase14  = 15; %B10
pPhase15  = 0.3; %B11
lPhase15  = 20; %B11
pPhase16 = 0.5; %B12
lPhase16 = 15; %B12
pPhase17  = 0.8; %A5
lPhase17  = 50; %A5

% outcomes
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

phase11  = ones(1,lPhase4);
iIncIdx = randperm(lPhase11,floor((1-pPhase11)*lPhase11));
phase11(1,iIncIdx) = 0;

phase12  = ones(1,lPhase5);
iIncIdx = randperm(lPhase12,floor((1-pPhase12)*lPhase12));
phase12(1,iIncIdx) = 0;

phase13  = ones(1,lPhase6);
iIncIdx = randperm(lPhase13,floor((1-pPhase13)*lPhase13));
phase13(1,iIncIdx) = 0;

phase14  = ones(1,lPhase14);
iIncIdx = randperm(lPhase14,floor((1-pPhase14)*lPhase14));
phase14(1,iIncIdx) = 0;

phase15  = ones(1,lPhase15);
iIncIdx = randperm(lPhase15,floor((1-pPhase15)*lPhase15));
phase15(1,iIncIdx) = 0;

phase16  = ones(1,lPhase16);
iIncIdx = randperm(lPhase16,floor((1-pPhase16)*lPhase16));
phase16(1,iIncIdx) = 0;

phase17  = ones(1,lPhase17);
iIncIdx = randperm(lPhase17,floor((1-pPhase17)*lPhase17));
phase17(1,iIncIdx) = 0;
% create input trajectory
u = [phase1,phase2,phase3,phase4,phase5,phase6,phase7,phase8,phase9,phase10,phase11,phase12,phase13,phase14,phase15,phase16,phase17];

% underlying probability structure
probStr = [pPhase1*ones(1,lPhase1),pPhase2*ones(1,lPhase2),pPhase3*ones(1,lPhase3),pPhase4*ones(1,lPhase4),pPhase5*ones(1,lPhase5),...
    pPhase6*ones(1,lPhase6),pPhase7*ones(1,lPhase7),pPhase8*ones(1,lPhase8),pPhase9*ones(1,lPhase9),pPhase10*ones(1,lPhase10),...
    pPhase11*ones(1,lPhase11),pPhase12*ones(1,lPhase12),pPhase13*ones(1,lPhase13),pPhase14*ones(1,lPhase14),pPhase15*ones(1,lPhase15),...
    pPhase16*ones(1,lPhase16),pPhase17*ones(1,lPhase17)];


%% PLOTTING
figure;
fig = plot(u, '.', 'MarkerSize', 20); ylim([-0.1, 1.1]);
hold on;
stairs(probStr, '-.', 'Color', 'r', 'LineWidth', 2);
legend({'RewardingLeverSide', 'Prob(Reward)'});
title('ABABA sequence', 'FontWeight', 'bold', 'FontSize', 12);
 
tempTable = array2table([u]);
writetable(tempTable, [pwd,filesep, 'genTraj_NJB_BinarySeq.csv'])

% save([savepath,'/inputs.mat'],'u');
% save([savepath,'/probStr.mat'],'probStr');
% save([savepath,'/traj.fig'],'fig');

end
