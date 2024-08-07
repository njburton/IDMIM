function [probStr,savepath] = gen_trajectory
%% SOCIAL EMOTIONAL PROCESSING under AFFECTIVE BLUNTING Task Trajectory 
%
% script to generate different possible task trajectories that are suitable
% for fitting a binary eHGF to (enhanced Hierarchical Gaussian Filter). The
% choice of the input structure is both informed by informed reasoning
% about how individuals may learn about the stimuli used here together with
% how well the trajectory can be estimated by the HGF during model
% inversion

date     = char(datetime('today'));
savepath = [pwd,'/simulations_',date];
mkdir(savepath)

% setup phases

pPhase1  = 0.8; % probability of "1" in curr phase
lPhase1  = 40;   % n trials of curr phase
pPhase2  = 0.2; 
lPhase2  = 20;
pPhase3  = 0.8; 
lPhase3  = 20;
pPhase4  = 0.2; 
lPhase4  = 40;
pPhase5  = 0.60; 
lPhase5  = 40;
pPhase6  = 0; 
lPhase6  = 0;
pPhase7  = 0; 
lPhase7  = 0;
pPhase8  = 0; 
lPhase8  = 0;
pPhase9  = 0; 
lPhase9  = 0;
pPhase10 = 0; 
lPhase10 = 0;

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
iIncIdx = randperm(lPhase6,floor((1-pPhase7)*lPhase7));
phase7(1,iIncIdx) = 0;

phase8  = ones(1,lPhase8);
iIncIdx = randperm(lPhase9,floor((1-pPhase8)*lPhase8));
phase8(1,iIncIdx) = 0;

phase9  = ones(1,lPhase9);
iIncIdx = randperm(lPhase9,floor((1-pPhase9)*lPhase9));
phase9(1,iIncIdx) = 0;

phase10  = ones(1,lPhase10);
iIncIdx = randperm(lPhase10,floor((1-pPhase6)*lPhase10));
phase10(1,iIncIdx) = 0;

% create input trajectory
u = [phase1,phase2,phase3,phase4,phase5,phase6,phase7,phase8,phase9,phase10]';

% underlying probability structure
probStr = [pPhase1*ones(1,lPhase1),pPhase2*ones(1,lPhase2),pPhase3*ones(1,lPhase3),pPhase4*ones(1,lPhase4),pPhase5*ones(1,lPhase5),...
    pPhase6*ones(1,lPhase6),pPhase7*ones(1,lPhase7),pPhase8*ones(1,lPhase8),pPhase9*ones(1,lPhase9),pPhase10*ones(1,lPhase10)];


%% PLOTTING
fig = plot(u,'o','Color','b');
ylim([-0.1,1.1]);
hold on
plot(probStr);

save([savepath,'/inputs.mat'],'u');
save([savepath,'/probStr.mat'],'probStr');
save([savepath,'/traj.fig'],'fig');

end
