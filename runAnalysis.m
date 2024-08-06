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

%% IS THIS RELEVANT/WORKING?
%% Plot responses, perceptualModel prior & posterior params
disp('plotting sim mice...');
for k = 1:optionsFile.simulations.nSamples
    simData = load('C:\Users\c3200098\Desktop\projects\IDMIM\simResults\ABA1_Lsimulation_agent(k)model_in1_model_est1.mat'); %agent1model
    histogram(simData.rec.sim.agent(k).data.y);


    figdir = fullfile([char(optionsFile.paths.resultsDir),'\mouse',num2str(currMouse),'RWFit']);


    simMouseResponsePriorPostParamPlot = tiledlayout(2,4,'TileSpacing','Compact');
    title(ResponsePriorPostParamPlot, 'sim mouse XXX');

    %Tile1 - Responses of simMouse
    ax1 = nexttile([1,2]);
    histogram(simData.y);
    ylim([0.0 maxResponses]);
    title('Responses');

    %Tile2 - Omega percModel prior values of 3 levels of currMouse
    ax2 = nexttile([1,2]);
    X = categorical({'FirstLevel','SecondLevel','ThirdLevel'});
    X = reordercats(X,{'FirstLevel','SecondLevel','ThirdLevel'});
    Y = simData.c_prc.ommu; %perceptual Omega priors
    bar(X,Y,0.5);
    ylim([0.3 0.8]);
    title('omega prior of perc');


    %Tile3 - Omega percModel posterior values of 3 levels of currMouse
    nexttile(6,[1,2]);
    X = categorical({'FirstLevel','SecondLevel','ThirdLevel'});
    X = reordercats(X,{'FirstLevel','SecondLevel','ThirdLevel'});
    Y = simData.p_prc.om; %perceptual omega posteriors
    bar(X,Y,0.5);
    ylim([0.3 0.8]);
    title('Omega posterior perc');


    %Save ResponsePriorPostParamPlot
    figdir = fullfile([char(optionsFile.paths.resultsDir),'\mouse',num2str(currMouse),'SimMouseResponsePriorPostParamPlot']);
    save([figdir,'.fig']);
    print([figdir,'.png'], '-dpng');


end

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
