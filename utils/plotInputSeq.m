%%PLot input sequences
%% PLOTTING

%Study 1: UCMS ABA_R
% u = readmatrix("C:\Users\c3200098\Desktop\projects\IDMIM\utils\inputSequences\2023_UCMS\NJB_HGF_ABA2_R.txt");
% probStr = [0.8*ones(1,60),0.5*ones(1,10),0.65*ones(1,5),0.3*ones(1,8),0.45*ones(1,12),...
%         0.75*ones(1,6),0.55*ones(1,11),0.25*ones(1,8),0.8*ones(1,60)];

%Study 2 & 3: TrainingTask_RL
% u = readmatrix("C:\Users\c3200098\Desktop\projects\IDMIM\utils\inputSequences\2024_HGFPilot\NJB_HGF_TrainingTask_RL.txt");
% probStr = [0.8*ones(1,140),0.2*ones(1,140)]; TrainingTask_RL

%TestTask A
u = readmatrix("C:\Users\c3200098\Desktop\projects\IDMIM\utils\inputSequences\2024_HGFPilot\NJB_HGF_TestTaskA.txt");
probStr = [0.8*ones(1,40),0.3*ones(1,20),0.7*ones(1,20),0.2*ones(1,40),0.7*ones(1,20),...
         0.3*ones(1,20),0.8*ones(1,40),0.3*ones(1,20),0.7*ones(1,20),0.2*ones(1,40)];
            
createfigure(u,probStr)


figure;
fig = plot(u, '.', 'MarkerSize', 20); ylim([-0.1, 1.1]);
hold on;
stairs(probStr, '-.', 'Color', 'r', 'LineWidth', 2);
legend({'RewardingLeverSide', 'Prob(Reward)'});
title('TrainingTask', 'FontWeight', 'bold', 'FontSize', 12);
figdir = fullfile([savePath,filesep, currTask, '_TrajPlot']);
save([figdir,'.fig'])
print([figdir,'.png'], '-dpng')