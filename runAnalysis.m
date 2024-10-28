function runAnalysis

%% INITIALIZE runOptions
% Main function for running the analysis of the IDMIM study
%
%    SYNTAX:        runAnalysis
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

diaryName = 'diary_IDMIM_UCMS_study'; %start diary that will be saved as a textfile
diary on

%% Initialise options for running this function
disp('initialising options...');
optionsFile = load("optionsFile.mat");

%% Simulate synthetic agents
% create agents that act like a specific model would expect them to act and then fit models
if optionsFile.doSimulations
    addpath(genpath(optionsFile.paths.HGFtoolboxDir));
    disp('setting up simulations...');
    setup_simulations;
    disp('performing model inversion on simulated agents...');
    sim_data_modelinversion;
end

%% Extract model based quantities
% Fit mouse choice data using the following models for comparison
if optionsFile.doModelInversion
    disp('preparing to fit model to task data...');
    fitModels(optionsFile);
end

%% Plot parameter recovery and data plots
if optionsFile.doParamRecovery
    disp('preparing for parameter recovery to task data...');
    parameter_recovery(optionsFile);
end

%% Bayesian Model Comparison and Model Identifiability
% (compare different model fits to see which explains the data the best)
%disp('preparing for Bayesian Model Comparison and model identifiability...');
if optionsFile.doBMS
    performBMS
end

diary off
save(diaryName)
disp('pipeline finished.');

end
