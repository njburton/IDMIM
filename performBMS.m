function performBMS(cohortNo,subCohort,iTask,iCondition,iRep)

%% performBMS
%  Performs Bayesian Model Selection to determine what model in the model
%  space describes the data acquired in the current dataset (cohort) best
%
%   SYNTAX:       preformBMS(cohortNo)
%
%   IN: cohortNo:  integer, cohort number, see optionsFile for what cohort
%                            corresponds to what number in the
%                            optionsFile.cohort(cohortNo).name struct. This
%                            allows to run the pipeline and its functions for different
%                            cohorts whose expcifications have been set in runOptions.m
%
% Original: 29-05-2024; Katharina V. Wellstein,
%           katharina.wellstein@newcastle.edu.au
%
% -------------------------------------------------------------------------
% This file is released under the terms of the GNU General Public Licence
% (GPL), version 3. You can redistribute it and/or modify it under the
% terms of the GPL (either version 3 or, at your option, any later version).
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details:
% <http://www.gnu.org/licenses/>
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
% _________________________________________________________________________
% =========================================================================

%% INITIALIZE Variables for running this function

disp('************************************** BAYESIAN MODEL SELECTION **************************************');
disp('*');
disp('*');

% load or run options for running this function
if exist('optionsFile.mat','file')==2
    load('optionsFile.mat');
else
    optionsFile = runOptions();
end

% prespecify variables needed for running this function
nModels  = numel(optionsFile.model.space);
nReps    = optionsFile.cohort(cohortNo).taskRepetitions;
currTask = optionsFile.cohort(cohortNo).testTask(iTask).name;

if isempty(optionsFile.cohort(cohortNo).conditions)
    currCondition = [];
else
    currCondition = optionsFile.cohort(cohortNo).conditions{iCondition};
end

disp(['*** for ',currCondition, ' mice in ', char(optionsFile.cohort(cohortNo).name), ' cohort ***']);

% check available mouse data and exclusion criteria
[mouseIDs,nSize] = getSampleSpecs(optionsFile,cohortNo,subCohort);
noDataArray = zeros(1,nSize);
exclArray   = zeros(1,nSize);

