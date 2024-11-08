function optionsFile = runOptions()

%% runOptions
% - set all relevant paths, global variables
% - specify what analysis steps should be executed when running "runAnalysis"
% - make directories and folderstructure for data if needed
%
%  SYNTAX:          runAnalysis
%
%  OUTPUT:    optionsFile.mat
%
%
% Original: 30/5/2023; Katharina Wellstein
% Amended: 23/2/2024; Nicholas Burton
% -------------------------------------------------------------------------
%
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


%% what steps to do?
optionsFile.doOptions        = 1;
optionsFile.setupModels      = 0;
optionsFile.doGetData        = 0;
optionsFile.doSimulations    = 0;
optionsFile.doModelInversion = 0;
optionsFile.doParamRecovery  = 0;
optionsFile.doParamInvestig  = 0;
optionsFile.doBMS            = 0;

%%
if optionsFile.doOptions == 1
    disp('setting new paths...');
    optionsFile.paths.projDir               = [pwd,filesep];
    optionsFile.paths.outputDir             = [optionsFile.paths.projDir,'output',filesep];
    optionsFile.paths.databaseDir           = [optionsFile.paths.outputDir,'database'];
    optionsFile.paths.mouseModelFitFilesDir = [optionsFile.paths.databaseDir,filesep,'modelFitFiles'];
    optionsFile.paths.mouseMatFilesDir      = [optionsFile.paths.databaseDir,filesep,'mouseMatFiles'];
    optionsFile.paths.resultsDir            = [optionsFile.paths.outputDir,'results'];
    optionsFile.paths.plotsDir              = [optionsFile.paths.outputDir,'plots'];
    optionsFile.paths.toolboxDir            = [optionsFile.paths.projDir,filesep,'toolboxes'];
    optionsFile.paths.HGFtoolboxDir         = [optionsFile.paths.toolboxDir,filesep,'HGF'];
    optionsFile.paths.VKFtoolboxDir         = [optionsFile.paths.toolboxDir,filesep,'VKF'];
    optionsFile.paths.SPMtoolboxDir         = [optionsFile.paths.toolboxDir,filesep,'spm'];
    optionsFile.paths.utilsDir              = [optionsFile.paths.projDir,'utils'];
    optionsFile.paths.genTrajDir            = [optionsFile.paths.utilsDir,'generateTrajectories'];

    % Path to directory containing files to analyse from mouse decision-making task
    % COMMENT KW: softcode this, so that anyone could run this. If the file
    % was in the projectDir and any of the sub directories,
    % 'C:\Users\c3200098\Desktop',filesep, could be replaced by optionsFile.paths.projDir 
    optionsFile.paths.dataToAnalyse   = [optionsFile.paths.projDir,'dataToAnalyse']; %Local file on Desktop of UoN issued PhD laptop

    %Set cohort info
    optionsFile.cohort.nSize          = 20; % sample size
    optionsFile.cohort.cohort          = {'2023_UCMS2', '2024_HGFPilot3'}; %Each group represents an individual experiment/cohort
    % hardcode sex for each mouse
    optionsFile.cohort.maleMice       = {'1.1','1.2','2.1','3.1','3.2','3.3'};
    optionsFile.cohort.femaleMice     = {'4.2','5.1','5.2','5.3','5.4','5.5'};
    %hardcode test group for each mouse
    optionsFile.cohort.controlGroup   = {'1.1','1.2','2.1','3.1','3.2','3.3',...
                                            '4.2','5.1','5.2','5.3','5.4','5.5'};
    optionsFile.cohort.treatmentGroup = {''};



    % Set Task info
    optionsFile.task.taskList                        = {'NJB_HGF_TrainingTask_RL','NJB_HGF_TrainingTask_LL - Copy', 'NJB_HGF_TestTaskA','NJB_HGF_TestTaskB'}; 
    optionsFile.task.nTrials                         = 280; %total task trials
    optionsFile.task.MouseID                         = NaN(optionsFile.cohort.nSize,1);
    optionsFile.task.trialDuration                   = 13; % in seconds
    optionsFile.task.totalTaskDuration               = 3640; % in seconds

      % simulation options
    optionsFile.simulations.nSamples                 = 50;
    optionsFile.simulations.simResultsDir            = [optionsFile.paths.outputDir,'simResults'];

    if ~exist(optionsFile.simulations.simResultsDir,'dir')
        mkdir(optionsFile.simulations.simResultsDir)
    end

    % Markers used to identify arrays of interest from raw Med-PC data (.txt file).
    optionsFile.dataFile.taskNameLocation            = 13; %taskNameMSN
    optionsFile.dataFile.outcomeOffset               = 332; %Outcome G
    optionsFile.dataFile.choiceOffset                = 615; %Choice H
    optionsFile.dataFile.trialStartTimeOffset        = 898; % TrialStartTime I
    optionsFile.dataFile.recepticalBeamBreakOffset   = 1181; % RecepticalBeamBreak J
    optionsFile.dataFile.leverPressTimeOffset        = 1464; %LeverPressTime K

    % optimization algorithm
    addpath(genpath(optionsFile.paths.HGFtoolboxDir));
    addpath(genpath(optionsFile.paths.VKFtoolboxDir));
    optionsFile.hgf.opt_config = eval('tapas_quasinewton_optim_config');

    % seed for random number generator
    optionsFile.rng.idx        = 1; % Set counter for random number states
    optionsFile.rng.settings   = rng(123, 'twister');
    optionsFile.rng.nRandInit  = 100;

    % define model and its related functions
    optionsFile.setupModels         = [];
    optionsFile.model.spaceTAPAS    = {'HGF_3LVL','HGF_2LVL','RW'};% all models in modelspace
    optionsFile.model.spaceVKF      = {'VKF','vkf_bin'};
    optionsFile.model.prc           = {'tapas_ehgf_binary','tapas_ehgf_binary','tapas_rw_binary','vkf_binary'};
    optionsFile.model.prc_config    = {'tapas_ehgf_binary_config_3LVL','tapas_ehgf_binary_config_2LVL','tapas_rw_binary_config'};
    optionsFile.model.obs	        = {'tapas_unitsq_sgm'};
    optionsFile.model.obs_config    = {'tapas_unitsq_sgm_config'};
    optionsFile.model.opt_config    = {'tapas_quasinewton_optim_config'};
    optionsFile.plot(1).plot_fits   = @tapas_ehgf_binary_plotTraj;
    optionsFile.plot(2).plot_fits   = @tapas_ehgf_binary_plotTraj;
    optionsFile.plot(3).plot_fits   = @tapas_rw_binary_plotTraj;
    modelSpace = struct();

    optionsFile.fileName.rawFitFile = {'eHGF_3LVLFit','eHGF_2LVLFit','RWFit'};

    % Volatile kalman filter parameters informed by paper, Figure 7D
    optionsFile.modelVKF.lambda     = 0.1;  %volatility learning rate
    optionsFile.modelVKF.v0         = 0.5; % initial volatility
    optionsFile.modelVKF.omega      = 0.2;  % noise parameter


    save([optionsFile.paths.projDir,'optionsFile.mat'],"optionsFile");

