function [] = parameter_recovery(cohortNo)

%% parameter_recovery
%  Parameter recovery analysis based on simulations. This step will be
%  executed if optionsFile.doSimulations = 1;
%
%   SYNTAX:       parameter_recovery(cohortNo)
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

disp('************************************** PARAMETER RECOVERY **************************************');
disp('*');
disp('*');

%% LOAD inverted mouse data
% and save data into rec.est struct and paramete values for recovery into
% rec.param.{}.est


for iTask = 1:numel(optionsFile.cohort(cohortNo).testTask)

    % collate all mouse IDs
    mouseIDs = [optionsFile.cohort(cohortNo).treatment.maleMice,optionsFile.cohort(cohortNo).treatment.femaleMice,...
    optionsFile.cohort(cohortNo).control.maleMice,optionsFile.cohort(cohortNo).control.femaleMice];

    %load data exclusion info
    % still to do!
     load([char(optionsFile.paths.cohort(cohortNo).results),'ExclusionInfo_',char(currTask),'.mat']);


    for iMouse = 1:optionsFile.cohort(cohortNo).nSize
        currMouse = mouseIDs{iMouse};
        for m_est = 1:numel(optionsFile.model.space)
            currModel = optionsFile.model.space{m_est};
            fprintf('current iteration: mouse=%1.0f, model=%1.0f \n', iMouse,m_est);

            % load results from real data model inversion
            try
                rec.est(iMouse,m_est).task(iTask).data = load([optionsFile.paths.cohort(cohortNo).results,...
                    optionsFile.cohort(cohortNo).dataFile.fileStartSrings{1},currMouse,'_',optionsFile.cohort(cohortNo).testTask(iTask).name,'_',currModel,'.mat']);
            catch
                try
                    rec.est(iMouse,m_est).task(iTask).data = load([optionsFile.paths.cohort(cohortNo).results,...
                        optionsFile.cohort(cohortNo).dataFile.fileStartSrings{2},currMouse,'_',optionsFile.cohort(cohortNo).testTask(iTask).name,'_',currModel,'.mat']);
                catch
                    rec.est(iMouse,m_est).task(iTask).data = load([optionsFile.paths.cohort(cohortNo).results,...
                        optionsFile.cohort(cohortNo).dataFile.fileStartSrings{3},currMouse,'_',optionsFile.cohort(cohortNo).testTask(iTask).name,'_',currModel,'.mat']);
                end
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
% model space and inverted with all the models in the model space. For
% model identifiability we are saving into the following structure: agent(m_in,iAgent,m_est)

for iTask = 1:numel(optionsFile.cohort(cohortNo).testTask)
    for iAgent = 1:optionsFile.cohort(cohortNo).nSize
        for m_in = 1:numel(optionsFile.model.space)
            modelIn = optionsFile.model.space{m_in};
            fprintf('current iteration: n=%1.0f, m=%1.0f \n', iAgent,modelIn);
            simResp = load([optionsFile.paths.cohort(cohortNo).simulations,optionsFile.model.space{m_in},...
                            optionsFile.cohort(cohortNo).testTask(iTask).name,'_sim.mat']);
            
            for m_est = 1:numel(optionsFile.model.space)
                modelEst = optionsFile.model.space{m_est};
                % load results from simulated agents' model inversion
                rec.sim.task(iTask).agent(m_in,iAgent,m_est).data = load(fullfile(optionsFile.paths.cohort(cohortNo).simulations, ...
                    [optionsFile.model.space{m_in},'_simAgent_', num2str(iAgent),'_model_in_',modelIn,'_model_est_',modelEst,...
                    '_task_',optionsFile.cohort(cohortNo).testTask(iTask).name,'.mat']));

                % LME
                rec.task(iTask).model(m_in).LME(iAgent,m_est) = rec.sim.task(iTask).agent(m_in,iAgent,m_est).data.optim.LME;
            end
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

        sgtitle([optionsFile.modelSpace(m).name], 'FontSize', 18);
        figDir = fullfile([optionsFile.paths.cohort(cohortNo).simPlots,'Parameter_recovery_', ...
            optionsFile.modelSpace(m).name,' ',optionsFile.cohort(cohortNo).testTask(iTask).name]);
        print(figDir, '-dpng');
        save([figDir,'.fig'])
    end
end

%% PLOT PRIORS AND POSTERIORS

