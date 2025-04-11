function optionsFile = runOptions()
%% runOptions
%
% - specifies what analysis steps should be executed when running "runAnalysis"
% - creates directories and folderstructure for data if needed and sets paths
% - sets all relevant paths, global variables
% - writes all dataset specifics via setDatasetSpecifics.m
% - includes information needed to read MEDPC txt files
% - reads and saves task outcome sequences
% - specifies model space and model-related settings
% - specifies file name parts
%
%  SYNTAX:    optionsFile = runOptions()
%
%  OUTPUT:    optionsFile.mat
%
% Original: 30.04.2025, Katharina Wellstein and Nicholas Burton
%                       https://github.com/kwellstein
% -------------------------------------------------------------------------
% Copyright (C) 2025 - need to fill in details
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

%% what steps to do
optionsFile.doOptions        = 1;
optionsFile.doMakeDir        = 1;
optionsFile.doCreatePlots    = 1;
optionsFile.doSimulations    = 1;
optionsFile.setupModels      = 1;
optionsFile.doGetData        = 1;
optionsFile.doPrepData       = 1;
optionsFile.doExcludeData    = 1;
optionsFile.doModelInversion = 1;
optionsFile.doSimModelFitCheck = 1;
optionsFile.doParamFitCheck  = 1;
optionsFile.doBMS            = 1;



%% SPECIFY COHORT Specific settings and information
% specify the task name, mouseIDs, task names, conditons, exclusion criteria etc.
optionsFile = setDatasetSpecifics(optionsFile);

% size of file containing multiple mouse datasets (individualMouseMECPDCFiles are ca 63,140 bytes)
optionsFile.dataFiles.largeFileThreshold = 500000;

% specify info needed to read MEDPC files that contain more than one mouse's data
optionsFile.cohort(1).dataFile.missedTrialCode           = 3;
% optionsFile.cohort(1).dataFile.taskNameLocation          = 13;  % taskNameMSN
optionsFile.cohort(1).dataFile.outcomeOffset             = 332; % Outcome G
optionsFile.cohort(1).dataFile.choiceOffset              = 615; % Choice H
optionsFile.cohort(1).dataFile.trialStartTimeOffset      = 898; % TrialStartTime I
optionsFile.cohort(1).dataFile.recepticalBeamBreakOffset = 1181;% RecepticalBeamBreak J
optionsFile.cohort(1).dataFile.leverPressTimeOffset      = 1464;% LeverPressTime K
% specify info needed to read single-mouse MEDPC files
optionsFile.cohort(1).dataFile.ConditionMarker      = {'Group:','Group'};
optionsFile.cohort(1).dataFile.RLSMarker            = {'F:','F'}; %RewardingLeverSide
optionsFile.cohort(1).dataFile.ChoiceMarker         = {'H:','H'}; %Choice
optionsFile.cohort(1).dataFile.OutcomeMarker        = {'G:','G'}; % Did they get a reward
optionsFile.cohort(1).dataFile.LeverPressTimeMarker = {'K:','K'}; %LeverPressTime
optionsFile.cohort(1).dataFile.TrialStartTimeMarker = {'I:','I'}; % TrialStartTime
optionsFile.cohort(1).dataFile.RecepticalBeamBreakMarker = {'J:','J'}; % RecepticalBeamBreak

% specify info needed to read MEDPC files that contain more than one mouse's data
optionsFile.cohort(2).dataFile.missedTrialCode           = 3;
% optionsFile.cohort(2).dataFile.taskNameLocation          = 13;  % taskNameMSN
optionsFile.cohort(2).dataFile.outcomeOffset             = 332; % Outcome G
optionsFile.cohort(2).dataFile.choiceOffset              = 615; % Choice H
optionsFile.cohort(2).dataFile.trialStartTimeOffset      = 898; % TrialStartTime I
optionsFile.cohort(2).dataFile.recepticalBeamBreakOffset = 1181;% RecepticalBeamBreak J
optionsFile.cohort(2).dataFile.leverPressTimeOffset      = 1464;% LeverPressTime K

