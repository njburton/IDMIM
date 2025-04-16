function [] = parameterRecovery(cohortNo,subCohort,iTask,iCondition,iRep,nReps)

%% parameter_recovery
%  Parameter recovery analysis based on simulations. This step will be
%  executed if optionsFile.doSimulations = 1;
%
%   SYNTAX:       parameter_recovery(cohortNo,{'treatment','controls',[]})
%
%   IN: cohortNo:  integer, cohort number, see optionsFile for what cohort
%                            corresponds to what number in the
%                            optionsFile.cohort(cohortNo).name struct. This
%                            allows to run the pipeline and its functions for different
%                            cohorts whose expcifications have been set in runOptions.m
%
% Coded by: 2025; Katharina V. Wellstein,
%           katharina.wellstein@newcastle.edu.au
%           https://github.com/kwellstein
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

%% INITIALIZE options and variables needed to run this function
disp('************************************** PARAMETER RECOVERY **************************************');
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
currTask = optionsFile.cohort(cohortNo).testTask(iTask).name;

if isempty(optionsFile.cohort(cohortNo).conditions)
    currCondition = [];
else
    currCondition = optionsFile.cohort(cohortNo).conditions{iCondition};
end

disp(['********for ',currCondition, ' mice in ', char(optionsFile.cohort(cohortNo).name), ' cohort ********']);

% check available mouse data and exclusion criteria
[mouseIDs,nSize] = getSampleVars(optionsFile,cohortNo,subCohort);
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

for iMouse = 1:nSize
    currMouse = mouseIDs{iMouse};
    loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,...
        [],currCondition,iRep,nReps,'info');
    load([char(optionsFile.paths.cohort(cohortNo).data),...
        'mouse',char(currMouse),'_',loadInfoName]);
    if any([MouseInfoTable.exclCrit2_met,MouseInfoTable.exclCrit1_met],'all')
        disp(['mouse ', currMouse,' excluded based on exclusion criteria']);
        exclArray(iMouse) = iMouse;
    end
end

exclArray = sort(exclArray,'descend');
exclArray(exclArray==0)=[];

for i=exclArray
  mouseIDs(i) =[];
end
nSize = numel(mouseIDs);

optionsFile = setup_configFiles(optionsFile,cohortNo);

%% LOAD inverted mouse data
% and save data into rec.est struct and paramete values for recovery into
% rec.param.{}.est
for iMouse = 1:nSize
    currMouse = mouseIDs{iMouse};
    loadDataName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,...
        [],currCondition,iRep,nReps,[]);

    for iModel = 1:nModels
        % load results from real data model inversion
        rec.est(iMouse,iModel).task(iTask,iRep).data =  load([char(optionsFile.paths.cohort(cohortNo).results),...
            'mouse',char(currMouse),'_',loadDataName,'_',optionsFile.dataFiles.rawFitFile{iModel},'.mat']);

        % param values in transformed space (assumption of Gaussian prior)
        rec.param(iTask,iRep).prc(iModel).estAgent(iMouse,:) = rec.est(iMouse,iModel).task(iTask,iRep).data.est.p_prc.ptrans(optionsFile.modelSpace(iModel).prc_idx);
        rec.param(iTask,iRep).obs(iModel).estAgent(iMouse,:) = rec.est(iMouse,iModel).task(iTask,iRep).data.est.p_obs.ptrans(optionsFile.modelSpace(iModel).obs_idx);

        % load simulated responses with current model
        simResp = load([optionsFile.paths.cohort(cohortNo).simulations,optionsFile.model.space{iModel},...
            '_',optionsFile.cohort(cohortNo).testTask(iTask).name,'_sim.mat']);
        rec.param(iTask).prc(iModel).simAgent(iMouse,:) = simResp.agent(iMouse,iModel).task(iTask).input.prc.transInp(optionsFile.modelSpace(iModel).prc_idx);
        rec.param(iTask).obs(iModel).simAgent(iMouse,:) = simResp.agent(iMouse,iModel).task(iTask).input.obs.transInp(optionsFile.modelSpace(iModel).obs_idx);
    end  % END MODELS Loop
end % END MOUSE Loop

%% CALCULATE Pearson's Correlation Coefficient

for iModel = 1:nModels
    % Perceptual Model parameters
    for pRec = 1:length(optionsFile.modelSpace(iModel).prc_idx)
        [prc_coef,prc_p] = corr(rec.param(iTask).prc(iModel).simAgent(:,pRec),...
            rec.param(iTask,iRep).prc(iModel).estAgent(:,pRec));
        rec.param(iTask,iRep).prc(iModel).pcc(pRec)  = diag(prc_coef);
        rec.param(iTask,iRep).prc(iModel).pval(pRec) = diag(prc_p);

        % Observational Model parameters
        for pObs= 1:length(optionsFile.modelSpace(iModel).obs_idx)
            [obs_coef,obs_p] = corr(rec.param(iTask).obs(iModel).simAgent(:,pObs),...
                rec.param(iTask,iRep).obs(iModel).estAgent(:,pObs));
            rec.param(iTask,iRep).obs(iModel).pcc(pObs)  = diag(obs_coef);
            rec.param(iTask,iRep).obs(iModel).pval(pObs) = diag(obs_p);
        end
    end
