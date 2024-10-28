function performBMS

%% INITIALIZE Variables for running this function

optionsFile = load("optionsFile.mat"); % specifications for this analysis

disp('************************************** BAYESIAN MODEL SELECTION **************************************');
disp('*');
disp('*');

load([optionsFile.paths.resultsDir,filesep,'2023_UCMS2',filesep,'modelInv.mat']);
groupCodes = codeGroups;
groups = [find(groupCodes==1) find(groupCodes==0)]; %0 = controls,1 = treatment

addpath(genpath([pwd,filesep,'spm12']));

for modeli = length(optionsFile.model.space)
    for mousei = 1:optionsFile.cohort.nSize
        res.LME(mousei,modeli)   = allMice(mousei,modeli).est.optim.LME;
        res.prc_param(mousei,modeli).ptrans = allMice(mousei,modeli).est.p_prc.ptrans(optionsFile.modelSpace(modeli).prc_idx);
        res.obs_param(mousei,modeli).ptrans = allMice(mousei,modeli).est.p_obs.ptrans(optionsFile.modelSpace(modeli).obs_idx);
    end
end

%% PERFORM rfx BMS for all Mice
[res.BMS.alpha,res.BMS.exp_r,res.BMS.xp,res.BMS.pxp,res.BMS.bor] = spm_BMS(res.LME);

% Create figure
pos0 = get(0,'screenSize');
pos = [1,pos0(4)/2,pos0(3)/1.2,pos0(4)/1.2];
figure('position',pos,...
    'color',[1 1 1],...
    'name','BMS all');

% plot BMS results
hold on; subplot(1,2,1); bar(1, res.BMS.exp_r(1),'FaceColor',[0,176/255,240/255],'EdgeColor',[0,176/255,240/255]);
hold on; subplot(1,2,1); bar(2, res.BMS.exp_r(2),'FaceColor',[112/255,48/255,160/255],'EdgeColor',[112/255,48/255,160/255]);
ylabel ('posterior probability', 'FontSize', 15); ylim([0 1]);
set(gca, 'XTick', []);
set(gca,'box','off'); get(gca, 'YTick'); set(gca, 'FontSize', 13);
ax1       = subplot(1,2,1);
ax1.YTick = [0 0.25 0.5 0.75 1.0];
h_leg     = legend(optionsFile.model.space{1}, optionsFile.model.space{2}, 'Location', 'east');
set(h_leg,'box','off','FontSize', 13);

hold on; subplot(1,2,2); bar(1, res.BMS.xp(1),'FaceColor',[0,176/255,240/255],'EdgeColor',[0,176/255,240/255]);
hold on; subplot(1,2,2); bar(2, res.BMS.xp(2),'FaceColor',[112/255,48/255,160/255],'EdgeColor',[112/255,48/255,160/255]);
ylabel('exceedance probability', 'FontSize', 15);
set(gca, 'XTick', []);
set(gca,'box','off'); get(gca, 'YTick'); set(gca, 'FontSize', 13);
ax2 = subplot(1,2,2);
ax2.YTick = [0 0.25 0.5 0.75 1.0];
h_leg2 = legend(optionsFile.model.space{1}, optionsFile.model.space{2}, 'Location', 'east');
set(h_leg2,'box','off','FontSize', 13);

hold on; subplot(1,2,2); bar(1, res.BMS.pxp(1),'FaceColor',[0,176/255,240/255],'EdgeColor',[0,176/255,240/255]);
hold on; subplot(1,2,2); bar(2, res.BMS.pxp(2),'FaceColor',[112/255,48/255,160/255],'EdgeColor',[112/255,48/255,160/255]);
ylabel('protected exceedance probability', 'FontSize', 15);
set(gca, 'XTick', []);
set(gca,'box','off'); get(gca, 'YTick'); set(gca, 'FontSize', 13);
ax2       = subplot(1,2,2);
ax2.YTick = [0 0.25 0.5 0.75 1.0];
h_leg2    = legend(optionsFile.model.space{1}, optionsFile.model.space{2}, 'Location', 'east');
set(h_leg2,'box','off','FontSize', 13);