for iMouse = 1:nSize
    currMouse = mouseIDs{iMouse};
    loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,...
        [],currCondition,iRep,nReps,'info');
    if isfile([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',loadInfoName,'.mat'])
    else
        disp(['data for mouse ', currMouse,' not available']);
        noDataArray(iMouse) = iMouse;
    end
end

noDataArray = sort(noDataArray,'descend');
noDataArray(noDataArray==0)=[];

for i=noDataArray
  mouseIDs(i) =[];
end
nSize = numel(mouseIDs);


addpath(genpath([optionsFile.paths.toolboxDir,'spm']));
optionsFile = setup_configFiles(optionsFile,cohortNo);


for iMouse = 1:nSize
    currMouse = mouseIDs{iMouse};
    for iModel = 1:nModels
        % load results from real data model inversion
        if isempty(optionsFile.cohort(cohortNo).conditions)
            load([char(optionsFile.paths.cohort(cohortNo).results),...
                'mouse',char(currMouse),'_',currTask,'_',optionsFile.dataFiles.rawFitFile{iModel},'.mat']);
        else
            currCondition = optionsFile.cohort(cohortNo).conditions{iCondition};
            load([char(optionsFile.paths.cohort(cohortNo).results),...
                'mouse',char(currMouse),'_',currTask,'_condition_',currCondition,'_',...
                optionsFile.dataFiles.rawFitFile{iModel},'.mat']);
        end

        res.LME(iInclMouse,iModel)   = est.optim.LME;
        res.prc_param(iMouse,iModel).ptrans = est.p_prc.ptrans(optionsFile.modelSpace(iModel).prc_idx);
        res.obs_param(iMouse,iModel).ptrans = est.p_obs.ptrans(optionsFile.modelSpace(iModel).obs_idx);
    end
end


% PERFORM rfx BMS for all Mice
[res.BMS.alpha,res.BMS.exp_r,res.BMS.xp,res.BMS.pxp,res.BMS.bor] = spm_BMS(res.LME);

% Create figure
pos0 = get(0,'screenSize');
pos = [1,pos0(4)/2,pos0(3)/1.2,pos0(4)/1.2];
figure('position',pos,...
    'color',[1 1 1],...
    'name','BMS all');


% plot BMS results
hold on; subplot(1,3,1); bar(1, res.BMS.exp_r(1),'FaceColor',[0,0.6902,0.9412],'EdgeColor',[0,0.6902,0.9412]);
hold on; subplot(1,3,1); bar(2, res.BMS.exp_r(2),'FaceColor',[0.4392,0.1882,0.6275],'EdgeColor',[0.4392,0.1882,0.6275]);
hold on; subplot(1,3,1); bar(3, res.BMS.exp_r(3),'FaceColor',[0.1490,0.1490,0.1490],'EdgeColor',[0.1490,0.1490,0.1490]);
ylabel ('posterior probability', 'FontSize', 15); ylim([0 1]);
set(gca, 'XTick', []);
set(gca,'box','off'); get(gca, 'YTick'); set(gca, 'FontSize', 13);
ax1       = subplot(1,3,1);
ax1.YTick = [0 0.25 0.5 0.75 1.0];
h_leg     = legend(optionsFile.model.names{1},optionsFile.model.names{2},optionsFile.model.names{3}, 'Location', 'northeast');
set(h_leg,'box','off','FontSize', 13);
set(gca, 'color', 'none');

hold on; subplot(1,3,2); bar(1, res.BMS.xp(1),'FaceColor',[0,0.6902,0.9412],'EdgeColor',[0,0.6902,0.9412]);
hold on; subplot(1,3,2); bar(2, res.BMS.xp(2),'FaceColor',[0.4392,0.1882,0.6275],'EdgeColor',[0.4392,0.1882,0.6275]);
hold on; subplot(1,3,2); bar(3, res.BMS.xp(3),'FaceColor',[0.1490,0.1490,0.1490],'EdgeColor',[0.1490,0.1490,0.1490]);
ylabel('exceedance probability', 'FontSize', 15);
set(gca, 'XTick', []);
set(gca,'box','off'); get(gca, 'YTick'); set(gca, 'FontSize', 13);
ax2 = subplot(1,3,2);
ax2.YTick = [0 0.25 0.5 0.75 1.0];
% h_leg2 = legend(optionsFile.model.names{1},optionsFile.model.names{2},optionsFile.model.names{3}, 'Location', 'northeast');
% set(h_leg2,'box','off','FontSize', 13);
set(gca, 'color', 'none');

hold on; subplot(1,3,3); bar(1, res.BMS.pxp(1),'FaceColor',[0,0.6902,0.9412],'EdgeColor',[0,0.6902,0.9412]);
hold on; subplot(1,3,3); bar(2, res.BMS.pxp(2),'FaceColor',[0.4392,0.1882,0.6275],'EdgeColor',[0.4392,0.1882,0.6275]);
hold on; subplot(1,3,3); bar(3, res.BMS.pxp(3),'FaceColor',[0.1490,0.1490,0.1490],'EdgeColor',[0.1490,0.1490,0.1490]);
ylabel('protected exceedance probability', 'FontSize', 15);
set(gca, 'XTick', []);
set(gca,'box','off'); get(gca, 'YTick'); set(gca, 'FontSize', 13);
ax2       = subplot(1,3,3);
ax2.YTick = [0 0.25 0.5 0.75 1.0];
% h_leg2    = legend(optionsFile.model.names{1},optionsFile.model.names{2},optionsFile.model.names{3}, 'Location', 'northeast');
% set(h_leg2,'box','off','FontSize', 13);

sgtitle('Bayesian Model Selection', 'FontSize', 18);
set(gcf, 'color', 'none');
set(gca, 'color', 'none');

saveName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,subCohort,currCondition,iRep,nReps,[]);

figdir = fullfile([optionsFile.paths.cohort(cohortNo).groupLevel,saveName,'_BMS']);
print(figdir, '-dpng');
close all;

end
