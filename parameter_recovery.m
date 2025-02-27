function [] = parameter_recovery()

%% parameter_recovery
%  Parameter recovery analysis based on simulations. This step will be
%  executed if simP.doSimulations = 1;
%
%   SYNTAX:       parameter_recovery
%
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

for iTask = 1:numel(optionsFile.task.testTask)
    for iMouse = 1:optionsFile.cohort.nSize
        currMouse = optionsFile.cohort.controlGroup{iMouse};
        for m_est = 1:numel(optionsFile.model.space)
            currModel = optionsFile.model.space{m_est};
            fprintf('current iteration: mouse=%1.0f, model=%1.0f \n', iMouse,m_est);

            % load results from real data model inversion
            try
                rec.est(iMouse,m_est).task(iTask).data = load([optionsFile.paths.mouseModelFitFilesDir,filesep,...
                    '2024-10-09_mouse',currMouse,'_',optionsFile.task.testTask(iTask).name,'_',optionsFile.fileName.rawFitFile{m_est},'.mat']);
            catch
                try
                    rec.est(iMouse,m_est).task(iTask).data = load([optionsFile.paths.mouseModelFitFilesDir,filesep,...
                        '2024-10-13_mouse',currMouse,'_',optionsFile.task.testTask(iTask).name,'_',optionsFile.fileName.rawFitFile{m_est},'.mat']);
                catch
                    rec.est(iMouse,m_est).task(iTask).data = load([optionsFile.paths.mouseModelFitFilesDir,filesep,...
                        '2024-10-16_mouse',currMouse,'_',optionsFile.task.testTask(iTask).name,'_',optionsFile.fileName.rawFitFile{m_est},'.mat']);
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

for iTask = 1:numel(optionsFile.task.testTask)
    for iAgent = 1:optionsFile.cohort.nSize
        for m_in = 1:numel(optionsFile.model.space)
            fprintf('current iteration: n=%1.0f, m=%1.0f \n', iAgent,m_in);
            simResp = load([optionsFile.simulations.simResultsDir,filesep,optionsFile.model.space{m_in},optionsFile.task.testTask(iTask).name,'_sim.mat']);
            
            for m_est = 1:numel(optionsFile.model.space)

                % load results from simulated agents' model inversion
                rec.sim.task(iTask).agent(m_in,iAgent,m_est).data = load(fullfile(optionsFile.simulations.simResultsDir, ...
                    [optionsFile.model.space{m_in},'_simAgent_', num2str(iAgent),'_model_in',num2str(m_in),'_model_est',num2str(m_est),'_task_',optionsFile.task.testTask(iTask).name,'.mat']));

                % LME
                rec.task(iTask).model(m_in).LME(iAgent,m_est) = rec.sim.task(iTask).agent(m_in,iAgent,m_est).data.optim.LME;
            end
            rec.param(iTask).prc(m_in).simAgent(iAgent,:) = simResp.agent(iAgent,m_in).task(iTask).input.prc.transInp(optionsFile.modelSpace(m_in).prc_idx); 
            rec.param(iTask).obs(m_in).simAgent(iAgent,:) = simResp.agent(iAgent,m_in).task(iTask).input.obs.transInp(optionsFile.modelSpace(m_in).obs_idx);
        end
    end 
end

%% CALCULATE Pearson's Correlation Coefficient (pcc)

for iTask = 1:numel(optionsFile.task.testTask)
    for m = 1:numel(optionsFile.model.space)
        for p = 1:length(optionsFile.modelSpace(m).prc_idx)
            % prc model
            [prc_coef, prc_p] = corr(rec.param(iTask).prc(m).simAgent(:,p), rec.param(iTask).prc(m).estAgent(:,p));
            rec.param(iTask).prc(m).pcc(p)  = diag(prc_coef);
            rec.param(iTask).prc(m).pval(p) = diag(prc_p);
        end
    end
end

