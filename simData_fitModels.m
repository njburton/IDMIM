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
% Coded by: 30-04-2025; Katharina V. Wellstein
% -------------------------------------------------------------------------
% Copyright (C) 2025
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

disp(['******** for mice in ', char(optionsFile.cohort(cohortNo).name), ' cohort ********']);

% prespecify variables needed for running this function
nTasks   = numel(optionsFile.cohort(cohortNo).testTask);
nModels  = numel(optionsFile.model.space);
nSamples = optionsFile.simulations.nSamples;

% specify  modeling settings add toolbox path
addpath(genpath([optionsFile.paths.toolboxDir,'HGF']));
strct              = optionsFile.hgf.opt_config;
strct.maxStep      = inf;
strct.nRandInit    = optionsFile.rng.nRandInit;
strct.seedRandInit = optionsFile.rng.settings.State(optionsFile.rng.idx, 1);

% if responses to the task in this cohort should be simulated using informed priors,
% run getInformedPriors.m with the settings prespecified in the optionsFile
if ~isempty(optionsFile.cohort(cohortNo).priorsFromCohort)

    % set up the configfiles for the models in the modelspace
    optionsFile = setup_configFiles(optionsFile,cohortNo);
    disp(['>>>>>>>>> get priors from data in ',char(optionsFile.cohort(optionsFile.cohort(cohortNo).priorsFromCohort).name), '.... ']);

    % input aguments: priorCohort,currCohort,subCohort,iTask,iCondition,iRep,optionsHandle
    [~,optionsFile] = get_informedPriors(optionsFile.cohort(cohortNo).priorsFromCohort,...
        optionsFile.cohort(cohortNo).priorsFromSubCohort,...
        optionsFile.cohort(cohortNo).priorsFromTask,optionsFile.cohort(cohortNo).priorsFromCondition,...
        optionsFile.cohort(cohortNo).priorsFromRepetition);

else % otherwise just set up the configfiles for the models in the modelspace
    optionsFile = setup_configFiles(optionsFile,cohortNo);
end

sim = load([optionsFile.paths.cohort(cohortNo).simulations,optionsFile.cohort(cohortNo).taskPrefix,optionsFile.dataFiles.simResponses]);      
%%  MODEL INVERSION
% looping across tasks, samples, models that created the simulated behaviour (gen model | m_in) 
% and models that will be fitted to the simulated behaviour (estimating model | m_est)
for iTask = 1:nTasks
    for iSample = 1:nSamples 
        for m_in = 1:nModels
            for m_est = 1:nModels
                if strcmp(optionsFile.model.space{m_est},'RW') && strcmp(optionsFile.model.space{m_in},'RW')
                    strct.maxStep  = 1000; % special setting for the RW model due to issue with opt algorithm
                end

                disp(['Model inversion for agent: ', num2str(iSample), ' | gen model ', optionsFile.modelSpace(m_in).name, ' | estimating with model: ', optionsFile.modelSpace(m_est).name]);
                est = tapas_fitModel(sim.agent(iSample,m_in).task(iTask).data.y,... % responses
                    optionsFile.cohort(cohortNo).testTask(iTask).inputs,...         % input sequence
                    optionsFile.modelSpace(m_est,iTask).prc_config,...         % Prc fitting model
                    optionsFile.modelSpace(m_est,iTask).obs_config,...         % Obs fitting model
                    strct); % settings and seed for multistart

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