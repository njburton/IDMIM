function [] = sim_data_modelinversion()

%% sim_data_modelinversion
%  Invert simulated agents with models in the modelspace. This step will be
%  executed if optionsFIle.doSimulations = 1;
%
%   SYNTAX:       sim_data_modinv()
%
% Original: 29-10-2021; Alex Hess
% Amended:  30-11-2021; Sandra Iglesias
% Amended:  30-05-2023; Katharina V. Wellstein
%       and 11-11-2024; for Nicholas Burton
% -------------------------------------------------------------------------
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
% specifications for this analysis
if exist('optionsFile.mat','file')==2
    load("optionsFile.mat");
else
    optionsFile = runOptions();
end

disp('************************************** SIM_DATA_MODELINVERSION **************************************');
disp('*');
disp('*');
strct              = optionsFile.hgf.opt_config;
strct.maxStep      = inf;
strct.nRandInit    = optionsFile.rng.nRandInit;
strct.seedRandInit = optionsFile.rng.settings.State(optionsFile.rng.idx, 1);

for iTask = 1:numel(optionsFile.task.testTask)
    for iSample = 1:optionsFile.simulations.nSamples
        for m_in = 1:numel(optionsFile.model.space)

            sim = load(fullfile([optionsFile.simulations.simResultsDir,filesep,optionsFile.model.space{m_in},optionsFile.task.testTask(iTask).name,'_sim']));
            for m_est = 1:2 %1:numel(optionsFile.model.space)

                if m_est == 3
                    strct.maxStep  = 100;
                end
                %%  MODEL INVERSION
                disp(['Model inversion for agent: ', num2str(iSample), ' | gen model ', optionsFile.modelSpace(m_in).name, ' | fitting model: ', optionsFile.modelSpace(m_est).name]);
                est = tapas_fitModel(sim.agent(iSample,m_in).task(iTask).data.y,... % responses
                    optionsFile.task.testTask(iTask).inputs,...                  % input sequence
                    optionsFile.modelSpace(m_est,iTask).prc_config,...         % Prc fitting model
                    optionsFile.modelSpace(m_est,iTask).obs_config,...         % Obs fitting model
                    strct); % seed for multistart

                %% SAVE model fit as struct
                save_path = fullfile(char(optionsFile.simulations.simResultsDir),...
                    [filesep,char(optionsFile.model.space{m_in}),'_simAgent_', num2str(iSample),'_model_in',num2str(m_in),'_model_est',num2str(m_est),'_task_',optionsFile.task.testTask(iTask).name,'.mat']);
                save(save_path, '-struct', 'est');

            end
        end
    end
end

end