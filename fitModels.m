function fitModels(cohortNo)

% fitModels - Fit computational models to mouse behavioural data
%
% This function fits multiple computational models to choice data from 
% behavioural experiments. It processes data across conditions, tasks, 
% repetitions, and individual mice, applying hierarchical Gaussian filter (HGF) 
% models and Rescorla-Wagner models (RW) to quantify learning parameters. 
% The function systematically loops through the dataset, creating individual
% model fits for each mouse and experimental condition while handling informed 
% priors if specified. Model fitting results are saved individually and also 
% compiled into group-level files for further analysis. The function supports 
% visualisation of model trajectories when enabled in the optionsFile.
%
% -------------------------------------------------------------------------
%
%  SYNTAX:  fitModels(cohortNo)
%
%   IN: cohortNo:  integer, cohort number, see optionsFile for what cohort
%                            corresponds to what number in the
%                            optionsFile.cohort(cohortNo).name struct. This
%                            allows to run the pipeline and its functions for different
%                            cohorts whose expcifications have been set in runOptions.m
%
% -------------------------------------------------------------------------
%
% Original: 30/5/2023; Katharina Wellstein
% Amended: 23/2/2024; Nicholas Burton
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
% -------------------------------------------------------------------------

%% INITIALIZE options and variables needed to run this function
if exist('optionsFile.mat','file')==2
    load('optionsFile.mat');
else
    optionsFile = runOptions();
end

% prespecify variables needed for running this function
nTasks  = numel(optionsFile.cohort(cohortNo).testTask);
nReps   = optionsFile.cohort(cohortNo).taskRepetitions;
nModels = numel(optionsFile.model.space);
nSize   = optionsFile.cohort(cohortNo).nSize;

if numel(optionsFile.cohort(cohortNo).conditions)==0
    nConditions   = 1;
    currCondition = [];
else
    nConditions = numel(optionsFile.cohort(cohortNo).conditions);
end

% add toolbox path
addpath(genpath([optionsFile.paths.toolboxDir,'HGF']));
% set up config files for models in model space
optionsFile = setup_configFiles(optionsFile,cohortNo);

% optimization settings
strct              = eval(char(optionsFile.model.opt_config));
strct.maxStep      = inf;
strct.nRandInit    = optionsFile.rng.nRandInit;
strct.seedRandInit = optionsFile.rng.settings.State(optionsFile.rng.idx, 1);

%% INVERT MODELS with data
% by looping though conditions, tasks, repetitions, mice, and models

for iCondition = 1:nConditions
    if nConditions>1 % if there is more than one condition get condition name string
        currCondition = iCondition;
        disp(['* condition ', char(currCondition),'.']);
        currCondition = optionsFile.cohort(cohortNo).conditions{iCondition};
    end

    for iTask = 1:nTasks
        currTask = optionsFile.cohort(cohortNo).testTask(iTask).name;
        disp(['* task  ', char(currTask),'.']);

        for iRep = 1:nReps
            disp(['* repetition  ', num2str(iRep),'.']);
            % get informed priors in case that was specified for this cohort
            if ~isempty(optionsFile.cohort(cohortNo).priorsFromCohort)
                % input aguments: (priorCohort,subCohort,iTask,iCondition,iRep)
                [~,optionsFile] = get_informedPriors(optionsFile.cohort(cohortNo).priorsFromCohort,...
                    optionsFile.cohort(cohortNo).priorsFromSubCohort,...
                    optionsFile.cohort(cohortNo).priorsFromTask,optionsFile.cohort(cohortNo).priorsFromCondition,...
                    optionsFile.cohort(cohortNo).priorsFromRepetition);
            end

            for iMouse  = 1:nSize
                currMouse = optionsFile.cohort(cohortNo).mouseIDs{iMouse};
                loadName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,...
                    [],currCondition,iRep,nReps,[]);

                for iModel = 1:nModels
                    disp(['* model ', optionsFile.model.space{iModel},'.']);

                    try
                        load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                            loadName,'.mat']);

                        disp(['* mouse ', char(currMouse), ' (',num2str(iMouse),' of ',num2str(optionsFile.cohort(cohortNo).nSize),')...']);

                        %% model fit
                        est = tapas_fitModel(ExperimentTaskTable.Choice, ...
                            optionsFile.cohort(cohortNo).testTask(iTask).inputs, ...
                            optionsFile.model.prc_config{iModel}, ...
                            optionsFile.model.obs_config{1}, ... % all perceptual models use the same observational model
                            strct); % info for optimization and multistart

                        if optionsFile.doCreatePlots
                            % Plot standard trajectory plot
                            optionsFile.plot(iModel).plot_fits(est);
                            saveName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,...
                                [],currCondition,iRep,nReps,[]);
                            figdir = fullfile([char(optionsFile.paths.cohort(cohortNo).plots),...
                                'mouse',char(currMouse),'_',saveName,'_',optionsFile.dataFiles.rawFitFile{iModel}]);
                            save([figdir,'.fig']);
                            print([figdir,'.png'], '-dpng');
                            close all;
                        end

                        %Save model fit
                        save([char(optionsFile.paths.cohort(cohortNo).results),...
                            'mouse',char(currMouse),'_',saveName,'_',optionsFile.dataFiles.rawFitFile{iModel},'.mat'], 'est');

                        modelInv.allMice(iMouse,iModel).est = est;

                    catch
                        modelInv.allMice(iMouse,iModel).est = [];
                        disp(['mouse ', char(saveName), ' not loaded...'])
                    end

                    % create savepath and filename as a .mat file
                    groupSaveName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,...
                        [],currCondition,iRep,nReps,[]);
                    savePath = [optionsFile.paths.cohort(cohortNo).groupLevel,groupSaveName,'_',...
                        optionsFile.model.space{iModel},'_',optionsFile.dataFiles.fittedData];

                    save(savePath, '-struct', 'modelInv','allMice');
                end % END MODEL loop
            end % END MOUSE loop
        end % END REPETITION loop
    end % END TASK loop
end % END CONDITION loop

end

