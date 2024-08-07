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


% in the future this should happen in the getData function


%% LOAD results from model inversion
for n = 1:length(optionsFile.Task.MouseID)
    currMouse = optionsFile.Task.MouseID(n);
    for m_in = 1:size(optionsFile.model.space, 2)

        fprintf('current iteration: n=%1.0f, m=%1.0f \n', n,m_in);
        for m_est = 1:size(optionsFile.model.space, 2)

            % load results from real data model inversion
            rec.est(m_in,n,m_est).data = load(fullfile([char(optionsFile.paths.resultsDir),'\mouse',num2str(currMouse),optionsFile.fileName.rawFile,'.mat']));
        end

        % param values in transformed space (assumption of Gaussian prior)
        rec.param.prc(m_in).est(n,:) = rec.est(m_in,n,m_in).data.eHGFFit.p_prc.ptrans(optionsFile.modelSpace(m_in).prc_idx);
        rec.param.obs(m_in).est(n,:) = rec.est(m_in,n,m_in).data.eHGFFit.p_obs.ptrans(optionsFile.modelSpace(m_in).obs_idx);
    end
end

% simulated agents
for i = 1:optionsFile.simulations.nSamples
    for m_in = 1:size(optionsFile.model.space, 2)

        fprintf('current iteration: n=%1.0f, m=%1.0f \n', i,m_in);
        for m_est = 1:size(optionsFile.model.space, 2)

            % load results from simulated agents' model inversion
            rec.sim.agent(i,m_in).data = load(fullfile(optionsFile.simulations.simResultsDir, ...
                [optionsFile.Task.task,'simulation_agent', num2str(i),'model_in',num2str(m_in),'_model_est',num2str(m_est),'.mat']));
        end
    end

    rec.param.prc(m_in).sim(i,:) = rec.sim.agent(i,m_in).data.p_prc.ptrans(optionsFile.modelSpace(m_in).prc_idx);
    rec.param.obs(m_in).sim(i,:) = rec.sim.agent(i,m_in).data.p_obs.ptrans(optionsFile.modelSpace(m_in).obs_idx);
end

%% CALCULATE Pearson's Correlation Coefficient (pcc)
% 
% for m_in = 1:size(optionsFile.model.space, 2)
%     rec.param.prc(m_in).pcc = diag(corr(rec.param.prc(m_in).sim, rec.param.prc(m_in).est));
%     rec.param.obs(m_in).pcc = diag(corr(rec.param.obs(m_in).sim, rec.param.obs(m_in).est));
% end

%% Plot est mice (X axis are mice/sim) Yaxis=values;
%Plot free perceptual model parameters
xAxis = 1:length(optionsFile.Task.MouseID);

for p = 1:length(optionsFile.modelSpace.prc_idx)   % Plot both free params in perceptual model
    for n = 1:length(optionsFile.Task.MouseID)
        PostPerceptParam = rec.est(n).data.eHGFFit.p_prc.ptrans(optionsFile.modelSpace.prc_idx(p));
        fig = plot(xAxis(n),PostPerceptParam,'Marker', 'o','Color','b');
        hold on
        fig = plot(xAxis(n),rec.est(n).data.eHGFFit.c_prc.priormus,'Marker', 'o','Color','r');
        hold on
        %line using this values rec.est(k).data.eHGFFit.c_prc.priormus
        hold on
    end
    figdir = fullfile([char(optionsFile.paths.plotsDir),'\RealMicePercModelFreeParam',num2str(p)]);
    save([figdir,'.fig']);
    print([figdir,'.png'], '-dpng');
    close all;
end


%Plot free observational model parameters
for j = 1:optionsFile.Task.nSize
    PostObsParam = rec.est(j).data.eHGFFit.p_obs.ptrans(optionsFile.modelSpace.obs_idx);   % Plot single free param in observation model
    figObsParam = plot(xAxis(j),PostObsParam,'Marker','o','Color','b');
    hold on
end

fig2dir = fullfile([char(optionsFile.paths.plotsDir),'\RealMiceObsModelFreeParam',num2str(p)]);
save([fig2dir,'.fig']);
print([fig2dir,'.png'], '-dpng');
close all;

%% Plot simAgent's Perceptual & Observational Free Parameter values
%Plot free perceptual model parameters
xAxis = 1:optionsFile.simulations.nSamples;

