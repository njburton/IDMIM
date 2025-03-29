function [] = parameter_recovery(cohortNo,subCohort)

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

if exist('optionsFile.mat','file')==2
    load("optionsFile.mat");
else
    optionsFile = runOptions();
end
optionsFile = setup_configFiles(optionsFile,cohortNo);


%% exclude datasets
if optionsFile.doExcludeData==1
    [inclIdArray,optionsFile] = excludeData(optionsFile,cohortNo,subCohort,'updateDataInfo');
    disp([num2str(sum(inclIdArray)), 'of ',num2str(length(inclIdArray)), ' mice included in final analyses.' ])
end

disp('************************************** PARAMETER RECOVERY **************************************');
disp('*');
disp('*');

%% LOAD inverted mouse data
% and save data into rec.est struct and paramete values for recovery into
% rec.param.{}.est

if numel(optionsFile.cohort(cohortNo).conditions)==0
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
     currCondition = [];
    for iTask = 1:numel(optionsFile.cohort(cohortNo).testTask)
        currTask = optionsFile.cohort(cohortNo).testTask(iTask).name;
        for iMouse = 1:nSize
            currMouse = mouseIDs{iMouse};
            for m_est = 1:numel(optionsFile.model.space)
                % load results from real data model inversion
                if isempty(optionsFile.cohort(cohortNo).conditions)
                    rec.est(iMouse,m_est).task(iTask).data =  load([char(optionsFile.paths.cohort(cohortNo).results),...
                        'mouse',char(currMouse),'_',currTask,'_',optionsFile.dataFiles.rawFitFile{m_est},'.mat']);
                else
                    currCondition = optionsFile.cohort(cohortNo).conditions{iCondition};
                    rec.est(iMouse,m_est).task(iTask).data = load([char(optionsFile.paths.cohort(cohortNo).results),...
                        'mouse',char(currMouse),'_condition_',currCondition,'_',...
                        currTask,'_',optionsFile.dataFiles.rawFitFile{m_est},'.mat']);
                end
                % param values in transformed space (assumption of Gaussian prior)
                rec.param(iTask).prc(m_est).estAgent(iMouse,:) = rec.est(iMouse,m_est).task(iTask).data.est.p_prc.ptrans(optionsFile.modelSpace(m_est).prc_idx);
                rec.param(iTask).obs(m_est).estAgent(iMouse,:) = rec.est(iMouse,m_est).task(iTask).data.est.p_obs.ptrans(optionsFile.modelSpace(m_est).obs_idx);
            end
        end
    end

    %% LOAD simulated responses and inverted simulated responses
    % and save simulated response data into rec.param.{}.simAgent struct and paramete values for recovery into
    % rec.param.{}.estAgent. The data were simulated with all models in the
    % model space and inverted with all the models in the model space.

    for iTask = 1:numel(optionsFile.cohort(cohortNo).testTask)
        for iAgent = 1:nSize
            for m_in = 1:numel(optionsFile.model.space)
                modelIn = optionsFile.dataFiles.rawFitFile{m_in};
                simResp = load([optionsFile.paths.cohort(cohortNo).simulations,optionsFile.model.space{m_in},...
                    '_',optionsFile.cohort(cohortNo).testTask(iTask).name,'_sim.mat']);
                rec.param(iTask).prc(m_in).simAgent(iAgent,:) = simResp.agent(iAgent,m_in).task(iTask).input.prc.transInp(optionsFile.modelSpace(m_in).prc_idx);
                rec.param(iTask).obs(m_in).simAgent(iAgent,:) = simResp.agent(iAgent,m_in).task(iTask).input.obs.transInp(optionsFile.modelSpace(m_in).obs_idx);
            end
        end
    end

    %% CALCULATE Pearson's Correlation Coefficient (pcc)

    % Perceptual Model
    for iTask = 1:numel(optionsFile.cohort(cohortNo).testTask)
        for m = 1:numel(optionsFile.model.space)
            for p = 1:length(optionsFile.modelSpace(m).prc_idx)
                [prc_coef,prc_p] = corr(rec.param(iTask).prc(m).simAgent(:,p),...
                    rec.param(iTask).prc(m).estAgent(:,p));
                rec.param(iTask).prc(m).pcc(p)  = diag(prc_coef);
                rec.param(iTask).prc(m).pval(p) = diag(prc_p);
            end
        end
    end

    % Observational Model
    for iTask = 1:numel(optionsFile.cohort(cohortNo).testTask)
        for m = 1:numel(optionsFile.model.space)
            for p = 1:length(optionsFile.modelSpace(m).obs_idx)
                [obs_coef,obs_p] = corr(rec.param(iTask).obs(m_in).simAgent(:,p),...
                    rec.param(iTask).obs(m_in).estAgent(:,p));
                rec.param(iTask).obs(m).pcc(p)  = diag(obs_coef);
                rec.param(iTask).obs(m).pval(p) = diag(obs_p);
            end
        end
    end

    %% PLOT correlation plot

    for iTask = 1:numel(optionsFile.cohort(cohortNo).testTask)
        for m = 1:numel(optionsFile.model.space)
            t = tiledlayout('flow');
            figure('Color',[1,1,1],'pos',[10 10 1050 500]);
            % Perceptual Model
            for pPrc = 1:size(optionsFile.modelSpace(m).prc_idx,2)
                nexttile;
                scatter(rec.param(iTask).prc(m).simAgent(:,pPrc),rec.param(iTask).prc(m).estAgent(:,pPrc),'filled');
                lsline;
                ylim([(min(rec.param(iTask).prc(m).estAgent(:,pPrc))-0.1) (max(rec.param(iTask).prc(m).estAgent(:,pPrc))+0.1)]);
                [t,s] = title([optionsFile.model.space{m},' ',optionsFile.modelSpace(m).free_expnms_mu_prc{pPrc},'rho = ' num2str(rec.param(iTask).prc(m).pcc(pPrc))]);
                t.FontSize = 18;
                xlabel('simulated data')
                ylabel('estimated data')
                hold on;
            end

            % Observational Model
            for pObs = 1:size(optionsFile.modelSpace(m).obs_idx,2)
                nexttile;
                scatter(rec.param(iTask).obs(m).simAgent(:,pObs),rec.param(iTask).obs(m).estAgent(:,pObs),'filled');
                lsline;
                ylim([(min(rec.param(iTask).obs(m).estAgent(:,pObs))-0.1) (max(rec.param(iTask).obs(m).estAgent(:,pObs))+0.1)]);
                [t,s] = title([optionsFile.model.space{m},' ',optionsFile.modelSpace(m).free_expnms_mu_obs{pObs},'rho = ' num2str(rec.param(iTask).obs(m).pcc(pObs))]);
                t.FontSize = 18;
                hold on;
                xlabel('simulated data')
                ylabel('estimated data')
                hold on;
            end

            saveName = getSaveName(optionsFile,cohortNo,subCohort,currCondition);
            figTitle = getFigTitle(optionsFile,cohortNo,subCohort,currCondition);
            sgtitle([optionsFile.modelSpace(m).name,figTitle,optionsFile.cohort(cohortNo).testTask(iTask).name], 'FontSize', 18);
            figDir = fullfile([optionsFile.paths.cohort(cohortNo).groupSim ,'Parameter_recovery',...
                optionsFile.modelSpace(m).name,saveName,optionsFile.cohort(cohortNo).testTask(iTask).name]);

            print(figDir, '-dpng');
            save([figDir,'.fig'])
            close all;
        end
    end

    %% PLOT PRIORS AND POSTERIORS
 for t = 1:numel(optionsFile.cohort(cohortNo).testTask)
    for m = 1:numel(optionsFile.model.space)
        % perceptual model
        for j = 1:size(optionsFile.modelSpace(m).prc_idx,2)
            hgf_plot_param_pdf(optionsFile.modelSpace(m).free_expnms_mu_prc,rec.est(:,m),optionsFile.modelSpace(m).prc_idx(j),j,t,'prc');

            saveName = getSaveName(optionsFile,cohortNo,subCohort,currCondition);
            figdir   = fullfile(optionsFile.paths.cohort(cohortNo).groupLevel,...
                [optionsFile.cohort(cohortNo).taskPrefix,'prc_priors_posteriors_model_',char(optionsFile.model.space{m}),'_',optionsFile.modelSpace(m).free_expnms_mu_prc{j},saveName,optionsFile.cohort(cohortNo).testTask(t).name]);
            print(figdir, '-dpng');
            close;
        end

        % observational model
        for k = 1:size(optionsFile.modelSpace(m).obs_idx,2)
            hgf_plot_param_pdf(optionsFile.modelSpace(m).free_expnms_mu_prc,rec.est(:,m),optionsFile.modelSpace(m).obs_idx(k),k,t,'obs');

            saveName = getSaveName(optionsFile,cohortNo,subCohort,currCondition);
            figdir   = fullfile(optionsFile.paths.cohort(cohortNo).groupLevel,...
                [optionsFile.cohort(cohortNo).taskPrefix,'obs_priors_posteriors_model_',char(optionsFile.model.space{m}),'_',...
                optionsFile.modelSpace(m).free_expnms_mu_obs{k},saveName,optionsFile.cohort(cohortNo).testTask(iTask).name]);
            print(figdir, '-dpng');
            close;
        end
    end
 end
    close all

    %% SAVE results as struct
    res.rec = rec;
    save_path = fullfile([optionsFile.paths.cohort(cohortNo).groupLevel,optionsFile.cohort(cohortNo).taskPrefix,'recoveryData',saveName,optionsFile.cohort(cohortNo).testTask(t).name,'.mat']);
    save(save_path, '-struct', 'res');

end
disp('recovery analysis complete.')

end
