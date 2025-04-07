function runAnalysis(cohortNo)

%% INITIALIZE runOptions
% Main function for running the analysis of the IDMIM study
%
%    SYNTAX:        runAnalysis
%
%    IN: cohortNo:  integer, cohort number, see optionsFile for what cohort
%                            corresponds to what number in the
%                            optionsFile.cohort(cohortNo).name struct. This
%                            allows to run the pipeline and its functions for different
%                            cohorts whose expcifications have been set in runOptions.m
%
% Original: 30-5-2023; Katharina V. Wellstein
% Amended: 23-2-2023; Nicholas Burton
% -------------------------------------------------------------------------
% Copyright (C) 2024 - need to fill in details
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

%% STARTUP
% some of these may be unnecessary, if you are running the function as a whole
close all % Close any open windows like fig windows
clc % Clear cmd window
disp('starting analysis pipeline...');
restoredefaultpath();
diary on

%% Initialise options for running this function
disp('initialising options...');

if exist('optionsFile.mat','file')==2
    load('optionsFile.mat');
else
    optionsFile = runOptions();
end

%% Simulate synthetic agents
% create agents that act like a specific model would expect them to act and then fit models
if optionsFile.doSimulations == 1
    disp('setting up simulations...');
    setup_simulations(cohortNo);
    disp('performing model inversion on simulated agents...');
    sim_data_modelinversion(cohortNo);
end

if optionsFile.doSimModelFitCheck == 1
    computeModelIdentifiability(cohortNo);
end

%% Get and process data
if optionsFile.doGetData == 1
    disp('preparing to extract raw data from .txt files in dataToAnalyseDir...');
    getData(optionsFile,cohortNo); 
end

if optionsFile.doPrepData == 1
    prepDataFiles(cohortNo);
end

%% Extract model based quantities
% Fit mouse choice data using the following models for comparison
if optionsFile.optionsFile.doModelInversion == 1
    disp('preparing to fit model to task data...');
    fitModels(cohortNo);
end

%% Sanity check plots
% parameter recovery
if optionsFile.optionsFile.doParamRecovery == 1
    disp('preparing for parameter recovery to task data...');
    parameterRecovery(cohortNo);
end


%% Bayesian Model Comparison and Model Identifiability
% (compare different model fits to see which explains the data the best)

if optionsFile.optionsFile.doBMS == 1
     disp('preparing for Bayesian Model Comparison..');
    performBMS(cohortNo)
end

disp('pipeline finished.');
diary off
save([optionsFile.optionsFile.paths.diaryDir,filesep,optionsFile.optionsFile.fileName.fullDiaryName,'.txt'])

end
