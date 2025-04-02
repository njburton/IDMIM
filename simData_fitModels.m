function [] = simData_fitModels(cohortNo)

%% simData_fitModels
%  Invert simulated agents with models in the modelspace. This step will be
%  executed if optionsFile.doSimulations = 1;
%
%   SYNTAX:       simData_fitModels
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

%% INITIALIZE options and variables needed to run this function

disp('************************************** INVERT SIMULATED RESPONSES **************************************');
disp('*');
disp('*');

% load or run options for running this function
if exist('optionsFile.mat','file')==2
    load('optionsFile.mat');
else
    optionsFile = runOptions();
end

% prespecify variables needed for running this function
nTasks   = numel(optionsFile.cohort(cohortNo).testTask);
nModels  = numel(optionsFile.model.space);
nSamples = optionsFile.simulations.nSamples;

%% SPECIFY modeling settings
% add toolbox path
addpath(genpath([optionsFile.paths.toolboxDir,'HGF']));

% if responses to the task in this cohort should be simulated using informed priors,
% run getInformedPriors.m with the settings prespecified in the optionsFile
if ~isempty(optionsFile.cohort(cohortNo).priorsFromCohort)
    optionsFile = setup_configFiles(optionsFile,cohortNo);
    disp('get priors from pilot data...');
    % input aguments: priorCohort,currCohort,subCohort,iTask,iCondition,iRep,optionsHandle
    [~,optionsFile] = get_informedPriors(optionsFile.cohort(cohortNo).priorsFromCohort,...
        cohortNo,optionsFile.cohort(cohortNo).priorsFromSubCohort,...
        optionsFile.cohort(cohortNo).priorsFromTask,optionsFile.cohort(cohortNo).priorsFromCondition,...
        optionsFile.cohort(cohortNo).priorsFromRepetition,0);

else % otherwise just set up the configfiles for the models in the modelspace
    optionsFile = setup_configFiles(optionsFile,cohortNo);
end

strct              = optionsFile.hgf.opt_config;
strct.maxStep      = inf;
strct.nRandInit    = optionsFile.rng.nRandInit;
strct.seedRandInit = optionsFile.rng.settings.State(optionsFile.rng.idx, 1);
                
%%  MODEL INVERSION
% looping across tasks, samples, models that created the simulated behaviour (gen model | m_in) 
% and models that will be fitted to the simulated behaviour (estimating model | m_est)
for iTask = 1:nTasks
    for iSample = 1:nSamples 
        for m_in = 1:nModels
            sim = load(fullfile([optionsFile.paths.cohort(cohortNo).simulations,optionsFile.model.space{m_in},'_',optionsFile.cohort(cohortNo).testTask(iTask).name,'_sim']));

            for m_est = 1:nModels
                if m_est == 3 && m_in ==3
                    strct.maxStep  = 1000;
                end

                disp(['Model inversion for agent: ', num2str(iSample), ' | gen model ', optionsFile.modelSpace(m_in).name, ' | estimating with model: ', optionsFile.modelSpace(m_est).name]);
                est = tapas_fitModel(sim.agent(iSample,m_in).task(iTask).data.y,... % responses
                    optionsFile.cohort(cohortNo).testTask(iTask).inputs,...                  % input sequence
                    optionsFile.modelSpace(m_est,iTask).prc_config,...         % Prc fitting model
                    optionsFile.modelSpace(m_est,iTask).obs_config,...         % Obs fitting model
                    strct); % seed for multistart

                if optionsFile.doCreatePlots
                    % Plot standard trajectory plot
                    optionsFile.plot(m_est).plot_fits(est);
                    figdir = fullfile([char(optionsFile.paths.cohort(cohortNo).simPlots),...
                        'simAgent_', num2str(iSample),'_',optionsFile.cohort(cohortNo).testTask(iTask).name,'_model_in_',optionsFile.dataFiles.rawFitFile{m_in},...
                        '_model_est_',optionsFile.dataFiles.rawFitFile{m_est}]);
                    save([figdir,'.fig']);
                    print([figdir,'.png'], '-dpng');
                    close all;
                end

                %% SAVE model fit
                savePath = fullfile(char(optionsFile.paths.cohort(cohortNo).simulations),...
                    ['simAgent_', num2str(iSample),'_',optionsFile.cohort(cohortNo).testTask(iTask).name,'_model_in_',optionsFile.dataFiles.rawFitFile{m_in},...
                        '_model_est_',optionsFile.dataFiles.rawFitFile{m_est},'.mat']);
                save(savePath, '-struct', 'est');

            end % END ESTIMATING MODEL loop
        end % END GENERATING MODEL loop
    end % END SAMPLE loop
end % END TASK loop

disp('model inversion of simulated responses for cohort ',optionsFile.cohort(cohortNo).name,' complete.')

end