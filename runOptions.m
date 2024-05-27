function optionsFile = runOptions()

%% runOptions
% - set all relevant paths, global variables
% - specify what analysis steps should be executed when running "runAnalysis"
% - make directories and folderstructure for data if needed
%
%  SYNTAX:          runAnalysis
%
%  OUTPUT:
%
%
% Original: 30/5/2023; Katharina Wellstein
% Amended: 23/2/2024; Nicholas Burton
% -------------------------------------------------------------------------
%
% Copyright (C) 2024 - need to fill in details
%
%
% _________________________________________________________________________
% =========================================================================

%% SET DIRECTORY PATHS FOR PROJECT, RAWDATA, RESULTS & PLOTS
% Set paths of directories
disp('setting paths...');
optionsFile.paths.projDir         = 'C:\Users\c3200098\Desktop\IDMIM';
optionsFile.paths.rawDataStoreDir = 'C:\Users\c3200098\Desktop\IDMIM\rawDataStore';
optionsFile.paths.resultsDir      = 'C:\Users\c3200098\Desktop\IDMIM\results';
optionsFile.paths.plotsDir        = 'C:\Users\c3200098\Desktop\IDMIM\plots';
optionsFile.paths.rawDataDir      = ('C:\Users\c3200098\Desktop\data\');
optionsFile.paths.toolbox         = 'C:\Users\c3200098\Desktop\IDMIM\HGF';

% task names
optionsFile.Task          = load('C:\Users\c3200098\Desktop\results\resultsANS\HGF-ANS-latest.mat', 'seqABALeftLever');
optionsFile.Task.FileName = 'testResults2_ABA2_R_corrrectedVariables.xlsx';
optionsFile.Task.task1    = 'ABA1_L';
optionsFile.Task.task2    = 'ABA2_R';
optionsFile.Task.nTrials  = 180;
optionsFile.Task.nSize    = 22;


% simulation options
optionsFile.simulations.nSamples      = 100;
optionsFile.simulations.simResultsDir = 'C:\Users\c3200098\Desktop\IDMIM\simResults';

if ~exist(optionsFile.simulations.simResultsDir,'dir')
    mkdir(optionsFile.simulations.simResultsDir)
end

%% !!!!!!!!! TO COMPLETE !!!!!!!!!!!
optionsFile.DataFile.ChoiceMarker   = 'H:';
optionsFile.DataFile.OutcomeMarker  = '??:'; %Outcome_ABA1
optionsFile.DataFile.LeverPressTime = '??:'; %LeverPressTime_ABA1
optionsFile.DataFile.TrialStartTime = '??:';


%% DATA EXTRACTION & PREPARATION
% Extract data from MED-PC output file (.xlsx) and save as matlab file.
% Individual subject data stored as a table.
%mouseID, totalSubjs = length(unique(mouseID));  % Total number of subjects in  cohort
%treatmentGroup, sex, task, task phase (A vs. B), trial, rewardingLeverSide, choice, outcome
%trialStartTime, leverPressTime, responseTime (create it)

%% !!!!! TO DO, comment out for now...

% %%  EXTRACT AND SAVE DATA IN DESCRIPTIVE TABLE
% % Locate GetOperant output file in directory
% rawDescriptiveData = readcell([optionsFile.paths.rawDataDir,'\', optionsFile.Task.task2,'\', optionsFile.Task.FileName],'Range','A1:W15');
% rawDescriptiveData(cellfun(@(x) all(ismissing(x)), rawDescriptiveData)) = {NaN};
% 
% %Create empty table for descriptive mouse with variable names as columns
% varTypes = {'string','string','string','string','double','double','double','double','double'}; %Defines variable type for creating the table
% varNames = {'MouseID','Group','Sex','Age','Omissions','TotalRewards','TotalTimeouts','TotalLeftLeverPresses','TotalRightLeverPresses'};
% ExperimentDescriptiveTable = table('Size',[22 9],'VariableTypes',varTypes,'VariableNames',varNames);
% 
% disp('descriptive table created...');
% 
% %For loop which creates dscriptive mouse table
% for i = 1:22
% 
%     ExperimentDescriptiveTable.MouseID(i)                = string(rawDescriptiveData{4,1+i});
%     ExperimentDescriptiveTable.Group(i)                  = 'NaN';
%     ExperimentDescriptiveTable.Sex(i)                    = 'NaN';
%     ExperimentDescriptiveTable.Age(i)                    = 0; %find age by writing into csv file to read into matlab (samew folder as descriptivedata)
%     ExperimentDescriptiveTable.Omissions(i)              = cell2mat(rawDescriptiveData(11,1+i));
%     ExperimentDescriptiveTable.TotalRewards(i)           = cell2mat(rawDescriptiveData(12,1+i));
%     ExperimentDescriptiveTable.TotalTimeouts(i)          = cell2mat(rawDescriptiveData(13,1+i));
%     ExperimentDescriptiveTable.TotalLeftLeverPresses(i)  = cell2mat(rawDescriptiveData(14,1+i));
%     ExperimentDescriptiveTable.TotalRightLeverPresses(i) = cell2mat(rawDescriptiveData(15,1+i));
% 
% end
% save([char(optionsFile.paths.resultsDir),'\ExperimentDescriptiveTable.mat'],'ExperimentDescriptiveTable');
% disp('descriptive table filled with data...');

%%  EXTRACT AND SAVE DATA IN SINGLE MOUSE TABLES

%Create empty table for individual mouse with variable names as columns
TaskTableVarTypes = {'string','double','double','double','double','double','double','double'};
TaskTableVarNames = {'TrialCode','RewardingLeverSideABA1','Choice','Outcome','TrialStartTime','LeverPressTime','ResponseTime','RecepticalBeamBreak'};
ExperimentTaskTable = table('Size',[180 8],'VariableTypes', TaskTableVarTypes,'VariableNames',TaskTableVarNames);

%For loop which creates individual mouse tables from rawTaskData file
%(where each column is a mouse)
files = dir(fullfile(optionsFile.paths.rawDataDir,'*Subject *.txt'));

for i = 1:optionsFile.Task.nSize
    fileName  = string(files(i).name);
    currMouse = extract(fileName ," "+digitsPattern(3)+".");
    currMouse = erase( currMouse{end},".");

    data      = readcell(fileName);
    choiceIdx = find(contains(data(:,1),optionsFile.DataFile.ChoiceMarker))+1;

    ExperimentTaskTable.TrialCode           = nan(optionsFile.Task.nTrials,1); % ?? why are they NaNs?
    ExperimentTaskTable.Choice              = cell2mat(data(choiceIdx:choiceIdx+optionsFile.Task.nTrials-1,1+i));  %Choice_ABA1
    ExperimentTaskTable.Outcome             = cell2mat(data(outcomeIdx:outcomeIdx+optionsFile.Task.nTrials-1,1+i));   %Outcome_ABA1
    ExperimentTaskTable.LeverPressTime      = cell2mat(data(lPressTIdx:lPressTIdx+optionsFile.Task.nTrials-1,1+i));  %LeverPressTime_ABA1
    ExperimentTaskTable.TrialStartTime      = (0:20:3600)'; %TrialStartTime list every 20seconds
    ExperimentTaskTable.ResponseTime        = ExperimentTaskTable.LeverPressTime - ExperimentTaskTable.TrialStartTime; %ResponseTime
    ExperimentTaskTable.RecepticalBeamBreak = cell2mat(rawTaskData(725:905,1+i)) - ExperimentTaskTable.TrialStartTime; %RecepticalBeamBreak_ABA1
    optionsFile.MouseID(i) = currMouse;

    %Data correction
    ExperimentTaskTable.Choice(ExperimentTaskTable.Choice==3) = NaN;  %Replace omissions (3 in Choice) with NaN
    ExperimentTaskTable.LeverPressTime(ExperimentTaskTable.LeverPressTime==0) = NaN; %Replace trials where no lever press with NaN
    ExperimentTaskTable.RecepticalBeamBreak(ExperimentTaskTable.RecepticalBeamBreak<0) = NaN;

    % mkdir([char(optionsFile.paths.resultsDir),'\mouse',char(currMouse)]);
    save([char(optionsFile.paths.resultsDir),'\mouse',char(currMouse)],'ExperimentTaskTable');
end



%Need to fix computing responsetime
%import unique binary sequence for rewarding lever side


%% optimization algorithm
addpath(genpath(optionsFile.paths.toolbox));

optionsFile.hgf.opt_config           = eval('tapas_quasinewton_optim_config');
optionsFile.hgf.opt_config.nRandInit = 100; %%

%% seed for random number generator
optionsFile.rng.idx      = 1; % Set counter for random number states
optionsFile.rng.settings = rng(123, 'twister');

%% define model and its related functions
optionsFile.model.space      = {'eHGF binary'};
optionsFile.model.prc        = {'tapas_ehgf_binary'};
optionsFile.model.prc_config = {'tapas_ehgf_binary_config'};
optionsFile.model.obs	     = {'tapas_unitsq_sgm'};
optionsFile.model.obs_config = {'tapas_unitsq_sgm_config'};
optionsFile.model.optim      = {'tapas_quasinewton_optim_config'};
optionsFile.model.hgf_plot   = {'tapas_ehgf_binary_plotTraj'};
optionsFile.plot.plot_fits   = @tapas_ehgf_binary_plotTraj;

modelSpace = struct();

%% SETUP config files for Perceptual models
for i = 1:numel(optionsFile.model.space)
    modelSpace(i).prc        = optionsFile.model.prc{i};
    modelSpace(i).prc_config = eval(optionsFile.model.prc_config{i});
    pr = priorPrep(optionsFile.Task.seqABALeftLever);

    % Replace placeholders in parameter vectors with their calculated values
    modelSpace(i).prc_config.priormus(modelSpace(i).prc_config.priormus==99991) = pr.plh.p99991;
    modelSpace(i).prc_config.priorsas(modelSpace(i).prc_config.priorsas==99991) = pr.plh.p99991;

    modelSpace(i).prc_config.priormus(modelSpace(i).prc_config.priormus==99992) = pr.plh.p99992;
    modelSpace(i).prc_config.priorsas(modelSpace(i).prc_config.priorsas==99992) = pr.plh.p99992;

    modelSpace(i).prc_config.priormus(modelSpace(i).prc_config.priormus==99993) = pr.plh.p99993;
    modelSpace(i).prc_config.priorsas(modelSpace(i).prc_config.priorsas==99993) = pr.plh.p99993;

    modelSpace(i).prc_config.priormus(modelSpace(i).prc_config.priormus==-99993) = -pr.plh.p99993;
    modelSpace(i).prc_config.priorsas(modelSpace(i).prc_config.priorsas==-99993) = -pr.plh.p99993;

    modelSpace(i).prc_config.priormus(modelSpace(i).prc_config.priormus==99994) = pr.plh.p99994;
    modelSpace(i).prc_config.priorsas(modelSpace(i).prc_config.priorsas==99994) = pr.plh.p99994;

    % Get fieldnames. If a name ends on 'mu', that field defines a prior mean.
    % If it ends on 'sa', it defines a prior variance.
    names  = fieldnames(modelSpace(i).prc_config);
    fields = struct2cell(modelSpace(i).prc_config);

    % Loop over names
    for n = 1:length(names)
        if regexp(names{n}, 'mu$')
            priormus = [];
            priormus = [priormus, modelSpace(i).prc_config.(names{n})];
            priormus(priormus==99991)  = pr.plh.p99991;
            priormus(priormus==99992)  = pr.plh.p99992;
            priormus(priormus==99993)  = pr.plh.p99993;
            priormus(priormus==-99993) = -pr.plh.p99993;
            priormus(priormus==99994)  = pr.plh.p99994;
            modelSpace(i).prc_config.(names{n}) = priormus;
            clear priormus;

        elseif regexp(names{n}, 'sa$')
            priorsas = [];
            priorsas = [priorsas, modelSpace(i).prc_config.(names{n})];
            priorsas(priorsas==99991)  = pr.plh.p99991;
            priorsas(priorsas==99992)  = pr.plh.p99992;
            priorsas(priorsas==99993)  = pr.plh.p99993;
            priorsas(priorsas==-99993) = -pr.plh.p99993;
            priorsas(priorsas==99994)  = pr.plh.p99994;
            modelSpace(i).prc_config.(names{n}) = priorsas;
            clear priorsas;
        end
    end

    % find parameter names of mus and sas:
    expnms_mu_prc=[];
    expnms_sa_prc=[];
    n_idx      = 0;
    for k = 1:length(names)
        if regexp(names{k}, 'mu$')
            for l= 1:length(fields{k})
                n_idx = n_idx + 1;
                expnms_mu_prc{1,n_idx} = [names{k},'_',num2str(l)];
            end
        elseif regexp(names{k}, 'sa$')
            for l= 1:length(fields{k})
                n_idx = n_idx + 1;
                expnms_sa_prc{1,n_idx} = [names{k},'_',num2str(l)];
            end
        end
    end
    modelSpace(i).expnms_mu_prc=expnms_mu_prc(~cellfun('isempty',expnms_mu_prc));
    modelSpace(i).expnms_sa_prc=expnms_sa_prc(~cellfun('isempty',expnms_sa_prc));
end

%% SETUP config files for Observational models
for i = 1:numel(optionsFile.model.space)
    modelSpace(i).name       = optionsFile.model.space{i};
    modelSpace(i).obs        = optionsFile.model.obs{i};
    modelSpace(i).obs_config = eval(optionsFile.model.obs_config{i});

    % Get fieldnames. If a name ends on 'mu', that field defines a prior mean.
    % If it ends on 'sa', it defines a prior variance.
    names  = fieldnames(modelSpace(i).obs_config);
    fields = struct2cell(modelSpace(i).obs_config);
    % find parameter names of mus and sas:
    expnms_mu_obs=[];
    expnms_sa_obs=[];
    n_idx      = 0;
    for k = 1:length(names)
        if regexp(names{k}, 'mu$')
            for l= 1:length(fields{k})
                n_idx = n_idx + 1;
                expnms_mu_obs{1,n_idx} = [names{k},'_',num2str(l)];
            end
        elseif regexp(names{k}, 'sa$')
            for l= 1:length(fields{k})
                n_idx = n_idx + 1;
                expnms_sa_obs{1,n_idx} = [names{k},'_',num2str(l)];
            end
        end
    end
    modelSpace(i).expnms_mu_obs=expnms_mu_obs(~cellfun('isempty',expnms_mu_obs));
    modelSpace(i).expnms_sa_obs=expnms_sa_obs(~cellfun('isempty',expnms_sa_obs));
end

%% find free parameters & convert parameters to native space

for i = 1:size(modelSpace,2)

    % Perceptual model
    prc_idx = modelSpace(i).prc_config.priorsas;
    prc_idx(isnan(prc_idx)) = 0;
    modelSpace(i).prc_idx = find(prc_idx);
    % find names of free parameters:
    modelSpace(i).free_expnms_mu_prc=modelSpace(i).expnms_mu_prc(modelSpace(i).prc_idx);
    modelSpace(i).free_expnms_sa_prc=modelSpace(i).expnms_sa_prc(modelSpace(i).prc_idx);
    c.c_prc = (modelSpace(i).prc_config);
    % transform values into natural space for the simulations
    modelSpace(i).prc_mus_vect_nat = c.c_prc.transp_prc_fun(c, c.c_prc.priormus);
    modelSpace(i).prc_sas_vect_nat = c.c_prc.transp_prc_fun(c, c.c_prc.priorsas);

    % Observational model
    obs_idx = modelSpace(i).obs_config.priorsas;
    obs_idx(isnan(obs_idx)) = 0;
    modelSpace(i).obs_idx = find(obs_idx);
    % find names of free parameters:
    modelSpace(i).free_expnms_mu_obs=modelSpace(i).expnms_mu_obs(modelSpace(i).obs_idx);
    modelSpace(i).free_expnms_sa_obs=modelSpace(i).expnms_sa_obs(modelSpace(i).obs_idx);
    c.c_obs = (modelSpace(i).obs_config);
    % transform values into natural space for the simulations
    modelSpace(i).obs_vect_nat = c.c_obs.transp_obs_fun(c, c.c_obs.priormus);
end

optionsFile.modelSpace = modelSpace;

% NOTE: THIS IS A COPY from hgf function tapas_fitModel:
% --------------------------------------------------------------------------------------------------
    function pr = priorPrep(options)

        % Initialize data structure to be returned
        pr = struct;

        % Store responses and inputs
        pr.u  = options;

        % Calculate placeholder values for configuration files

        % First input
        % Usually a good choice for the prior mean of mu_1
        pr.plh.p99991 = pr.u(1,1);

        % Variance of first 20 inputs
        % Usually a good choice for the prior variance of mu_1
        if length(pr.u(:,1)) > 20
            pr.plh.p99992 = var(pr.u(1:20,1),1);
        else
            pr.plh.p99992 = var(pr.u(:,1),1);
        end

        % Log-variance of first 20 inputs
        % Usually a good choice for the prior means of log(sa_1) and alpha
        if length(pr.u(:,1)) > 20
            pr.plh.p99993 = log(var(pr.u(1:20,1),1));
        else
            pr.plh.p99993 = log(var(pr.u(:,1),1));
        end

        % Log-variance of first 20 inputs minus two
        % Usually a good choice for the prior mean of omega_1
        if length(pr.u(:,1)) > 20
            pr.plh.p99994 = log(var(pr.u(1:20,1),1))-2;
        else
            pr.plh.p99994 = log(var(pr.u(:,1),1))-2;
        end

    end % function priorPrep
% --------------------------------------------------------------------------------------------------



%% colors for plotting
% define colors
optionsFile.col.wh   = [1 1 1];
optionsFile.col.gry  = [0.5 0.5 0.5];
optionsFile.col.tnub = [0 110 182]/255;
optionsFile.col.tnuy = [255 166 22]/255;
optionsFile.col.grn  = [0 0.6 0];



end