end % END MODELS Loop

%% PLOT correlation plot
if optionsFile.doCreatePlots == 1
    for iModel = 1:nModels
        tiledlayout('flow');
        figure('Color',[1,1,1],'pos',[10 10 1050 500]);
        % Perceptual Model
        for pPrc = 1:size(optionsFile.modelSpace(iModel).prc_idx,2)
            nexttile;
            scatter(rec.param(iTask).prc(iModel).simAgent(:,pPrc),rec.param(iTask,iRep).prc(iModel).estAgent(:,pPrc),'filled');
            lsline;
            ylim([(min(rec.param(iTask,iRep).prc(iModel).estAgent(:,pPrc))-0.1) (max(rec.param(iTask,iRep).prc(iModel).estAgent(:,pPrc))+0.1)]);
            [t,~] = title([optionsFile.model.space{iModel},' ',optionsFile.modelSpace(iModel).free_expnms_mu_prc{pPrc},'rho = ' num2str(rec.param(iTask,iRep).prc(iModel).pcc(pPrc))]);
            t.FontSize = 18;
            xlabel('simulated data')
            ylabel('estimated data')
            hold on;
        end

        % Observational Model
        for pObs = 1:size(optionsFile.modelSpace(iModel).obs_idx,2)
            nexttile;
            scatter(rec.param(iTask).obs(iModel).simAgent(:,pObs),rec.param(iTask,iRep).obs(iModel).estAgent(:,pObs),'filled');
            lsline;
            ylim([(min(rec.param(iTask,iRep).obs(iModel).estAgent(:,pObs))-0.1) (max(rec.param(iTask,iRep).obs(iModel).estAgent(:,pObs))+0.1)]);
            [t,~] = title([optionsFile.model.space{iModel},' ',optionsFile.modelSpace(iModel).free_expnms_mu_obs{pObs},'rho = ' num2str(rec.param(iTask,iRep).obs(iModel).pcc(pObs))]);
            t.FontSize = 18;
            hold on;
            xlabel('simulated data')
            ylabel('estimated data')
            hold on;
        end

        saveName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,subCohort,currCondition,iRep,nReps,[]);
        figTitle = getFigTitle(optionsFile,cohortNo,subCohort,currCondition);
        sgtitle([optionsFile.modelSpace(iModel).name,figTitle,optionsFile.cohort(cohortNo).testTask(iTask).name], 'FontSize', 18);

        figDir = fullfile([optionsFile.paths.cohort(cohortNo).groupSim ,'Parameter_recovery',...
            optionsFile.modelSpace(iModel).name,saveName,optionsFile.cohort(cohortNo).testTask(iTask).name]);

        print(figDir, '-dpng');
        save([figDir,'.fig'])
        close all;
    end % END MODELS Loop

    %% PLOT PRIORS AND POSTERIORS
    for iModel = 1:nModels
        % perceptual model
        for j = 1:size(optionsFile.modelSpace(iModel).prc_idx,2)
            hgf_plot_param_pdf(optionsFile.modelSpace(iModel).free_expnms_mu_prc,rec.est(:,iModel),optionsFile.modelSpace(iModel).prc_idx(j),j,iTask,'prc');

            saveName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,subCohort,currCondition,iRep,nReps,[]);
            figdir   = fullfile(optionsFile.paths.cohort(cohortNo).groupLevel,[saveName,'prc_priors_posteriors',...
                char(optionsFile.model.space{iModel}),'_',optionsFile.modelSpace(iModel).free_expnms_mu_prc{j}]);
            print(figdir, '-dpng');
            close;
        end

        % observational model
        for k = 1:size(optionsFile.modelSpace(iModel).obs_idx,2)
            hgf_plot_param_pdf(optionsFile.modelSpace(iModel).free_expnms_mu_prc,rec.est(:,iModel),optionsFile.modelSpace(iModel).obs_idx(k),k,iTask,'obs');

            saveName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,subCohort,currCondition,iRep,nReps,[]);
            figdir   = fullfile(optionsFile.paths.cohort(cohortNo).groupLevel,[saveName,'obs_priors_posteriors_model_',...
                char(optionsFile.model.space{iModel}),'_',optionsFile.modelSpace(iModel).free_expnms_mu_obs{k}]);
            print(figdir, '-dpng');
            close;
        end
    end % END MODELS Loop
end
close all

%% SAVE results as struct
groupSaveName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,subCohort,currCondition,iRep,nReps,'param_recovery');
save_path = fullfile([optionsFile.paths.cohort(cohortNo).groupLevel,groupSaveName,'.mat']);
save(save_path, '-struct', 'rec');

disp('recovery analysis complete.')

end
