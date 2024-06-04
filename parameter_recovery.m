function [] = parameter_recovery(optionsFile)

%% WBEST_recovery_analysis
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

% if ~exist(optionsFile)
%     optionsFile = runOptions; % specifications for this analysis
% end

disp('************************************** PARAMETER RECOVERY **************************************');
disp('*');
disp('*');


%% LOAD results from model inversion

for n = 1:optionsFile.Task.nSize

    if ~isnan(optionsFile.Task.MouseID(n))
        currMouse = optionsFile.Task.MouseID(n);

        for m_in = 1:size(optionsFile.model.space, 2)

            fprintf('current iteration: n=%1.0f, m=%1.0f \n', n,m_in);
            for m_est = 1:size(optionsFile.model.space, 2)
                % load results from simulated agents' model inversion
                rec.sim.agent(n,m_in).data = fullfile(optionsFile.simulations.simResultsDir, ...
                    [optionsFile.Task.task1,'simulation_agent', num2str(n),'model_in',num2str(m_in),'_model_est',num2str(m_est),'.mat']);

                % load results from real data model inversion
                rec.est(m_in,n,m_est).data = load(fullfile([char(optionsFile.paths.resultsDir),'\mouse',num2Str(currMouse),'HGFFitABA1.mat']));
            end

            % param values in transformed space (assumption of Gaussian prior)
            rec.param.prc(m_in).sim(n,:) = res.sim.agent(n,m_in).input.prc.transInp(optionsFile.modelSpace(m_in).prc_idx);
            rec.param.obs(m_in).sim(n,:) = res.sim.agent(n,m_in).input.obs.transInp(optionsFile.modelSpace(m_in).obs_idx);
            rec.param.prc(m_in).est(n,:) = rec.est(m_in,n,m_in).data.p_prc.ptrans(optionsFile.modelSpace(m_in).prc_idx);
            rec.param.obs(m_in).est(n,:) = rec.est(m_in,n,m_in).data.p_obs.ptrans(optionsFile.modelSpace(m_in).obs_idx);
        end
    else
        disp('skipped...invalid mouse');
    end


%% CALCULATE Pearson's Correlation Coefficient (pcc)

    for m_in = 1:size(optionsFile.model.space, 2)
        rec.param.prc(m_in).pcc = diag(corr(rec.param.prc(m_in).sim, rec.param.prc(m_in).est));
        rec.param.obs(m_in).pcc = diag(corr(rec.param.obs(m_in).sim, rec.param.obs(m_in).est));
    end


%% PLOT correlation plot

    for m_in = 1:size(optionsFile.model.space, 2)
        t = tiledlayout('flow');
        figure('Color',[1,1,1],'pos',[10 10 1050 500]);

        for p = 1:size(rec.param.prc(m_in).sim,2)
            nexttile;
            scatter(rec.param.prc(m_in).sim(:,p),rec.param.prc(m_in).est(:,p),'filled');
            refline(1,0);
            ylim([(min(rec.param.prc(m_in).est(:,p))-0.1) (max(rec.param.prc(m_in).est(:,p))+0.1)]);
            [t,s] = title(res.main.ModSpace(m_in).free_expnms_mu_prc(p),{'rho = ' rec.param.prc(m_in).pcc(p)});
            t.FontSize = 18;
            s.FontSize = 14;
            s.FontAngle = 'italic'; hold on;
            xlabel('simulated data')
            ylabel('estimated data')
            hold on;
        end

        for p2 = 1:size(rec.param.obs(m_in).sim,2)
            nexttile;
            scatter(rec.param.obs(m_in).sim(:,p2),rec.param.obs(m_in).est(:,p2),'filled');
            refline(1,0);
            ylim([(min(rec.param.obs(m_in).est(:,p2))-0.1) (max(rec.param.obs(m_in).est(:,p2))+0.1)]);
            [t,s] = title(res.main.ModSpace(m_in).free_expnms_mu_obs(p2),{'rho = ' rec.param.obs(m_in).pcc(p2)});
            t.FontSize = 18;
            s.FontSize = 14;
            s.FontAngle = 'italic';
            hold on;
            xlabel('simulated data')
            ylabel('estimated data')
            hold on;
        end

        sgtitle([optionsFile.modelSpace(m_in).name], 'FontSize', 18);
        figdir = fullfile([optionsFile.paths.plotsDir, ...
            '/Parameter_recovery_',optionsFile.modelSpace(m_in).name]);
        print(figdir, '-dpng');
    end

    %% SAVE results as struct
    res.rec = rec;

    save_path = fullfile(optionsFile.paths.plotsDir,'\sim_and_realData.mat');
    save(save_path, '-struct', 'res');

    disp('recovery analysis complete.')

end