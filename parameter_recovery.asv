function [] = parameter_recovery(optionsFile)

%% parameter_recovery
%  Parameter recovery analysis based on simulations. This step will be
%  executed if simP.doSimulations = 1;
%
%   SYNTAX:       parameter_recovery(optionsFile)
%
%   IN:      optionsFile: struct, contains specifications needed for this analysis
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

try
    load('optionsFile.mat');
catch
    optionsFile = runOptions; % specifications for this analysis
end

disp('************************************** PARAMETER RECOVERY **************************************');
disp('*');
disp('*');

%% LOAD results from model inversion
for n = 1:length(optionsFile.Task.MouseID)
    currMouse = optionsFile.Task.MouseID(n);
    for m_in = 1:size(optionsFile.model.space, 2) %For each model in our model space (",2" meaning by the 2nd dimension?
        %but found only have 1 index in that vector, "RW_binary
        fprintf('current iteration: n=%1.0f, m=%1.0f \n', n,m_in);
        for m_est = 1:size(optionsFile.model.space, 2)

            % load results from real data model inversion
            rec.est(m_in,n,m_est).data = load(fullfile([char(optionsFile.paths.resultsDir),filesep,'mouse',num2str(currMouse),'_',optionsFile.fileName.rawFitFile{m_in},'.mat']));
        end

        % param values in transformed space (assumption of Gaussian prior)
        rec.param.prc(m_in).est(n,:) = rec.est(m_in,n,m_in).data.est.p_prc.ptrans(optionsFile.modelSpace(m_in).prc_idx);
        rec.param.obs(m_in).est(n,:) = rec.est(m_in,n,m_in).data.est.p_obs.ptrans(optionsFile.modelSpace(m_in).obs_idx);
    end
end

% simulated agents
for i = 1:length(optionsFile.Task.MouseID)
    for m_in = 1:size(optionsFile.model.space, 2)
        fprintf('current iteration: n=%1.0f, m=%1.0f \n', i,m_in);
        for m_est = 1:size(optionsFile.model.space, 2)

            % load results from simulated agents' model inversion
            rec.sim.agent(i,m_in).data = load(fullfile(optionsFile.simulations.simResultsDir, ...
                [optionsFile.model.space{m_in},'_simAgent_', num2str(i),'_model_in',num2str(m_in),'_model_est',num2str(m_in),'.mat']));
        end

        rec.param.prc(m_in).sim(i,:) = rec.sim.agent(i,m_in).data.p_prc.ptrans(optionsFile.modelSpace(m_in).prc_idx);
        rec.param.obs(m_in).sim(i,:) = rec.sim.agent(i,m_in).data.p_obs.ptrans(optionsFile.modelSpace(m_in).obs_idx);
    end
end

%% CALCULATE Pearson's Correlation Coefficient (pcc)
for m = 1:numel(optionsFile.model.space)
    for p = 1:length(optionsFile.modelSpace(m).prc_idx)

        % prc model
        [prc_coef, prc_p] = corr(rec.param.prc(m).sim(:,p), rec.param.prc(m).est(:,p));
        rec.param.prc(m).pcc(p)  = diag(prc_coef);
        rec.param.prc(m).pval(p) = diag(prc_p);
    end
end

for m = 1:numel(optionsFile.model.space)
    for p = 1:length(optionsFile.modelSpace(m).obs_idx)
        % obs model
        [obs_coef, obs_p] = corr(rec.param.obs(m_in).sim(:,p), rec.param.obs(m_in).est(:,p));
        rec.param.obs(m).pcc(p)  = diag(obs_coef);
        rec.param.obs(m).pval(p) = diag(obs_p);
    end
end
%% Plot est mice (X axis are mice/sim) Yaxis=values;
%Plot free perceptual model parameters
xAxis = 1:length(optionsFile.Task.MouseID);

for m = 1:numel(optionsFile.model.space)
for p = 1:length(optionsFile.modelSpace(m).prc_idx)   % Plot both free params in perceptual model
    for n = 1:length(optionsFile.Task.MouseID)
        PostPerceptParam = rec.est(m,n,m).data.est.p_prc.ptrans(optionsFile.modelSpace(m).prc_idx(p));
        fig = plot(xAxis(n),PostPerceptParam,'Marker', 'o','Color','b'); %ylim([-5.0, 5.0]);
        hold on

    end %TO DO, check if this type of indexing works here
    yline(rec.est(m,n,m).data.est.c_prc.priormus(optionsFile.modelSpace(m).prc_idx),'Color','r');
    %     title(fig,['mice perceptual parameters',num2str(p)]);
    figDir = fullfile([char(optionsFile.paths.plotsDir),filesep,'mice_prc_param',num2str(p)]);
    save([figDir,'.fig']);
    print([figDir,'.png'], '-dpng');
    close all;
    %remove first yline
end


%Plot free observational model parameters
for j = 1:optionsFile.Task.nSize
    PostObsParam = rec.est(m,j,m).data.est.p_obs.ptrans(optionsFile.modelSpace(m).obs_idx);   % Plot single free param in observation model
    fig = plot(xAxis(j),PostObsParam,'Marker','o','Color','b');
    hold on

end
%TO DO, check if this type of indexing works here
yline(rec.est(m,n,m).data.est.c_obs.priormus(optionsFile.modelSpace(m).obs_idx),'Color','r');
% title(fig,['mice observational parameters',num2str(p)]);
figDir = fullfile([char(optionsFile.paths.plotsDir),filesep,'mice_obs_param',num2str(p)]);
save([figDir,'.fig']);
print([figDir,'.png'], '-dpng');
close all;
end

%% Plot simAgent's Perceptual & Observational Free Parameter values
%Plot free perceptual model parameters
xAxis = 1:length(optionsFile.Task.MouseID);

for p = 1:length(optionsFile.modelSpace.prc_idx)   % Plot both free params in perceptual model
    for n = 1:length(optionsFile.Task.MouseID)
        PostPerceptParam = rec.sim.agent(m,n,m).data.p_prc.ptrans(optionsFile.modelSpace(m).prc_idx(p));
        fig = plot(xAxis(n),PostPerceptParam,'Marker', 'o','Color','b');
        hold on
    end
    %TO DO, check if this type of indexing works here
    yline(rec.sim.agent(n).data.c_prc.priormus(optionsFile.modelSpace.prc_idx),'Color','r');
    %     title(fig,['simulated observational parameters',num2str(p)]);
    figDir = fullfile([char(optionsFile.paths.plotsDir),filesep,'simAgents_prc_param',num2str(p)]);
    save([figDir,'.fig']);
    print([figDir,'.png'], '-dpng');
    close all;
end


%Plot free observational model parameters
for j = 1:length(optionsFile.Task.MouseID)
    PostObsParam = rec.sim.agent(j).data.p_obs.ptrans(optionsFile.modelSpace.obs_idx);   % Plot single free param in observation model
    fig = plot(xAxis(j),PostObsParam,'Marker','o','Color','b');
    hold on
end
%TO DO, check if this type of indexing works here
yline(rec.sim.agent(n).data.c_obs.priormus(optionsFile.modelSpace.obs_idx),'Color','r');
% title(fig,['simulated observational parameters',num2str(p)]);
figDir = fullfile([char(optionsFile.paths.plotsDir),filesep,'simAgents_obs_param',num2str(p)]);
save([figDir,'.fig']);
print([figDir,'.png'], '-dpng');
close all;


%% PLOT correlation plot
for m_in = 1:size(optionsFile.model.space, 2)
    t = tiledlayout('flow');
    figure('Color',[1,1,1],'pos',[10 10 1050 500]);

    for pPrc = 1:size(rec.param.prc(m_in).sim,2)
        nexttile;
        scatter(rec.param.prc(m_in).sim(:,pPrc),rec.param.prc(m_in).est(:,pPrc),'filled');
        refline(1,0);
        %         ylim([(min(rec.param.prc(m_in).est(:,pPrc))-0.1) (max(rec.param.prc(m_in).est(:,p))+0.1)]);
        [t,s] = title([optionsFile.model.space(m_in),optionsFile.modelSpace.free_expnms_mu_prc(pPrc),'rho = ' num2str(rec.param.prc(m_in).pcc(pPrc))]);
        t.FontSize = 18;
        s.FontSize = 14;
        s.FontAngle = 'italic'; hold on;
        xlabel('simulated data')
        ylabel('estimated data')
        hold on;
    end

    for pObs = 1:size(rec.param.obs(m_in).sim,2)
        nexttile;
        scatter(rec.param.obs(m_in).sim(:,pObs),rec.param.obs(m_in).est(:,pObs),'filled');
        % refline(1,0);
        %         ylim([(min(rec.param.obs(m_in).est(:,pObs))-0.1) (max(rec.param.obs(m_in).est(:,pObs))+0.1)]);
        [t,s] = title([optionsFile.model.space(m_in),optionsFile.modelSpace.free_expnms_mu_obs(pObs),'rho = ' num2str(rec.param.obs(m_in).pcc(pObs))]);
        t.FontSize = 18;
        s.FontSize = 14;
        s.FontAngle = 'italic';
        hold on;
        xlabel('simulated data')
        ylabel('estimated data')
        hold on;
    end

    sgtitle([optionsFile.modelSpace(m_in).name], 'FontSize', 18);
    figDir = fullfile([optionsFile.paths.plotsDir, ...
        filesep,'Parameter_recovery_',optionsFile.modelSpace(m_in).name]);
    print(figDir, '-dpng');

    save([figDir,'.fig'])
end

%% SAVE results as struct
res.rec = rec;

save_path = fullfile(optionsFile.paths.plotsDir,filesep,'sim_and_realData.mat');
save(save_path, '-struct', 'res');

disp('recovery analysis complete.')
end