% specify info needed to read single-mouse MEDPC files
optionsFile.cohort(2).dataFile.ConditionMarker      = {'Group:','Group'};
optionsFile.cohort(2).dataFile.RLSMarker            = {'F:','F'}; %RewardingLeverSide
optionsFile.cohort(2).dataFile.ChoiceMarker         = {'H:','H'}; %Choice
optionsFile.cohort(2).dataFile.OutcomeMarker        = {'G:','G'}; %Outcome
optionsFile.cohort(2).dataFile.LeverPressTimeMarker = {'K:','K'}; %LeverPressTime
optionsFile.cohort(2).dataFile.TrialStartTimeMarker = {'I:','I'}; % TrialStartTime
optionsFile.cohort(2).dataFile.RecepticalBeamBreakMarker = {'J:','J'}; % RecepticalBeamBreak

% specify info needed to read MEDPC files that contain more than one mouse's data
optionsFile.cohort(3).dataFile.missedTrialCode           = 3;
% optionsFile.cohort(3).dataFile.taskNameLocation          = 13;  % taskNameMSN
optionsFile.cohort(3).dataFile.outcomeOffset             = 332; % Outcome G
optionsFile.cohort(3).dataFile.choiceOffset              = 615; % Choice H
optionsFile.cohort(3).dataFile.trialStartTimeOffset      = 898; % TrialStartTime I
optionsFile.cohort(3).dataFile.recepticalBeamBreakOffset = 1181;% RecepticalBeamBreak J
optionsFile.cohort(3).dataFile.leverPressTimeOffset      = 1464;% LeverPressTime K

% specify info needed to read single-mouse MEDPC files
optionsFile.cohort(3).dataFile.ConditionMarker      = {'Group:','Group'};
optionsFile.cohort(3).dataFile.RLSMarker            = {'F:','F'}; %RewardingLeverSide
optionsFile.cohort(3).dataFile.ChoiceMarker         = {'H:','H'}; %Choice
optionsFile.cohort(3).dataFile.OutcomeMarker        = {'G:','G'}; %Outcome
optionsFile.cohort(3).dataFile.LeverPressTimeMarker = {'K:','K'}; %LeverPressTime
optionsFile.cohort(3).dataFile.TrialStartTimeMarker = {'I:','I'}; % TrialStartTime
optionsFile.cohort(3).dataFile.RecepticalBeamBreakMarker = {'J:','J'}; % RecepticalBeamBreak


%% SPECIFY PATHS
% reorganize data and results folders
disp('setting new paths...');
% hardcoded, change to data directory of choice
optionsFile.paths.saveDir    = 'C:\Users\c3200098\Desktop\thesisData\';
optionsFile.paths.projDir    = [pwd,filesep];
optionsFile.paths.utilsDir   = [optionsFile.paths.projDir,'utils',filesep];
optionsFile.paths.toolboxDir = [optionsFile.paths.projDir,'toolboxes',filesep];
optionsFile.paths.resultsDir = [optionsFile.paths.saveDir,'results',filesep];
optionsFile.paths.dataDir    = [optionsFile.paths.saveDir,'data',filesep];
optionsFile.paths.inputsDir  = [optionsFile.paths.utilsDir,'inputSequences',filesep];

for d = 1:size(optionsFile.cohort,2)
    optionsFile.paths.cohort(d).data       = [optionsFile.paths.dataDir,optionsFile.cohort(d).name,filesep];
    optionsFile.paths.cohort(d).rawData    = [optionsFile.paths.dataDir,'raw',filesep,optionsFile.cohort(d).name,filesep];
    optionsFile.paths.cohort(d).results    = [optionsFile.paths.resultsDir,optionsFile.cohort(d).name,filesep];
    optionsFile.paths.cohort(d).groupLevel = [optionsFile.paths.cohort(d).results,'group',filesep];
    optionsFile.paths.cohort(d).groupSim   = [optionsFile.paths.cohort(d).groupLevel,'simulations',filesep];
    optionsFile.paths.cohort(d).plots      = [optionsFile.paths.resultsDir,optionsFile.cohort(d).name,filesep,'plots',filesep];
    optionsFile.paths.cohort(d).simulations = [optionsFile.paths.resultsDir,optionsFile.cohort(d).name,filesep,'simulations',filesep];
    optionsFile.paths.cohort(d).simPlots    = [optionsFile.paths.resultsDir,optionsFile.cohort(d).name,filesep,'simulations',filesep,'plots',filesep]; %% TO CHECK WHAT THAT IS FOR
