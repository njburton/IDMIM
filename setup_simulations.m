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
% specifications for this analysis
load("optionsFile.mat"); % specifications for this analysis

addpath(genpath(optionsFile.paths.HGFtoolboxDir));
disp('************************************** SETUP_SIMULATIONS **************************************');
disp('*');
disp('*');

%% Add in input sequence that has been generated
%Save input seq as variable in workspace so that I can subsititute it in
%the code when running this funcition
%newInputs = xlsread('C:\Users\c3200098\Desktop\ImprovedInputSequence.csv');

%% GENERATE synthetic agents using default priors from toolbox
sim.agent  = struct();
input      = struct();

for modeli = 1:length(optionsFile.model.space)
    for agenti = 1:optionsFile.simulations.nSamples
        % sample free parameter values
        input.prc.transInp = optionsFile.model.prc_config(modeli).priormus;
        input.obs.transInp = optionsFile.model.obs_config(modeli).priormus;

        for percParamIdx = 1:size(optionsFile.model.space(modeli).prc_idx,2)
            input.prc.transInp(optionsFile.modelSpace(modeli).prc_idx(percParamIdx)) = ...
                normrnd(optionsFile.model.prc_config(modeli).priormus(optionsFile.model(modeli).prc_idx(percParamIdx)),...
                abs(sqrt(optionsFile.model.prc_config(modeli).priorsas(optionsFile.model(modeli).prc_idx(percParamIdx)))));
        end
        for obsParamIdx = 1:size(optionsFile.model.space(modeli).obs_idx,2)
            input.obs.transInp(optionsFile.model.space(modeli).obs_idx(obsParamIdx)) = ...
                normrnd(optionsFile.model.obs_config.priormus(optionsFile.model(modeli).obs_idx(obsParamIdx)),...
                abs(sqrt(optionsFile.model.obs_config.priorsas(optionsFile.model(modeli).obs_idx(obsParamIdx)))));
        end

        % create simulation input vectors (native space)
        c.c_prc = optionsFile.model.prc_config(modeli);
        input.prc.nativeInp = optionsFile.model.prc_config(modeli).transp_prc_fun(c, input.prc.transInp);
        c.c_obs = optionsFile.model.obs_config;
        input.obs.nativeInp = optionsFile.model.obs_config.transp_obs_fun(c, input.obs.transInp);

        % simulate predictions for SNR calculation
        stable = 0;

        while stable == 0
            try %tapas_simModel(inputs, prc_model, prc_pvec, varargin)
                sim_est = tapas_simModel(optionsFile.task.inputs,...   %change to inputs if trialing different binSequences
                    optionsFile.modelSpace(modeli).prc,...
                    input.prc.nativeInp,...
                    optionsFile.modelSpace(modeli).obs,...
                    input.obs.nativeInp,...
                    optionsFile.rng.settings.State(optionsFile.rng.idx, 1));
                stable = 1;


            catch
                fprintf('simulation failed for synth. agent %1.0f \n',agenti);
            end

            % save simulation input
            sim.agent(agenti,modeli).data = sim_est;

            % Update the rng state idx
            optionsFile.rng.idx    = optionsFile.rng.idx+1;
            if optionsFile.rng.idx == (length(optionsFile.rng.settings.State)+1)
                optionsFile.rng.idx = 1;
            end
        end
    end
end

%% PLOT predictions

for modeli = 2:numel(optionsFile.model.space)
for agenti = 1:optionsFile.simulations.nSamples

   if any(strcmp('muhat',fieldnames(sim.agent(agenti,m).data.traj)))
    plot(sim.agent(agenti,modeli).data.traj.muhat(:,1), 'color', optionsFile.col.tnub);
    ylabel('$\hat{\mu}_{1}$', 'Interpreter', 'Latex')
   else
    plot(sim.agent(agenti,modeli).data.traj.vhat(:,1), 'color', optionsFile.col.tnub);
    ylabel('v_hat')
   end

    hold on;
end

%Create figure of trajectory 
ylim([-0.1 1.1])
plot(sim.agent(1).data.u,'o','Color','b');
plot(optionsFile.task.probStr,'Color','b');
xlabel('Trials');
ylabel('Reward Probability (%)');
txt = ['Simulation results (n=50) using ', optionsFile.model.prc{m}];
title(txt)
hold on
set(gcf, 'color', 'none');   %transparent background
set(gca, 'color', 'none');   %transparent background
xticks([0 40 80 120 160 200 240 280])
hold on;

figdir = fullfile([char(optionsFile.simulations.simResultsDir),filesep,optionsFile.model.space{m},'_predictions']);
save([figdir,'.fig'])
print(figdir, '-dpng');
close;

% reset rng state idx
optionsFile.rng.idx = 1;

%% SAVE model simulation specs as struct
save([optionsFile.simulations.simResultsDir,filesep,optionsFile.model.space{m},'_sim'], '-struct', 'sim');

disp('simulated data successfully created.')
end

end