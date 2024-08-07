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
% _________________________________________________________________________
% =========================================================================

%% SET DIRECTORY PATHS FOR PROJECT, RAWDATA, RESULTS & PLOTS
% Set paths of directories
disp('setting paths...');
optionsFile.paths.projDir         = 'C:\Users\c3200098\Desktop\projects\IDMIM';
optionsFile.paths.rawDataStoreDir = 'C:\Users\c3200098\Desktop\projects\IDMIM\rawDataStore';
optionsFile.paths.resultsDir      = 'C:\Users\c3200098\Desktop\projects\IDMIM\data\results';
optionsFile.paths.plotsDir        = 'C:\Users\c3200098\Desktop\projects\IDMIM\data\plots';
optionsFile.paths.rawDataDir      = 'C:\Users\c3200098\Desktop\data\ABA2_R\'; 
optionsFile.paths.toolbox         = 'C:\Users\c3200098\Desktop\projects\IDMIM\HGF';

% task names
optionsFile.Task          = load('C:\Users\c3200098\Desktop\results\resultsANS\HGF-ANS-latest.mat', 'seqABALeftLever');
optionsFile.Task.FileName = 'testResults2_ABA2_R_corrrectedVariables.xlsx'; % TO DO: make this more streamlined 
optionsFile.Task.task     = 'ABA1_L';   %Recode to ABA2_R
optionsFile.Task.nTrials  = 180;
optionsFile.Task.nSize    = 22;
optionsFile.Task.MouseID  = NaN(optionsFile.Task.nSize,1);
optionsFile.Task.BinarySeq = 'binSeqABA_BothLevers.csv'; % TO DO: make this more streamlined for when more than one task

% simulation options
optionsFile.simulations.nSamples      = 100;
optionsFile.simulations.simResultsDir = 'C:\Users\c3200098\Desktop\projects\IDMIM\sdata\imResults';

if ~exist(optionsFile.simulations.simResultsDir,'dir')
    mkdir(optionsFile.simulations.simResultsDir)
end

%% Markers used to identify arrays of interest from raw Med-PC data (.txt file).
optionsFile.DataFile.ChoiceMarker   = 'H:'; %Choice_ABA2
optionsFile.DataFile.OutcomeMarker  = 'G:'; %Outcome_ABA2
optionsFile.DataFile.LeverPressTimeMarker = 'K:'; %LeverPressTime_ABA2
optionsFile.DataFile.TrialStartTimeMarker = 'I:'; % TrialStartTime_ABA2

optionsFile.fileName.rawFile = 'HGFFitABA1';

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

%% Find free parameters & convert parameters to native space

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

%% NOTE: THIS IS A COPY from hgf function tapas_fitModel:
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
