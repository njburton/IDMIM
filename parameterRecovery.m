function [] = parameterRecovery(cohortNo,subCohort)

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
nTasks  = numel(optionsFile.cohort(cohortNo).testTask);
nReps   = optionsFile.cohort(cohortNo).taskRepetitions;
nModels = numel(optionsFile.model.space);
iExcl = 1;
iInclMouse = 1;

if numel(optionsFile.cohort(cohortNo).conditions)==0
    nConditions   = 1;
    currCondition = [];
else
    nConditions = numel(optionsFile.cohort(cohortNo).conditions);
end
optionsFile = setup_configFiles(optionsFile,cohortNo);

%% exclude datasets
if optionsFile.doExcludeData==1
    [exclArray,~] = excludeData(optionsFile,cohortNo,subCohort,'excludeData',optionsFile.cohort(cohortNo).exclMode.ParamLevel);
end

%% LOAD inverted mouse data
% and save data into rec.est struct and paramete values for recovery into
% rec.param.{}.est
[mouseIDs,nSize] = getSampleSpecs(optionsFile,cohortNo,subCohort);

for iCondition = 1:nConditions
    if nConditions>1 % if there is more than one condition get condition name string
        currCondition = optionsFile.cohort(cohortNo).conditions{iCondition};
    end
    for iTask = 1:nTasks
        currTask = optionsFile.cohort(cohortNo).testTask(iTask).name;
        for iRep = 1:nReps
            for iMouse = 1:nSize
                currMouse = mouseIDs{iMouse};
                if ~any(exclArray(iExcl).ID==iMouse)
                for m_est = 1:nModels
                    % load results from real data model inversion
                    loadName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,...
                        [],currCondition,iRep,optionsFile.cohort(priorCohort).taskRepetitions,[]);
                    rec.est(iInclMouse,m_est).task(iTask,iRep).data =  load([char(optionsFile.paths.cohort(cohortNo).results),...
                        'mouse',char(currMouse),'_',loadName,'_',optionsFile.dataFiles.rawFitFile{m_est},'.mat']);
                end  % END MODELS Loop

                % param values in transformed space (assumption of Gaussian prior)
                rec.param(iTask,iRep).prc(m_est).estAgent(iInclMouse,:) = rec.est(iInclMouse,m_est).task(iTask,iRep).data.est.p_prc.ptrans(optionsFile.modelSpace(m_est).prc_idx);
                rec.param(iTask,iRep).obs(m_est).estAgent(iInclMouse,:) = rec.est(iInclMouse,m_est).task(iTask,iRep).data.est.p_obs.ptrans(optionsFile.modelSpace(m_est).obs_idx);
                
                iInclMouse = iInclMouse+1;
                else
                    disp(['mouse ',currMouse,' data not loaded based on exclusion criteria '])
                end
                iExcl = iExcl+1;
            end % END MOUSE Loop
        end % END REPETITIONS Loop
    end  % END TASKS Loop
end % END CONDITIONS Loop

%% LOAD simulated responses and inverted simulated responses
% and save simulated response data into rec.param.{}.simAgent struct and paramete values for recovery into
% rec.param.{}.estAgent. The data were simulated with all models in the
% model space and inverted with all the models in the model space.

for iTask = 1:nTasks
    for iAgent = 1:nSize
        for m_in = 1:nModels
            simResp = load([optionsFile.paths.cohort(cohortNo).simulations,optionsFile.model.space{m_in},...
                '_',optionsFile.cohort(cohortNo).testTask(iTask).name,'_sim.mat']);
            rec.param(iTask).prc(m_in).simAgent(iAgent,:) = simResp.agent(iAgent,m_in).task(iTask).input.prc.transInp(optionsFile.modelSpace(m_in).prc_idx);
            rec.param(iTask).obs(m_in).simAgent(iAgent,:) = simResp.agent(iAgent,m_in).task(iTask).input.obs.transInp(optionsFile.modelSpace(m_in).obs_idx);
        end % END MODELS Loop
    end % END SIMULATED AGENTS Loop
end % END TASKS Loop

%% CALCULATE Pearson's Correlation Coefficient

% Perceptual Model
for iTask = 1:nTasks
    for iRep = 1:nReps
        for m = 1:nModels
            for p = 1:length(optionsFile.modelSpace(m).prc_idx)
                [prc_coef,prc_p] = corr(rec.param(iTask).prc(m).simAgent(:,p),...
                    rec.param(iTask,iRep).prc(m).estAgent(:,p));
                rec.param(iTask,iRep).prc(m).pcc(p)  = diag(prc_coef);
                rec.param(iTask,iRep).prc(m).pval(p) = diag(prc_p);
            end
        end % END MODELS Loop
    end % END REPETITIONS Loop
end % END TASKS Loop

% Observational Model
for iTask = 1:nTasks
    for iRep = 1:nReps
        for m = 1:nModels
            for p = 1:length(optionsFile.modelSpace(m).obs_idx)
                [obs_coef,obs_p] = corr(rec.param(iTask).obs(m_in).simAgent(:,p),...
                    rec.param(iTask,iRep).obs(m_in).estAgent(:,p));
                rec.param(iTask,iRep).obs(m).pcc(p)  = diag(obs_coef);
                rec.param(iTask,iRep).obs(m).pval(p) = diag(obs_p);
            end
        end % END MODELS Loop
    end % END REPETITIONS Loop