%if RW throws error, use ifElse statement to bypass
for iTask = 1:numel(optionsFile.task.testTask)
    for m = 1:numel(optionsFile.model.space)
        for p = 1:length(optionsFile.modelSpace(m).obs_idx)
            % obs model
            [obs_coef, obs_p] = corr(rec.param(iTask).obs(m_in).simAgent(:,p), rec.param(iTask).obs(m_in).estAgent(:,p));
            rec.param(iTask).obs(m).pcc(p)  = diag(obs_coef);
            rec.param(iTask).obs(m).pval(p) = diag(obs_p);
        end
    end
end

%% PLOT correlation plot
for iTask = 1:numel(optionsFile.task.testTask)
    for m = 1:numel(optionsFile.model.space)
        t = tiledlayout('flow');
        figure('Color',[1,1,1],'pos',[10 10 1050 500]);

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
        figDir = fullfile([optionsFile.paths.plotsDir, ...
            filesep,'Parameter_recovery_',optionsFile.modelSpace(m).name,' ',optionsFile.task.testTask(iTask).name]);
        print(figDir, '-dpng');

        save([figDir,'.fig'])
    end
end

close all

%% MODEL IDENTIFIABILITY (LME Winner classification)

for iTask = 1:numel(optionsFile.task.testTask)

    % pre-allocate
     rec.task(iTask).class.LMEwinner     = NaN(numel(optionsFile.model.space),numel(optionsFile.model.space));
     rec.task(iTask).class.percLMEwinner = NaN(size(rec.task(iTask).class.LMEwinner));

    % calc winner freq for each data generating model
    for m = 1:numel(optionsFile.model.space)
        [rec.task(iTask).class.max(m).val, rec.task(iTask).class.max(m).idx] = max(rec.task(iTask).model(m).LME, [], 2);
        for i = 1:numel(optionsFile.model.space)
            rec.task(iTask).class.LMEwinner(m,i) = sum(rec.task(iTask).class.max(m).idx==i);
        end
        rec.task(iTask).class.percLMEwinner(m,:) = rec.task(iTask).class.LMEwinner(m,:)./12; %optionsFile.simulations.nSamples;
        % accuracy
        rec.task(iTask).class.acc(m) = rec.task(iTask).class.percLMEwinner(m,m);
    end

    % balanced accuraccy
    rec.task(iTask).class.balacc = mean(rec.task(iTask).class.acc);
    % chance threshold (inv binomial distr)
    rec.task(iTask).class.chancethr = binoinv(0.9, optionsFile.simulations.nSamples, 1/numel(optionsFile.model.space)) / 12; %optionsFile.simulations.nSamples; 
end

%% PLOT model identifiability
for iTask = 1:numel(optionsFile.task.testTask)
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

    figdir = fullfile([optionsFile.paths.plotsDir,filesep,...
        'Model Identifiability  ',optionsFile.task.testTask(iTask).name]);
    print(figdir, '-dpng');
end

close all;

