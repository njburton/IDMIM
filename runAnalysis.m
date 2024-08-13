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
close all % Close any open  windows like fig windows
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
save([optionsFile.paths.projDir,'\optionsFile.mat'],"optionsFile")  %%Breakpoint here to troubleshoot

%% Simulate synthetic agends
% create agents that act like a specific model woul expect them to act and
% then fit models
setup_simulations;
sim_data_modelinversion;

%% Extract model based quantities
% Fit mouse choice data using the following models for comparison
% eHGF, eHGF without volatility, eHGF without perceptual uncertainty, eHGF
% without volatility & perceptual uncertainty, Rescorla-Wagner, Sutton K1
%addpath(genpath(optionsFile.paths.HGFDir));
disp('preparing to fit model to task data...');

fitModels(optionsFile);

%% Plot parameter recovery and data plots
parameter_recovery(optionsFile);

%% Compare HGF & RW LME across mice
% % % % for matFile = file List;
% % % %     load(file)
% % % %     create table for with colums, treatmet, HGFvs.RW
% % % %         add files to tables
% % % %     heatmap table
% % % %

diary off
save(diaryName)
end