end

%% SETUP config files for Perceptual models
if optionsFile.setupModels == 1
    for i = 1:numel(optionsFile.model.spaceTAPAS)
        modelSpace(i).prc           = optionsFile.model.prc{i};
        modelSpace(i).prc_config    = eval(optionsFile.model.prc_config{i});
        pr                          = priorPrep(optionsFile.input.inputs);

        % Replace placeholders in parameter vectors with their calculated values
        modelSpace(i).prc_config.priormus(modelSpace(i).prc_config.priormus==99991)  = pr.plh.p99991;
        modelSpace(i).prc_config.priorsas(modelSpace(i).prc_config.priorsas==99991)  = pr.plh.p99991;

        modelSpace(i).prc_config.priormus(modelSpace(i).prc_config.priormus==99992)  = pr.plh.p99992;
        modelSpace(i).prc_config.priorsas(modelSpace(i).prc_config.priorsas==99992)  = pr.plh.p99992;

        modelSpace(i).prc_config.priormus(modelSpace(i).prc_config.priormus==99993)  = pr.plh.p99993;
        modelSpace(i).prc_config.priorsas(modelSpace(i).prc_config.priorsas==99993)  = pr.plh.p99993;

        modelSpace(i).prc_config.priormus(modelSpace(i).prc_config.priormus==-99993) = -pr.plh.p99993;
        modelSpace(i).prc_config.priorsas(modelSpace(i).prc_config.priorsas==-99993) = -pr.plh.p99993;

        modelSpace(i).prc_config.priormus(modelSpace(i).prc_config.priormus==99994)  = pr.plh.p99994;
        modelSpace(i).prc_config.priorsas(modelSpace(i).prc_config.priorsas==99994)  = pr.plh.p99994;

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
    % SETUP config files for Observational models
    for i = 1:numel(optionsFile.model.space)
        modelSpace(i).name       = optionsFile.model.spaceTAPAS{i};
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
    % Find free parameters & convert parameters to native space
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

    % colors for plotting
    optionsFile.col.wh   = [1 1 1];
    optionsFile.col.gry  = [0.5 0.5 0.5];
    optionsFile.col.tnub = [186 85 211]/255;  %186,85,211 purple %blue 0 110 182
    optionsFile.col.tnuy = [255 166 22]/255;
    optionsFile.col.grn  = [0 0.6 0];
    save([optionsFile.paths.projDir,'optionsFile.mat'],"optionsFile");

    optionsFile.doOptions = 0;

end
%% 
if optionsFile.doGetData == 1
    load('optionsFile.mat');
    optionsFile = getData(optionsFile);
    optionsFile.doOptions     = 0;
    optionsFile.doSimulations = 0;
    optionsFile.doModelInversion = 0;
    optionsFile.doParamRecovery  = 0;
    optionsFile.doParamInvestig  = 0;
    optionsFile.doBMS = 0;
    save([optionsFile.paths.projDir,'optionsFile.mat'],"optionsFile");
    optionsFile.doGetData     = 0;
end

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

end