% %% Plot est mice (X axis are mice/sim) Yaxis=values;
% % Plot free perceptual model parameters
% xAxis = 1:optionsFile.cohort.nSize;
% for iTask = 1:numel(optionsFile.task.testTask)
%     for m = 1:2 % numel(optionsFile.model.space) have to fix prc_idx for RW model (and eventually VK model)
%         for p = 1:length(optionsFile.modelSpace(m).prc_idx)   % Plot both free params in perceptual model
%             for n = 1:optionsFile.cohort.nSize
%                 PostPerceptParam = rec.sim.task(iTask).agent(m,iAgent,m).data.p_prc.ptrans(optionsFile.modelSpace(m).prc_idx(p));
%                 fig = plot(xAxis(n),PostPerceptParam,'Marker', 'o','Color','b'); %ylim([-5.0, 5.0]);
%                 hold on
%             end %
% 
%             yline(rec.sim.task(iTask).agent(m,iAgent,m_).data.est.c_prc.priormus(optionsFile.modelSpace(m).prc_idx),'Color','r');
%             title(fig,['mice perceptual parameters',num2str(p),' ',optionsFile.task.testTask(iTask).name]);
%             figDir = fullfile([char(optionsFile.paths.plotsDir),filesep,'model',num2str(m),'_mice_prc_param',num2str(p),' ',optionsFile.task.testTask(iTask).name]);
%             save([figDir,'.fig']);
%             print([figDir,'.png'], '-dpng');
%             close all;
%         end
% 
%         %Plot free observational model parameters
%         for j = 1:optionsFile.cohort.nSize
%             PostObsParam = rec.sim.task(iTask).agent(m,iAgent,m_).data.est.p_obs.ptrans(optionsFile.modelSpace(m).obs_idx);   % Plot single free param in observation model
%             fig = plot(xAxis(j),PostObsParam,'Marker','o','Color','b');
%             hold on
%         end
% 
%         yline(rec.sim.task(iTask).agent(m,iAgent,m_).data.est.c_obs.priormus(optionsFile.modelSpace(m).obs_idx),'Color','r');
%         title(fig,['mice observational parameters',num2str(p),' ',optionsFile.task.testTask(iTask).name]);
%         figDir = fullfile([char(optionsFile.paths.plotsDir),filesep,'model',num2str(m),'_mice_obs_param',num2str(p),' ',optionsFile.task.testTask(iTask).name]);
%         save([figDir,'.fig']);
%         print([figDir,'.png'], '-dpng');
%         close all;
%     end
% end

% %% Plot simAgent's Perceptual & Observational Free Parameter values *TO CHECK IF THAT WORKS
% %Plot free perceptual model parameters
% xAxis = 1:length(optionsFile.task.MouseID);
% for iTask = 1:numel(optionsFile.task.testTask)
%     for m = 1:2 % numel(optionsFile.model.space) have to fix prc_idx for RW model (and eventually VK model)
%         for p = 1:length(optionsFile.modelSpace(m).prc_idx)   % Plot both free params in perceptual model
%             for n = 1:length(optionsFile.task.MouseID)
%                 PostPerceptParam = simResp.agent(iAgent,m_in).task(iTask).data.p_prc.p(optionsFile.modelSpace(m).prc_idx(p));
%                 fig = plot(xAxis(n),PostPerceptParam,'Marker', 'o','Color','b');
%                 hold on
%             end
%             yline(simResp.agent(iAgent,m_in).task(iTask).data.c_prc.priormus(optionsFile.modelSpace(m).prc_idx(p)),'Color','r');
%             %     title(fig,['simulated observational parameters',num2str(p)]);
%             figDir = fullfile([char(optionsFile.paths.plotsDir),filesep,'model',num2str(m),'_simAgents_prc_param',num2str(p)]);
%             save([figDir,'.fig']);
%             print([figDir,'.png'], '-dpng');
%             close all;
%         end
%     end
% 
%     %Plot free observational model parameters
%     for m = 1:2 % numel(optionsFile.model.space) have to fix prc_idx for RW model (and eventually VK model)
%         for j = 1:length(optionsFile.task.MouseID)
%             PostObsParam = simResp.agent(iAgent,m_in).task(iTask).data.p_obs.ptrans(optionsFile.modelSpace.obs_idx);   % Plot single free param in observation model
%             fig = plot(xAxis(j),PostObsParam,'Marker','o','Color','b');
%             hold on
%         end
%         yline(simResp.agent(iAgent,m_in).task(iTask).data.c_obs.priormus(optionsFile.modelSpace.obs_idx),'Color','r');
%         % title(fig,['simulated observational parameters',num2str(p)]);
%         figDir = fullfile([char(optionsFile.paths.plotsDir),filesep,'model',num2str(m),'_simAgents_obs_param',num2str(p)]);
%         save([figDir,'.fig']);
%         print([figDir,'.png'], '-dpng');
%         close all;
%     end
% end
%% SAVE results as struct
res.rec = rec;
save_path = fullfile(optionsFile.paths.plotsDir,filesep,'sim_and_realData.mat');
save(save_path, '-struct', 'res');

disp('recovery analysis complete.')

end
