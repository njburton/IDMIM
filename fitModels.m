function fitModels(optionsFile)
%% fitModels
%
%  SYNTAX:  fitModels
%
%  INPUT:  optionsFile
%
%  OUTPUT:
%
% Original: 30/5/2023; Katharina Wellstein
% Amended: 23/2/2024; Nicholas Burton
% -------------------------------------------------------------------------
%
% Copyright (C) 2024 - need to fill in details
%
% _________________________________________________________________________
% =========================================================================

try
    load('optionsFile.mat');
catch
    optionsFile = runOptions; % specifications for this analysis
end

ModelFitTableVarTypes = {'string','double','double'};
ModelFitTableVarNames = {'MouseID','eHGFFitLME','RWFitLME'};
ModelFitTable = table('Size',[20 3],'VariableTypes', ModelFitTableVarTypes,'VariableNames',ModelFitTableVarNames);

for n = 1:optionsFile.Task.nSize

    if ~isnan(optionsFile.Task.MouseID(n))
        currMouse = optionsFile.Task.MouseID(n);
        disp(['fitting mouse ', num2str(currMouse), ' (',num2str(n),' of ',num2str(optionsFile.Task.nSize),')']);

        load([char(optionsFile.paths.resultsDir),'\mouse',num2str(currMouse)]);


        try
            %% HGF model fit
            disp('fitting HGF to data...');
            eHGFFit = tapas_fitModel(ExperimentTaskTable.Choice, ...
                ExperimentTaskTable.RewardingLeverSide, ...
                'tapas_ehgf_binary_config', ...
                'tapas_unitsq_sgm_config', ...
                'tapas_quasinewton_optim_config');

            %Plot standard HGF trajectory plot
            tapas_hgf_plotTraj_mod(eHGFFit);
            figdir = fullfile([char(optionsFile.paths.plotsDir),'\mouse',num2str(currMouse),'_HGFFit']);
            save([figdir,'.fig']);
            print([figdir,'.png'], '-dpng');
            close all;

            %Save model fit
            save([char(optionsFile.paths.resultsDir),'\mouse',num2str(currMouse), optionsFile.fileName.rawFitFile],'eHGFFit'); % TO DO: Softcode the filename extension

            
            %Add currMouse ID to ModelFitTable column
            ModelFitTable.MouseID(n) = currMouse
            %SaveHGFFit LME to ModelFitTable
            ModelFitTable.eHGFFitLME(n) = eHGFFit.optim.LME


            %% Rescorla-Wagner fit
            % COMMENT: this is great, but we could do this in a loop later on. This
            % is one of the models we can loop over
            %RW
            disp('fitting RW to data...');
            RWFit = tapas_fitModel(ExperimentTaskTable.Choice, ...
                ExperimentTaskTable.RewardingLeverSide, ...
                'tapas_rw_binary_config', ...
                'tapas_unitsq_sgm_config', ...
                'tapas_quasinewton_optim_config');

            %Plot standard RW trajectory plot
            tapas_rw_binary_plotTraj(RWFit);
            figdir = fullfile([char(optionsFile.paths.plotsDir),'\mouse',num2str(currMouse),'_RWTrajPlot']);
            save([figdir,'.fig']);
            print([figdir,'.png'], '-dpng');
            close all;

            %Save model fit
            save([char(optionsFile.paths.resultsDir),'\mouse',num2str(currMouse),'RWFit.mat'],'RWFit'); % TO DO: Softcode the filename extension

%             %plot da
%             area(RWFit.traj.da)
%             title('PredictionError');
%             xlabel('Trial');
%             ylabel('prediction error delta ');
%             %Save plot
%             figdir = fullfile([char(optionsFile.paths.plotsDir),'\mouse',num2str(currMouse),'_RW_PredictionErrorPlot']);
%             save([figdir,'.fig']);
%             print([figdir,'.png'], '-dpng');
%             close all;
% 
%             %plot value
%             area(RWFit.traj.v)
%             title('Value of RightLever');
%             xlabel('Trial');
%             ylabel('Value');
%             %Save plot
%             figdir = fullfile([char(optionsFile.paths.plotsDir),'\mouse',num2str(currMouse),'_RW_ValuePlot']);
%             save([figdir,'.fig']);
%             print([figdir,'.png'], '-dpng');
%             close all;

            %Save RW LME to vector with mice as rows
            ModelFitTable.RWFitLME(n) = RWFit.optim.LME


        catch
            disp('fit failed in some way...');
            % Fit failed in some way - likely parameters outside of valid
            % variational range
            %             badFitCount = badFitCount + 1;
            %             listBadFits(badFitCount) = MouseID;
        end

    else
        disp('invalid mouse. Could be allocated as a NaN in the MouseID vector');
    end
end





LMEHeatMap = heatmap(ModelFitTable,"eHGFFitLME","RWFitLME")