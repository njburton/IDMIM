function [] = setup_simulations

%% WBEST_setup_simulations
%  Simulat synthetic agents using priors determined from pilot dataset
%
%   SYNTAX:       WBEST_setup_simulations
%
% Original: Katharina V. Wellstein
% Amended
% -------------------------------------------------------------------------
% Copyright (C) 2024, Katharina V. Wellstein
%
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
% options = set_options;   % specifications for this analysis
optionsFile = runOptions; % specifications for this analysis

addpath(genpath(optionsFile.paths.toolbox));
disp('************************************** SETUP_SIMULATIONS **************************************');
disp('*');
disp('*');

%% GENERATE synthetic agents using default priors from toolbox
sim.agent  = struct();
input      = struct();

for m = 1:numel(optionsFile.model.space)

    for n = 1:optionsFile.simulations.nSamples

        % sample free parameter values
        input.prc.transInp = optionsFile.modelSpace(m).prc_config.priormus;
        input.obs.transInp = optionsFile.modelSpace(m).obs_config.priormus;

        for j = 1:size(optionsFile.modelSpace(m).prc_idx,2)
            input.prc.transInp(optionsFile.modelSpace(m).prc_idx(j)) = ...
                normrnd(optionsFile.modelSpace(m).prc_config.priormus(optionsFile.modelSpace(m).prc_idx(j)),...
                abs(sqrt(optionsFile.modelSpace(m).prc_config.priorsas(optionsFile.modelSpace(m).prc_idx(j)))));
        end
        for k = 1:size(optionsFile.modelSpace(m).obs_idx,2)
            input.obs.transInp(optionsFile.modelSpace(m).obs_idx(k)) = ...
                normrnd(optionsFile.modelSpace(m).obs_config.priormus(optionsFile.modelSpace(m).obs_idx(k)),...
                abs(sqrt(optionsFile.modelSpace(m).obs_config.priorsas(optionsFile.modelSpace(m).obs_idx(k)))));
        end

        % create simulation input vectors (native space)
        c.c_prc = optionsFile.modelSpace(m).prc_config;
        input.prc.nativeInp = optionsFile.modelSpace(m).prc_config.transp_prc_fun(c, input.prc.transInp);
        c.c_obs = optionsFile.modelSpace(m).obs_config;
        input.obs.nativeInp = optionsFile.modelSpace(m).obs_config.transp_obs_fun(c, input.obs.transInp);

        % simulate predictions for SNR calculation
        stable = 0;

        while stable == 0
            try %tapas_simModel(inputs, prc_model, prc_pvec, varargin)
                sim_est = tapas_simModel(optionsFile.Task.seqABALeftLever,...
                    optionsFile.modelSpace(m).prc,...
                    input.prc.nativeInp,...
                    optionsFile.modelSpace(m).obs,...
                    input.obs.nativeInp,...
                    optionsFile.rng.settings.State(optionsFile.rng.idx, 1));
                stable = 1;

                
            catch
                fprintf('simulation failed for synth. agent %1.0f \n',n);
            end

            % save simulation input
            sim.agent(n,m).data = sim_est;

            % Update the rng state idx
            optionsFile.rng.idx    = optionsFile.rng.idx+1;
            if optionsFile.rng.idx == (length(optionsFile.rng.settings.State)+1)
                optionsFile.rng.idx = 1;
            end
        end

    end
end

%% PLOT predictions

for n = 1:optionsFile.simulations.nSamples
    any(strcmp('muhat',fieldnames(sim.agent(1).data.traj)));
    plot(sim.agent(n).data.traj.muhat(:,1), 'color', optionsFile.col.tnub) % check other synethc agents traj's
    ylabel('$\hat{\mu}_{1}$', 'Interpreter', 'Latex')
    hold on;
end

ylim([-0.1 1.1])
plot(sim.agent(1).data.u,'o','Color','b');
%plot(optionsFile.task.probStr,'Color','b');
xlabel('trials')
txt = ['model: ', optionsFile.model.prc];
title(txt)

figdir = fullfile([optionsFile.simulations.simResultsDir,'/predictions']);
save([figdir,'.fig'])
print(figdir, '-dpng');
close;

% reset rng state idx
optionsFile.rng.idx = 1;

%% SAVE model simulation specs as struct
save([optionsFile.simulations.simResultsDir,'/sim'], '-struct', 'sim');

disp('simulated data successfully created.')

end