end

if optionsFile.doMakeDir
    mkdir(optionsFile.paths.saveDir)
    for d = 1:size(optionsFile.cohort,2)
        mkdir(optionsFile.paths.cohort(d).data);
        mkdir(optionsFile.paths.cohort(d).rawData);
        mkdir(optionsFile.paths.cohort(d).results);
        mkdir(optionsFile.paths.cohort(d).groupLevel);
        mkdir(optionsFile.paths.cohort(d).groupSim);
        mkdir(optionsFile.paths.cohort(d).plots);
        mkdir(optionsFile.paths.cohort(d).simulations);
        mkdir(optionsFile.paths.cohort(d).simPlots);
    end
end

%% GET TASK INPUTS

% get test task outcome sequences
for d = 1:size(optionsFile.cohort,2)
    for i = 1:numel(optionsFile.cohort(d).testTask)
        inputs = readmatrix([optionsFile.paths.inputsDir,optionsFile.cohort(d).name,filesep,...
            optionsFile.cohort(d).taskPrefix,optionsFile.cohort(d).testTask(i).name,'.txt']);
        if size(inputs,2)>1
            optionsFile.cohort(d).testTask(i).inputs = inputs';
        else
            optionsFile.cohort(d).testTask(i).inputs = inputs;
        end
    end

    % get training task outcome sequences
    for i = 1:numel(optionsFile.cohort(d).trainTask)
        if ~isempty(optionsFile.cohort(d).trainTask(i).name) % some cohorts may not have used a training task
            inputs = readmatrix([optionsFile.paths.inputsDir,optionsFile.cohort(d).name,filesep,...
                optionsFile.cohort(d).taskPrefix,optionsFile.cohort(d).trainTask(i).name,'.txt']);
            if size(inputs,2)>1
                optionsFile.cohort(d).trainTask(i).inputs = inputs';
            else
                optionsFile.cohort(d).trainTask(i).inputs = inputs;
            end
        else
            optionsFile.cohort(d).trainTask(i).inputs = [];
        end
    end
end


%% SPECIFY SIMULATION settings
optionsFile.simulations.nSamples = 50;
optionsFile.hgf.opt_config       = eval('tapas_quasinewton_optim_config');

% seed for random number generator
optionsFile.rng.idx        = 1; % Set counter for random number states
optionsFile.rng.settings   = rng(123, 'twister');
optionsFile.rng.nRandInit  = 100;

%% SPECIFY MODELS and related functions
optionsFile.model.space       = {'HGF_3LVL','HGF_2LVL','RW'};         % all models in modelspace
optionsFile.model.names       = {'eHGF 3-level','eHGF 2-level','RW'}; % names for figure titles
optionsFile.model.prc         = {'tapas_ehgf_binary','tapas_ehgf_binary','tapas_rw_binary'};
optionsFile.model.prc_config  = {'tapas_ehgf_binary_config_3LVL','tapas_ehgf_binary_config_2LVL','tapas_rw_binary_config'};
optionsFile.model.obs	      = {'tapas_unitsq_sgm'};
optionsFile.model.obs_config  = {'tapas_unitsq_sgm_config'};
optionsFile.model.opt_config  = {'tapas_quasinewton_optim_config'};
optionsFile.plot(1).plot_fits = @tapas_ehgf_binary_plotTraj;
optionsFile.plot(2).plot_fits = @tapas_ehgf_binary_plotTraj;
optionsFile.plot(3).plot_fits = @tapas_rw_binary_plotTraj;

%% SPECIFY FILENAMES
optionsFile.dataFiles.simResponses     = 'sim.mat';
optionsFile.dataFiles.rawFitFile       = {'eHGF_3LVLFit','eHGF_2LVLFit','RWFit'};
optionsFile.dataFiles.fittedData       = 'modelInv.mat';
optionsFile.dataFiles.dataBaseFileName = 'rawDataFileInfo.mat';
optionsFile.dataFiles.dataBaseName     = 'dataInfoTable';

%% SAVE options file
save([optionsFile.paths.projDir,'optionsFile.mat'],'optionsFile');

end
