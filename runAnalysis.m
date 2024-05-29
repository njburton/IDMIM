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

disp('starting analysis pipeline...');

diaryName = ['diary_', datestr(datetime('now'))];
diary on
restoredefaultpath();


%% Initialise options for running this function
%
optionsFile = runOptions;


%% Import operant task choice data
% import manipulated mouseID tables
disp('loading task data...');


% Construct treatment groups (treatmentGroupMatrix) by looping through treatmentCondition var.
%. Construct sex groups (sexGroupMatrix) by looping through sexCondition var.
disp('splitting tasks into phases...');
% break down task into phases (A vs. B vs. A)
% Phase A = 1-59
% Phase B = 60-120
% Phase A = 121-180

%% Extract model based quantities
% Fit mouse choice data using the following models for comparison
% eHGF, eHGF without volatility, eHGF without perceptual uncertainty, eHGF
% without volatility & perceptual uncertainty, Rescorla-Wagner, Sutton K1
addpath(genpath(optionsFile.paths.HGFDir));

for n = 1:1 % optionsFile.Task.nSize
    
    if ~isnan(optionsFile.Task.MouseID(n))
        currMouse = optionsFile.Task.MouseID(n);
        disp(['fitting mouse ', num2Str(currMouse), ' (',num2str(n),' of ',optionsFile.Task.nSize,')']);

        load([char(optionsFile.paths.resultsDir),'\mouse',num2Str(currMouse)]);

        try
            %% Perceptual inference models
            % eHGF Fit est = tapas_fitModel(responses, inputs)
            eHGFFit = tapas_fitModel(ExperimentTaskTable.Choice, ...
                ExperimentTaskTable.RewardingLeverSide, ...
                'tapas_ehgf_binary_config', ...
                'tapas_unitsq_sgm_config', ...
                'tapas_quasinewton_optim_config');

            %Plot standard HGF 
            tapas_ehgf_plotTraj(eHGFFit);
            h = sgtitle(append('Subject ', char(currMouse), ... % why do you call that subject?
                      partData(subj).subjCondition{nVar}));
            set(h, 'fontweight', 'bold');

            %Save model fit
            save([char(optionsFile.paths.resultsDir),'\mouse',num2Str(currMouse),'HGFFitABA1.mat'],'eHGFFit'); % TO DO: Softcode the filename extension

            % eHGF without volatility Fit - est = tapas_fitModel(responses, inputs)
            %             eHGF_noVolatility_ABA1 = tapas_fitModel(ExperimentTaskTable.Choice,ExperimentTaskTable.RewardingLeverSideABA1, ...
            %                                             'tapas_ehgf_binary_config', ...
            %                                             'tapas_unitsq_sgm_config', ...
            %                                             'tapas_quasinewton_optim_config');
            %
            %
            %             save([char(optionsFile.paths.HGFDir),'\eHGF_noVolatility_ABA1.mat'],'eHGF_noVolatility_ABA1');
            %
            %             % eHGF without perceptual uncertainty Fit - est = tapas_fitModel(responses, inputs)
            %             eHGF_noPercUnc_ABA1 = tapas_fitModel(ExperimentTaskTable.Choice,ExperimentTaskTable.RewardingLeverSideABA1, ...
            %                                             'tapas_ehgf_binary_config', ...
            %                                             'tapas_unitsq_sgm_config', ...
            %                                             'tapas_quasinewton_optim_config');
            %
            %
            %             save([char(optionsFile.paths.HGFDir),'\eHGF_noPercUnc_ABA1.mat'],'eHGF_noPercUnc_ABA1');
            %
            %             % eHGF without perceptual uncertainty and volatility Fit - est = tapas_fitModel(responses, inputs)
            %             eHGF_noPercUncOrVolatility_ABA1 = tapas_fitModel(ExperimentTaskTable.Choice,ExperimentTaskTable.RewardingLeverSideABA1, ...
            %                                             'tapas_ehgf_binary_config', ...
            %                                             'tapas_unitsq_sgm_config', ...
            %                                             'tapas_quasinewton_optim_config');
            %
            %
            %             save([char(optionsFile.paths.HGFDir),'\eHGF_noPercUncOrVolatility_ABA1.mat'],'eHGF_noPercUncOrVolatility_ABA1');
            %
            %            %% Reinforcement learning models
            %            %RescorlaWagnerFit - est = tapas_fitModel(responses, inputs)
            %             RWFitABA1 = tapas_fitModel(ExperimentTaskTable.Choice,ExperimentTaskTable.RewardingLeverSideABA1, ...
            %                                             'tapas_rw_binary_config', ...
            %                                             'tapas_unitsq_sgm_config', ...
            %                                             'tapas_quasinewton_optim_config');
            %
            %
            %             save([char(optionsFile.paths.HGFDir),'\RWFitABA1.mat'],'RWFitABA1');
            %
            %             %RescorlaWagnerDualFit - est = tapas_fitModel(responses, inputs)
            %             RWFitABA1 = tapas_fitModel(ExperimentTaskTable.Choice,ExperimentTaskTable.RewardingLeverSideABA1, ...
            %                                             'tapas_rw_binary_dual_config', ...
            %                                             'tapas_unitsq_sgm_config', ...
            %                                             'tapas_quasinewton_optim_config');
            %
            %
            %             save([char(optionsFile.paths.HGFDir),'\RWDualFitABA1.mat'],'RWDualFitABA1');
            %
            %
            %            % SuttonK1 Fit - est = tapas_fitModel(responses, inputs)
            %            SuttonK1FitABA1 = tapas_fitModel(ExperimentTaskTable.Choice,ExperimentTaskTable.RewardingLeverSideABA1, ...
            %                                             'tapas_sutton_k1_binary_config', ...
            %                                             'tapas_unitsq_sgm_config', ...
            %                                             'tapas_quasinewton_optim_config');
            %
            %
            %             save([char(optionsFile.paths.HGFDir),'\SuttonK1FitABA1.mat'],'SuttonK1FitABA1');

        catch
            % Fit failed in some way - likely parameters outside of valid
            % variational range
            %             badFitCount = badFitCount + 1;
            %             listBadFits(badFitCount) = MouseID;
        end

    else
        disp('invalid mouse');
    end
end


%% Extract behavioural quantities
% Calculate win-stay lose-shift for each mouse & sex & group













%% Model recovery analysis
% Recover model parameters, model convergence &
parameter_recovery(optionsFile);

%% plotting
% Generate heat map showing LME for each model comparison
% Plot Traj for each mouseMatrix and treatmentGroupMatrix
% Plot softmax inverse temperature  figure
% plot win-stay lose-shift

%% simulations




end

