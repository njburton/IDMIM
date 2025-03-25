function performBMS(cohortNo,subCohort)

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
% specifications for this analysis
if exist('optionsFile.mat','file')==2
    load('optionsFile.mat');
else
    optionsFile = runOptions();
end

addpath(genpath([optionsFile.paths.toolboxDir,'spm']));
optionsFile = setup_configFiles(optionsFile,cohortNo);

disp('************************************** BAYESIAN MODEL SELECTION **************************************');
disp('*');
disp('*');


%% exclude datasets
if optionsFile.doExcludeData==1
    [inclIdArray,optionsFile] = excludeData(optionsFile,cohortNo,subCohort,'updateDataInfo');
    disp([num2str(sum(inclIdArray)), 'of ',num2str(length(inclIdArray)), ' mice included in final analyses.' ])
end


if strcmp(subCohort,'all')
    nConditions = 1;
    mouseIDs    = optionsFile.cohort(cohortNo).mouseIDs;
    nSize       = optionsFile.cohort(cohortNo).nSize;
elseif  numel(optionsFile.cohort(cohortNo).conditions)==0
    nConditions = 1;
    mouseIDs    = [optionsFile.cohort(cohortNo).(subCohort).maleMice,...
        optionsFile.cohort(cohortNo).(subCohort).femaleMice];
    nSize       = numel(mouseIDs);
else
    nConditions = numel(optionsFile.cohort(cohortNo).conditions);
    mouseIDs    = optionsFile.cohort(cohortNo).mouseIDs;
    nSize       = optionsFile.cohort(cohortNo).nSize;
end

for iCondition = 1:nConditions
    if nConditions ==1
        currCondition = [];
    else
        currCondition = optionsFile.cohort(cohortNo).conditions{iCondition};
    end

    for iTask = 1:numel(optionsFile.cohort(cohortNo).testTask)
        currTask = optionsFile.cohort(cohortNo).testTask(iTask).name;
        for iMouse = 1:nSize
            currMouse = mouseIDs{iMouse};
            for iModel = 1:numel(optionsFile.model.space)
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
                res.LME(iMouse,iModel)   = est.optim.LME;
                res.prc_param(iMouse,iModel).ptrans = est.p_prc.ptrans(optionsFile.modelSpace(iModel).prc_idx);
                res.obs_param(iMouse,iModel).ptrans = est.p_obs.ptrans(optionsFile.modelSpace(iModel).obs_idx);
            end
        end
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

saveName = getSaveName(optionsFile,cohortNo,subCohort,currCondition);

figdir = fullfile([optionsFile.paths.cohort(cohortNo).groupLevel,optionsFile.cohort(cohortNo).taskPrefix,'BMS',saveName,optionsFile.cohort(cohortNo).name]);
print(figdir, '-dpng');
close all;

end