for m = 1:numel(optionsFile.model.space)

    % perceptual model
    for j = 1:size(optionsFile.modelSpace(m).prc_idx,2)
        hgf_plot_param_pdf(res.main.ModSpace(m).free_expnms_mu_prc,M(m),res.main.ModSpace(m),res.pilot.ModSpace(m), j, 'prc')

        figdir = fullfile(simP.saveDirGroupPilots,...
            [simP.Acronym,'_priors_model_', options.model.space{m}, '_prcparam_', num2str(j),'_pilot_priors']);
        print(figdir, '-dpng');
        close;
    end

    % observational model
    for k = 1:size(optionsFile.modelSpace(m).obs_idx,2)
        hgf_plot_param_pdf(res.main.ModSpace(m).free_expnms_mu_obs,M(m),res.main.ModSpace(m),res.pilot.ModSpace(m), k, 'obs')

        figdir = fullfile(simP.saveDirGroupPilots,...
            [simP.Acronym,'_priors_model_', options.model.space{m}, '_obsparam_', num2str(k),'_pilot_priors']);
        print(figdir, '-dpng');
        close;
    end
end

hgf_plot_param_pdf(paramNames,data,prior,posterior,i,type);

close all

%% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %%
%% MODEL IDENTIFIABILITY (LME Winner classification)

for iTask = 1:numel(optionsFile.cohort(cohortNo).testTask)

    % pre-allocate
     rec.task(iTask).class.LMEwinner     = NaN(numel(optionsFile.model.space),numel(optionsFile.model.space));
     rec.task(iTask).class.percLMEwinner = NaN(size(rec.task(iTask).class.LMEwinner));

    % calc winner freq for each data generating model
    for m = 1:numel(optionsFile.model.space)
        [rec.task(iTask).class.max(m).val, rec.task(iTask).class.max(m).idx] = max(rec.task(iTask).model(m).LME, [], 2);
        for i = 1:numel(optionsFile.model.space)
            rec.task(iTask).class.LMEwinner(m,i) = sum(rec.task(iTask).class.max(m).idx==i);
        end
        rec.task(iTask).class.percLMEwinner(m,:) = rec.task(iTask).class.LMEwinner(m,:)./12;% should be !!! :optionsFile.simulations.nSamples
        % accuracy
        rec.task(iTask).class.acc(m) = rec.task(iTask).class.percLMEwinner(m,m);
    end

    % balanced accuraccy
    rec.task(iTask).class.balacc = mean(rec.task(iTask).class.acc);
    % chance threshold (inv binomial distr)
    rec.task(iTask).class.chancethr = binoinv(0.9, optionsFile.simulations.nSamples, 1/numel(optionsFile.model.space)) / 12; %optionsFile.simulations.nSamples; 
end

%% PLOT MODEL IDENTIFIABILITY
for iTask = 1:numel(optionsFile.cohort(cohortNo).testTask)
    label_x = {optionsFile.model.space{1} optionsFile.model.space{2} optionsFile.model.space{3}};
    figure('color',[1 1 1],'name','model identifiability');

    numlabels = size(rec.task(iTask).class.percLMEwinner, 1); % number of labels

    % plot colors
    imagesc(rec.task(iTask).class.percLMEwinner);
    title(sprintf('Balanced Accuracy: %.2f%%', 100*trace(rec.task(iTask).class.LMEwinner)/sum(rec.task(iTask).class.LMEwinner(:))));
    ylabel('Output Class'); xlabel('Target Class');

    % set colormap
    colormap(flipud(gray));

    % Create strings from the matrix values and remove spaces
    textStrings = num2str([rec.task(iTask).class.percLMEwinner(:), rec.task(iTask).class.LMEwinner(:)], '%.1f%%\n%d\n');
    textStrings = strtrim(cellstr(textStrings));

    % Create x and y coordinates for the strings and plot them
    [x,y]       = meshgrid(1:numlabels);
    hStrings    = text(x(:),y(:),textStrings(:), 'HorizontalAlignment','center');

    % Get the middle value of the color range
    midValue    = mean(get(gca,'CLim'));

    % Choose white or black for the text color of the strings so they can be seen over the background color
    textColors  = repmat(rec.task(iTask).class.percLMEwinner(:) > midValue,1,3);
    set(hStrings,{'Color'},num2cell(textColors,2));

    % Setting the axis labels
    set(gca,'XTick',1:numlabels,...
        'XTickLabel',label_x,...
        'YTick',1:numlabels,...
        'YTickLabel',label_x,...
        'TickLength',[0 0]);

    figdir = fullfile([optionsFile.paths.cohort(cohortNo).simPlots,'Model Identifiability  ',...
                       optionsFile.cohort(cohortNo).testTask(iTask).name]);
    print(figdir, '-dpng');
    save([figDir,'.fig'])
end

close all;

%% SAVE results as struct
res.rec = rec;
save_path = fullfile(optionsFile.paths.cohort(cohortNo).simulations,'sim_and_realData.mat');
save(save_path, '-struct', 'res');

disp('recovery analysis complete.')

end
