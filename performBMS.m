function performBMS

%% INITIALIZE Variables for running this function

try
    load('optionsFile.mat');
catch
    optionsFile = runOptions; % specifications for this analysis
end

disp('************************************** PARAMETER RECOVERY **************************************');
disp('*');
disp('*');

res.modelSelection = load(fullfile([char(optionsFile.paths.resultsDir),filesep,'mouse',num2str(currMouse),'_',optionsFile.fileName.rawFitFile{m_in},'.mat']));
for n = 1:simP.nS_main
    for iTraj = 1:simP.nTraj
        r = load([paths.mainRes{n,iTraj},'/',simP.singleMainDataFitNamePart,options.model.space{1},'.mat']);
        res.main.(eHGFCont3Field).est(n,iTraj)   = r.main.est;
        res.main.(eHGFCont3Field).LME(n,iTraj)   = r.main.est.optim.LME;
        res.main.(eHGFCont3Field).prc_param(n,iTraj).ptrans = r.main.est.p_prc.ptrans(main.ModSpace(1).prc_idx);
        res.main.(eHGFCont3Field).obs_param(n,iTraj).ptrans = r.main.est.p_obs.ptrans(main.ModSpace(1).obs_idx);

        r = load([paths.mainRes{n,iTraj},'/',simP.singleMainDataFitNamePart,options.model.space{2},'.mat']);
        res.main.(eHGFCont2Field).est(n,iTraj) = r.main.est;
        res.main.(eHGFCont2Field).LME(n,iTraj) = r.main.est.optim.LME;
        res.main.(eHGFCont2Field).prc_param(n,iTraj).ptrans = r.main.est.p_prc.ptrans(main.ModSpace(2).prc_idx);
        res.main.(eHGFCont2Field).obs_param(n,iTraj).ptrans = r.main.est.p_obs.ptrans(main.ModSpace(2).obs_idx);

        r = load([paths.mainRes{n,iTraj},'/',simP.singleMainDataFitNamePart,options.model.space{3},'.mat']);
        res.main.(eHGFJget3Field).est(n,iTraj) = r.main.est;
        res.main.(eHGFJget3Field).LME(n,iTraj) = r.main.est.optim.LME;
        res.main.(eHGFJget3Field).prc_param(n,iTraj).ptrans = r.main.est.p_prc.ptrans(main.ModSpace(3).prc_idx);
        res.main.(eHGFJget3Field).obs_param(n,iTraj).ptrans = r.main.est.p_obs.ptrans(main.ModSpace(3).obs_idx);

        r = load([paths.mainRes{n,iTraj},'/',simP.singleMainDataFitNamePart,options.model.space{4},'.mat']);
        res.main.(eHGFJget2Field).est(n,iTraj) = r.main.est;
        res.main.(eHGFJget2Field).LME(n,iTraj) = r.main.est.optim.LME;
        res.main.(eHGFJget2Field).prc_param(n,iTraj).ptrans = r.main.est.p_prc.ptrans(main.ModSpace(4).prc_idx);
        res.main.(eHGFJget2Field).obs_param(n,iTraj).ptrans = r.main.est.p_obs.ptrans(main.ModSpace(4).obs_idx);

        disp(['Reading data from participant: ', num2str(n), ' | trajectory ', num2str(iTraj)]);
    end
end


%% PERFORM rfx BMS
res.main.LME(:,1) = mean(res.main.(eHGFCont3Field).LME,2);
res.main.LME(:,2) = mean(res.main.(eHGFCont2Field).LME,2);
res.main.LME(:,3) = mean(res.main.(eHGFJget3Field).LME,2);
res.main.LME(:,4) = mean(res.main.(eHGFJget2Field).LME,2);

res.main.F = res.main.LME;
[res.main.alpha,res.main.exp_r,res.main.xp,res.main.pxp,res.main.bor] = spm_BMS(res.main.F);

% Create figure
pos0 = get(0,'screenSize');
pos = [1,pos0(4)/2,pos0(3)/1.2,pos0(4)/1.2];
figure('position',pos,...
    'color',[1 1 1],...
    'name','BMS all');