for p = 1:length(optionsFile.modelSpace.prc_idx)   % Plot both free params in perceptual model
    for n = 1:optionsFile.simulations.nSamples
        PostPerceptParam = rec.sim.agent(n).data.p_prc.ptrans(optionsFile.modelSpace.prc_idx(p));
        simFig = plot(xAxis(n),PostPerceptParam,'Marker', 'o','Color','b');
        hold on
        simFig = plot(xAxis(n),rec.est(1).data.eHGFFit.c_prc.priormus, 'Marker', '.', 'Color', 'r')
        
    end
    %simFig = plot([rec.est(1).data.eHGFFit.c_prc.priormus], '--')
    fig3dir = fullfile([char(optionsFile.paths.plotsDir),'\simAgentsPercModelFreeParam',num2str(p)]);
    
    save([fig3dir,'.fig']);
    print([fig3dir,'.png'], '-dpng');
    close all;
end


%Plot free observational model parameters
for j = 1:optionsFile.simulations.nSamples;
    PostObsParam = rec.sim.agent(j).data.p_obs.ptrans(optionsFile.modelSpace.obs_idx);   % Plot single free param in observation model
    simFigObsParam = plot(xAxis(j),PostObsParam,'Marker','o','Color','b');
    hold on
end

fig4dir = fullfile([char(optionsFile.paths.plotsDir),'\simAgentsObsModelFreeParam',num2str(p)]);
save([fig4dir,'.fig']);
print([fig4dir,'.png'], '-dpng');
close all;


%% PLOT correlation plot
for m_in = 1:size(optionsFile.model.space, 2)
    t = tiledlayout('flow');
    figure('Color',[1,1,1],'pos',[10 10 1050 500]);

    for p = 1:size(rec.param.prc(m_in).sim,2)
        nexttile;
        scatter(rec.param.prc(m_in).sim(:,p),rec.param.prc(m_in).est(:,p),'filled');
        %refline(1,0);
        ylim([(min(rec.param.prc(m_in).est(:,p))-0.1) (max(rec.param.prc(m_in).est(:,p))+0.1)]);
        [t,s] = title([optionsFile.model.space(m_in),optionsFile.modelSpace.free_expnms_mu_prc(p),'rho = ' num2str(rec.param.prc(m_in).pcc(p))]);
        t.FontSize = 18;
        s.FontSize = 14;
        s.FontAngle = 'italic'; hold on;
        xlabel('simulated data')
        ylabel('estimated data')
        hold on;
    end

    for p2Obs = 1:size(rec.param.obs(m_in).sim,2)
        nexttile;
        scatter(rec.param.obs(m_in).sim(:,p2Obs),rec.param.obs(m_in).est(:,p2Obs),'filled');
        % refline(1,0);
        ylim([(min(rec.param.obs(m_in).est(:,p2Obs))-0.1) (max(rec.param.obs(m_in).est(:,p2Obs))+0.1)]);
        [t,s] = title([optionsFile.model.space(m_in),optionsFile.modelSpace.free_expnms_mu_obs(p2Obs),'rho = ' num2str(rec.param.obs(m_in).pcc(p2Obs))]);
        t.FontSize = 18;
        s.FontSize = 14;
        s.FontAngle = 'italic';
        hold on;
        xlabel('simulated data')
        ylabel('estimated data')
        hold on;
    end
    %
    %         for
    %             plot(rec.param.obs.sim,'.');
    %             yline(mean_corr_T1,'Color',[1.0000 0.5529 0.1608]);
    %             hold on
    %             ylim([0.3 0.8]) % soft code!
    %             %if simP.includeOutliers
    %             %hold on
    %             plot(outlierIdx_T1,RQ01_correctness_dataTable.correctness_Traj1(outlierIdx_T1),'o','Color',[1.0000 0.5529 0.1608]);
    %         end


    sgtitle([optionsFile.modelSpace(m_in).name], 'FontSize', 18);
    figdir = fullfile([optionsFile.paths.plotsDir, ...
        '/Parameter_recovery_',optionsFile.modelSpace(m_in).name]);
    print(figdir, '-dpng');

    save([figdir,'.fig'])
end

%% SAVE results as struct
res.rec = rec;

save_path = fullfile(optionsFile.paths.plotsDir,'\sim_and_realData.mat');
save(save_path, '-struct', 'res');

disp('recovery analysis complete.')
end