end % END TASKS Loop

%% PLOT correlation plot
if optionsFile.doCreatePlots == 1
    for iCondition = 1:nConditions
        if nConditions>1 % if there is more than one condition get condition name string
            currCondition = optionsFile.cohort(cohortNo).conditions{iCondition};
        end
        for iTask = 1:nTasks
            for iRep = 1:nReps
                for m = 1:nModels
                    t = tiledlayout('flow');
                    figure('Color',[1,1,1],'pos',[10 10 1050 500]);
                    % Perceptual Model
                    for pPrc = 1:size(optionsFile.modelSpace(m).prc_idx,2)
                        nexttile;
                        scatter(rec.param(iTask).prc(m).simAgent(:,pPrc),rec.param(iTask,iRep).prc(m).estAgent(:,pPrc),'filled');
                        lsline;
                        ylim([(min(rec.param(iTask,iRep).prc(m).estAgent(:,pPrc))-0.1) (max(rec.param(iTask,iRep).prc(m).estAgent(:,pPrc))+0.1)]);
                        [t,s] = title([optionsFile.model.space{m},' ',optionsFile.modelSpace(m).free_expnms_mu_prc{pPrc},'rho = ' num2str(rec.param(iTask,iRep).prc(m).pcc(pPrc))]);
                        t.FontSize = 18;
                        xlabel('simulated data')
                        ylabel('estimated data')
                        hold on;
                    end

                    % Observational Model
                    for pObs = 1:size(optionsFile.modelSpace(m).obs_idx,2)
                        nexttile;
                        scatter(rec.param(iTask).obs(m).simAgent(:,pObs),rec.param(iTask,iRep).obs(m).estAgent(:,pObs),'filled');
                        lsline;
                        ylim([(min(rec.param(iTask,iRep).obs(m).estAgent(:,pObs))-0.1) (max(rec.param(iTask,iRep).obs(m).estAgent(:,pObs))+0.1)]);
                        [t,s] = title([optionsFile.model.space{m},' ',optionsFile.modelSpace(m).free_expnms_mu_obs{pObs},'rho = ' num2str(rec.param(iTask,iRep).obs(m).pcc(pObs))]);
                        t.FontSize = 18;
                        hold on;
                        xlabel('simulated data')
                        ylabel('estimated data')
                        hold on;
                    end

                    saveName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,subCohort,currCondition,iRep,nReps,[]);
                    figTitle = getFigTitle(optionsFile,cohortNo,subCohort,currCondition);
                    sgtitle([optionsFile.modelSpace(m).name,figTitle,optionsFile.cohort(cohortNo).testTask(iTask).name], 'FontSize', 18);

                    figDir = fullfile([optionsFile.paths.cohort(cohortNo).groupSim ,'Parameter_recovery',...
                        optionsFile.modelSpace(m).name,saveName,optionsFile.cohort(cohortNo).testTask(iTask).name]);

                    print(figDir, '-dpng');
                    save([figDir,'.fig'])
                    close all;
                end % END MODELS Loop
            end % END REPETITIONS Loop
        end % END TASKS Loop
    end % END CONDITIONS Loop

    %% PLOT PRIORS AND POSTERIORS
    for iCondition = 1:nConditions
        if nConditions>1 % if there is more than one condition get condition name string
            currCondition = optionsFile.cohort(cohortNo).conditions{iCondition};
        end
        for iTask = 1:nTasks
            for iRep = 1:nReps
                for m = 1:nModels
                    % perceptual model
                    for j = 1:size(optionsFile.modelSpace(m).prc_idx,2)
                        hgf_plot_param_pdf(optionsFile.modelSpace(m).free_expnms_mu_prc,rec.est(:,m),optionsFile.modelSpace(m).prc_idx(j),j,t,'prc');

                        saveName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,subCohort,currCondition,iRep,nReps,[]);
                        figdir   = fullfile(optionsFile.paths.cohort(cohortNo).groupLevel,saveName,'prc_priors_posteriors',...
                            char(optionsFile.model.space{m}),'_',optionsFile.modelSpace(m).free_expnms_mu_prc{j});
                        print(figdir, '-dpng');
                        close;
                    end

                    % observational model
                    for k = 1:size(optionsFile.modelSpace(m).obs_idx,2)
                        hgf_plot_param_pdf(optionsFile.modelSpace(m).free_expnms_mu_prc,rec.est(:,m),optionsFile.modelSpace(m).obs_idx(k),k,t,'obs');

                        saveName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,subCohort,currCondition,iRep,nReps,[]);
                        figdir   = fullfile(optionsFile.paths.cohort(cohortNo).groupLevel,saveName,'obs_priors_posteriors_model_',...
                            char(optionsFile.model.space{m}),'_',optionsFile.modelSpace(m).free_expnms_mu_obs{k});
                        print(figdir, '-dpng');
                        close;
                    end
                end % END MODELS Loop
            end % END REPETITIONS Loop
        end % END TASKS Loop
    end % END CONDITIONS Loop
end
close all

%% SAVE results as struct
save_path = fullfile([optionsFile.paths.cohort(cohortNo).groupLevel,saveName,'recoveryData.mat']);
save(save_path, '-struct', 'rec');

disp('recovery analysis complete.')

end
