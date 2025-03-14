function [] = sim_data_modelinversion(cohortNo)

%% sim_data_modelinversion
%  Invert simulated agents with models in the modelspace. This step will be
%  executed if optionsFile.doSimulations = 1;
%
%   SYNTAX:       sim_data_modinversion
%
%   IN: cohortNo:  integer, cohort number, see optionsFile for what cohort
%                            corresponds to what number in the
%                            optionsFile.cohort(cohortNo).name struct. This
%                            allows to run the pipeline and its functions for different
%                            cohorts whose expcifications have been set in runOptions.m
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

optionsFile = setup_configFiles(optionsFile,cohortNo);

disp('************************************** SIM_DATA_MODELINVERSION **************************************');
disp('*');
disp('*');

strct              = optionsFile.hgf.opt_config;
strct.maxStep      = inf;
strct.nRandInit    = optionsFile.rng.nRandInit;
strct.seedRandInit = optionsFile.rng.settings.State(optionsFile.rng.idx, 1);

for iTask = 1:numel(optionsFile.cohort(cohortNo).testTask)
    for iSample = 1:optionsFile.simulations.nSamples
        for m_in = 1:numel(optionsFile.model.space)
            sim = load(fullfile([optionsFile.paths.cohort(cohortNo).simulations,optionsFile.model.space{m_in},optionsFile.cohort(cohortNo).testTask(iTask).name,'_sim']));

            for m_est = 1:numel(optionsFile.model.space)

                if m_est == 3 && m_in ==3
                    strct.maxStep  = 100;
                end

                %%  MODEL INVERSION
                disp(['Model inversion for agent: ', num2str(iSample), ' | gen model ', optionsFile.modelSpace(m_in).name, ' | fitting model: ', optionsFile.modelSpace(m_est).name]);
                est = tapas_fitModel(sim.agent(iSample,m_in).task(iTask).data.y,... % responses
                    optionsFile.cohort(cohortNo).testTask(iTask).inputs,...                  % input sequence
                    optionsFile.modelSpace(m_est,iTask).prc_config,...         % Prc fitting model
                    optionsFile.modelSpace(m_est,iTask).obs_config,...         % Obs fitting model
                    strct); % seed for multistart


                %Plot standard trajectory plot
                optionsFile.plot(m_est).plot_fits(est);
                figdir = fullfile([char(optionsFile.paths.cohort(cohortNo).simPlots),...
                'simAgent_', num2str(iSample),'_model_in_',optionsFile.dataFiles.rawFitFile{m_in},...
                '_model_est_',optionsFile.dataFiles.rawFitFile{m_est},'_',optionsFile.cohort(cohortNo).testTask(iTask).name]);
            save([figdir,'.fig']);
                print([figdir,'.png'], '-dpng');
                close all;

                %% SAVE model fit as struct
                save_path = fullfile(char(optionsFile.paths.cohort(cohortNo).simulations),...
                    ['simAgent_', num2str(iSample),'_model_in_',optionsFile.dataFiles.rawFitFile{m_in},...
                    '_model_est_',optionsFile.dataFiles.rawFitFile{m_est},'_',optionsFile.cohort(cohortNo).testTask(iTask).name,'.mat']);
                save(save_path, '-struct', 'est');

            end
        end
    end
end

end