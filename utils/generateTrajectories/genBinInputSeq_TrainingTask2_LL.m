
% % TrainingTask2_LL - Create binary input sequence for trainingTask
pPhase1  = 0.2; %A1  probability of "1" in curr phase
lPhase1  = 140;  %A1 n trials of curr phase
pPhase2  = 0.8; %A2
lPhase2  = 140; %A2

% TrainingTask_ - Outcomes
phase1  = ones(1,lPhase1);
iIncIdx = randperm(lPhase1,floor((1-pPhase1)*lPhase1)); %floor rounds the number to prevent errors 
phase1(1,iIncIdx) = 0;

phase2  = ones(1,lPhase2);
iIncIdx = randperm(lPhase2,floor((1-pPhase2)*lPhase2));
phase2(1,iIncIdx) = 0;

% TrainingTask - create input trajectory
u = [phase1,phase2];
% TrainingTask - underlying probability structure
probStr = [pPhase1*ones(1,lPhase1),pPhase2*ones(1,lPhase2)];

%Create second row for left lever sequence
k = zeros(1,length(u))
for i = 1:length(k)
    if u(1,i) == 0
        k(1,i) = 1;
    end
end

%% PLOTTING
figure;
fig = plot(u, '.', 'MarkerSize', 20); ylim([-0.1, 1.1]);
hold on;
stairs(probStr, '-.', 'Color', 'r', 'LineWidth', 2);
legend({'RewardingLeverSide', 'Prob(Reward)'});
title('binInputSeq_TrainingTask2_L', 'FontWeight', 'bold', 'FontSize', 12);
figdir = fullfile('binInputSeq_TrainingTask2_LL_TrajPlot');
save([figdir,'.fig'])
print([figdir,'.png'], '-dpng')

writematrix(u, [pwd,filesep, 'binInputSeq_TrainingTask2_LLFirst_RightLeverList.txt'],"Delimiter",',')
writematrix(k, [pwd,filesep,'binInputSeq_TrainingTask2_LLFirst_LeftLeverList.txt'],"Delimiter",',')