sgtitle('Bayesian Model Selection', 'FontSize', 18);
set(gcf, 'color', 'none');   
set(gca, 'color', 'none');

figdir = fullfile([char(optionsFile.paths.plotsDir),filesep,'BMS']);
print(figdir, '-dpng');
close all;

%% PERFORM rfx BMS for different groups

for i = 1:length(groups)
    iGroup = groups(:,i);
    [res.BMS(i).alpha,res.BMS(i).exp_r,res.BMS(i).xp,res.BMS(i).pxp,res.BMS(i).bor] = spm_BMS(res.LME(iGroup,:));

    % Create figure
    pos0 = get(0,'screenSize');
    pos = [1,pos0(4)/2,pos0(3)/1.2,pos0(4)/1.2];
    figure('position',pos,...
        'color',[1 1 1],...
        'name','BMS all');

    % plot BMS results
    hold on; subplot(1,2,1); bar(1, res.BMS(i).exp_r(1),'FaceColor',[0,176/255,240/255],'EdgeColor',[0,176/255,240/255]);
    hold on; subplot(1,2,1); bar(2, res.BMS(i).exp_r(2),'FaceColor',[112/255,48/255,160/255],'EdgeColor',[112/255,48/255,160/255]);
    ylabel ('posterior probability', 'FontSize', 15); ylim([0 1]);
    set(gca, 'XTick', []);
    set(gca,'box','off'); get(gca, 'YTick'); set(gca, 'FontSize', 13);
    ax1       = subplot(1,2,1);
    ax1.YTick = [0 0.25 0.5 0.75 1.0];
    h_leg     = legend(optionsFile.model.space{1}, optionsFile.model.space{2}, 'Location', 'east');
    set(h_leg,'box','off','FontSize', 13);

    hold on; subplot(1,2,2); bar(1, res.BMS(i).xp(1),'FaceColor',[0,176/255,240/255],'EdgeColor',[0,176/255,240/255]);
    hold on; subplot(1,2,2); bar(2, res.BMS(i).xp(2),'FaceColor',[112/255,48/255,160/255],'EdgeColor',[112/255,48/255,160/255]);
    ylabel('exceedance probability', 'FontSize', 15);
    set(gca, 'XTick', []);
    set(gca,'box','off'); get(gca, 'YTick'); set(gca, 'FontSize', 13);
    ax2 = subplot(1,2,2);
    ax2.YTick = [0 0.25 0.5 0.75 1.0];
    h_leg2 = legend(optionsFile.model.space{1}, optionsFile.model.space{2}, 'Location', 'east');
    set(h_leg2,'box','off','FontSize', 13);

    hold on; subplot(1,2,2); bar(1, res.BMS(i).pxp(1),'FaceColor',[0,176/255,240/255],'EdgeColor',[0,176/255,240/255]);
    hold on; subplot(1,2,2); bar(2, res.BMS(i).pxp(2),'FaceColor',[112/255,48/255,160/255],'EdgeColor',[112/255,48/255,160/255]);
    ylabel('protected exceedance probability', 'FontSize', 15);
    set(gca, 'XTick', []);
    set(gca,'box','off'); get(gca, 'YTick'); set(gca, 'FontSize', 13);
    ax2       = subplot(1,2,2);
    ax2.YTick = [0 0.25 0.5 0.75 1.0];
    h_leg2    = legend(optionsFile.model.space{1}, optionsFile.model.space{2}, 'Location', 'east');
    set(h_leg2,'box','off','FontSize', 13);

    sgtitle(['Bayesian Model Selection - Group ', num2str(i)], 'FontSize', 18);

    figdir = fullfile([char(optionsFile.paths.plotsDir),filesep,'BMS- Group ', num2str(i)]);
    print(figdir, '-dpng');
    close all;
end
end