% plot BMS results
hold on; subplot(1,3,1); bar(1, res.main.exp_r(1),'FaceColor',[0,176/255,240/255],'EdgeColor',[0,176/255,240/255]);
hold on; subplot(1,3,1); bar(2, res.main.exp_r(2),'FaceColor',[112/255,48/255,160/255],'EdgeColor',[112/255,48/255,160/255]);
hold on; subplot(1,3,1); bar(3, res.main.exp_r(3),'FaceColor',[255/255,192/255,0/255],'EdgeColor',[255/255,192/255,0/255]);
hold on; subplot(1,3,1); bar(4, res.main.exp_r(4),'FaceColor',[0/255,176/255,80/255],'EdgeColor',[0/255,176/255,80/255]);
ylabel ('posterior probability', 'FontSize', 15); ylim([0 1]);
set(gca, 'XTick', []);
set(gca,'box','off'); get(gca, 'YTick'); set(gca, 'FontSize', 13);
ax1       = subplot(1,3,1);
ax1.YTick = [0 0.25 0.5 0.75 1.0];
h_leg     = legend(main.ModSpace(1).name, main.ModSpace(2).name, main.ModSpace(3).name, main.ModSpace(4).name, 'Location', 'east');
set(h_leg,'box','off','FontSize', 13);

hold on; subplot(1,3,2); bar(1, res.main.xp(1),'FaceColor',[0,176/255,240/255],'EdgeColor',[0,176/255,240/255]);
hold on; subplot(1,3,2); bar(2, res.main.xp(2),'FaceColor',[112/255,48/255,160/255],'EdgeColor',[112/255,48/255,160/255]);
hold on; subplot(1,3,2); bar(3, res.main.xp(3),'FaceColor',[255/255,192/255,0/255],'EdgeColor',[255/255,192/255,0/255]);
hold on; subplot(1,3,2); bar(4, res.main.xp(4),'FaceColor',[0/255,176/255,80/255],'EdgeColor',[0/255,176/255,80/255]);
ylabel('exceedance probability', 'FontSize', 15);
set(gca, 'XTick', []);
set(gca,'box','off'); get(gca, 'YTick'); set(gca, 'FontSize', 13);
ax2 = subplot(1,3,2);
ax2.YTick = [0 0.25 0.5 0.75 1.0];
h_leg2 = legend(main.ModSpace(1).name, main.ModSpace(2).name, main.ModSpace(3).name, main.ModSpace(4).name, 'Location', 'east');
set(h_leg2,'box','off','FontSize', 13);

hold on; subplot(1,3,3); bar(1, res.main.pxp(1),'FaceColor',[0,176/255,240/255],'EdgeColor',[0,176/255,240/255]);
hold on; subplot(1,3,3); bar(2, res.main.pxp(2),'FaceColor',[112/255,48/255,160/255],'EdgeColor',[112/255,48/255,160/255]);
hold on; subplot(1,3,3); bar(3, res.main.pxp(3),'FaceColor',[255/255,192/255,0/255],'EdgeColor',[255/255,192/255,0/255]);
hold on; subplot(1,3,3); bar(4, res.main.pxp(4),'FaceColor',[0/255,176/255,80/255],'EdgeColor',[0/255,176/255,80/255]);
ylabel('protected exceedance probability', 'FontSize', 15);
set(gca, 'XTick', []);
set(gca,'box','off'); get(gca, 'YTick'); set(gca, 'FontSize', 13);
ax2       = subplot(1,3,3);
ax2.YTick = [0 0.25 0.5 0.75 1.0];
h_leg2    = legend(main.ModSpace(1).name, main.ModSpace(2).name, main.ModSpace(3).name, main.ModSpace(4).name, 'Location', 'east');
set(h_leg2,'box','off','FontSize', 13);

sgtitle('Bayesian Model Selection', 'FontSize', 18);

figdir = fullfile([simP.saveDirGroupMainPlots,'/',simP.BMSplotName]);
print(figdir, '-dpng');
close all;
end