function fitModels(cohortNo)
%% fitModels
%
%  SYNTAX:  fitModels(cohortNo)
%
%   IN: cohortNo:  integer, cohort number, see optionsFile for what cohort
%                            corresponds to what number in the
%                            optionsFile.cohort(cohortNo).name struct. This
%                            allows to run the pipeline and its functions for different
%                            cohorts whose expcifications have been set in runOptions.m
%
% Original: 30/5/2023; Katharina Wellstein
% Amended: 23/2/2024; Nicholas Burton
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

if exist('optionsFile.mat','file')==2
    load("optionsFile.mat");
else
    optionsFile = runOptions();
end

addpath(genpath([optionsFile.paths.toolboxDir,'HGF']));
optionsFile = setup_configFiles(optionsFile,cohortNo);

if numel(optionsFile.cohort(cohortNo).conditions)==0
    nConditions = 1;
else
    nConditions = numel(optionsFile.cohort(cohortNo).conditions);
end

for iCondition = 1:nConditions
    disp(['fitting iteration', num2str(iCondition),'........'])
    for iTask = 1:numel(optionsFile.cohort(cohortNo).testTask)
        currTask = optionsFile.cohort(cohortNo).testTask(iTask).name;
        disp(['* task  ', char(currTask),'.']);
        for iModel = 2:numel(optionsFile.model.space) %for each model in the model space

            disp(['* model ', optionsFile.model.space{iModel},'.']);

            for iMouse  = 1:optionsFile.cohort(cohortNo).nSize  % for each mouse (agent) in the cohort
                currMouse = optionsFile.cohort(cohortNo).mouseIDs{iMouse};
                try
                    try
                        if isempty(optionsFile.cohort(cohortNo).conditions)
                            load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                                optionsFile.cohort(cohortNo).taskPrefix,currTask,'.mat']);
                        else % Save with conditions included

                            currCondition = optionsFile.cohort(cohortNo).conditions{iCondition};
                            disp(['* condition  ', char(currCondition),'.']);
                            load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                                optionsFile.cohort(cohortNo).taskPrefix,currTask,'_condition_',currCondition,'.mat']);
                        end
                    catch
                        if isempty(optionsFile.cohort(cohortNo).conditions)
                            load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                                currTask,'.mat']);
                        else % Save with conditions included
                            currCondition = optionsFile.cohort(cohortNo).conditions{iCondition};
                            disp(['* condition  ', char(currCondition),'.']);
                            load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                                currTask,'_condition_',currCondition,'.mat']);
                        end
                    end
                    disp(['* mouse ', char(currMouse), ' (',num2str(iMouse),' of ',num2str(optionsFile.cohort(cohortNo).nSize),')']);

                    % optimization settings
                    strct              = eval(char(optionsFile.model.opt_config));
                    strct.maxStep      = inf;
                    strct.nRandInit    = 100; %optionsFile.rng.nRandInit;
                    strct.seedRandInit = optionsFile.rng.settings.State(optionsFile.rng.idx, 1);

                    %% model fit
                    est = tapas_fitModel(ExperimentTaskTable.Choice, ...
                        optionsFile.cohort(cohortNo).testTask(iTask).inputs, ...
                        optionsFile.model.prc_config{iModel}, ...
                        optionsFile.model.obs_config{1}, ... % only ever take first entry because all perceptual models use the same observational model, if this changes, in runOptions add different observational models and add a loop
                        strct); % info for optimization and multistart

                    %Plot standard trajectory plot
                    optionsFile.plot(iModel).plot_fits(est);
                    figdir = fullfile([char(optionsFile.paths.cohort(cohortNo).plots),...
                        'mouse',char(currMouse),'_',currTask,'_',optionsFile.dataFiles.rawFitFile{iModel}]);
                    save([figdir,'.fig']);
                    print([figdir,'.png'], '-dpng');
                    close all;

                    %Save model fit
                    if isempty(optionsFile.cohort(cohortNo).conditions)
                        save([char(optionsFile.paths.cohort(cohortNo).results),...
                            'mouse',char(currMouse),'_',currTask,'_',optionsFile.dataFiles.rawFitFile{iModel},'.mat'], 'est');
                    else
                        save([char(optionsFile.paths.cohort(cohortNo).results),...
                            'mouse',char(currMouse),'_',currTask,'_condition_',currCondition,'_',...
                            optionsFile.dataFiles.rawFitFile{iModel},'.mat'], 'est');
                    end
                    modelInv.allMice(iMouse,iModel).est = est;

                catch
                    modelInv.allMice(iMouse,iModel).est = [];
                    disp(['mouse ', char(currMouse), ' not loaded'])
                end
            end
        end
        % create savepath and filename as a .mat file
        if isempty(optionsFile.cohort(cohortNo).conditions)
            savePath = [optionsFile.paths.cohort(cohortNo).results,'_',currTask,...
                '_',optionsFile.dataFiles.fittedData];
        else % Save with conditions included
            savePath = [optionsFile.paths.cohort(cohortNo).results,'_',currTask,...
                'condition_',currCondition,'_',optionsFile.dataFiles.fittedData];
        end
        save(savePath, '-struct', 'modelInv','allMice');

    end
end
end

