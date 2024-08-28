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
% _________________________________________________________________________
% =========================================================================

%% STARTUP

% some of these may be unnecessary, if you are running the function as a whole
close all % Close any open windows like fig windows
clc % Clear cmd window

disp('starting analysis pipeline...');
restoredefaultpath();

diaryName = ['diary_', datestr(datetime('now'))];
diary on


%% Initialise options for running this function
disp('initialising options...');
optionsFile = runOptions;

%% Get,Organize, and save data into tables
optionsFile = getData(optionsFile);
save([optionsFile.paths.projDir,'optionsFile.mat'],"optionsFile");

%% Simulate synthetic agends
% create agents that act like a specific model would expect them to act and then fit models
% addpath(genpath(optionsFile.paths.HGFtoolboxDir));
% disp('setting up simulations...');
% setup_simulations;
% %disp('performing model inversion on simulated agents...');
% sim_data_modelinversion;

%% Extract model based quantities
% Fit mouse choice data using the following models for comparison
disp('preparing to fit model to task data...');
fitModels(optionsFile);

%% Plot parameter recovery and data plots
disp('preparing for parameter recovery to task data...');
parameter_recovery(optionsFile);

% %% PlotByTreatmentGroup
% disp('preparing to plot mice by their treatment groups...');
% plotByTreatmentGroup(optionsFile);

%% Bayesian Model Comparison and Model Identifiability
% (compare different model fits to see which explains the data the best)
%disp('preparing for Bayesian Model Comparison and model identifiability...');


diary off
save(diaryName)
end
