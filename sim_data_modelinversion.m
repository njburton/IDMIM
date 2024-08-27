function [] = sim_data_modelinversion()

%% WBEST_sim_data_modinv
%  Invert simulated agents with models in the modelspace. This step will be
%  executed if simP.doSimulations = 1;
%
%   SYNTAX:       WBEST_sim_data_modinv()
%
% Original: 29-10-2021; Alex Hess
% Amended:  30-11-2021; Sandra Iglesias
% Amended:  30-05-2023; Katharina V. Wellstein

% -------------------------------------------------------------------------
% Copyright (C) 2023 TNU, Institute for Biomedical Engineering, University of Zurich and ETH Zurich.
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
try
    load('optionsFile.mat');
catch
    optionsFile = runOptions; % specifications for this analysis
end


disp('************************************** SIM_DATA_MODELINVERSION **************************************');
disp('*');
disp('*');

% simulation setup
sim = load(fullfile([optionsFile.simulations.simResultsDir,'/sim.mat']));

for n = 1:optionsFile.simulations.nSamples
    for m_in = 1:numel(optionsFile.model.space)
        for m_est = 1:numel(optionsFile.model.space)

            %% MODEL INVERSION
            disp(['Model inversion for agent: ', num2str(n), ' | gen model ', optionsFile.modelSpace(m_in).name, ' | fitting model: ', optionsFile.modelSpace(m_est).name]);

            est = tapas_fitModel(sim.agent(n,m_in).data.y,...    % responses
                sim.agent(n,m_in).data.u,...                     % input sequence
                optionsFile.modelSpace(m_est).prc_config,...         % Prc fitting model
                optionsFile.modelSpace(m_est).obs_config,...         % Obs fitting model
                optionsFile.hgf.opt_config,...                       % Optimization algorithm
                0,...                                            % 0 = MAP estimation
                optionsFile.rng.settings.State(optionsFile.rng.idx, 1)); % seed for multistart


            %% SAVE model fit as struct
           save_path = fullfile(char(optionsFile.simulations.simResultsDir),...
                ['\',char(optionsFile.model.space(m)),'_simAgent_', num2str(n),'_model_in',num2str(m_in),'_model_est',num2str(m_est),'.mat']);
            save(save_path, '-struct', 'est');

        end
    end
end

end