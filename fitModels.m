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
disp('fitting HGF to data...');
try
    load('optionsFile.mat');
catch
    optionsFile = runOptions; % specifications for this analysis
end

%CreatemodelFit table to capture LME's and other important free parameters
%in models
ModelFitTableVarTypes = {'string','double','double','double'};
ModelFitTableVarNames = {'MouseID','eHGFFitLME','RWFitLME','RWFit_Alpha'};
ModelFitTable = table('Size',[optionsFile.Task.nSize length(ModelFitTableVarNames)],'VariableTypes', ModelFitTableVarTypes,'VariableNames',ModelFitTableVarNames);


for n = 1:optionsFile.Task.nSize

    if ~isnan(optionsFile.Task.MouseID(n))
        currMouse = optionsFile.Task.MouseID(n);
        disp(['fitting mouse ', num2str(currMouse), ' (',num2str(n),' of ',num2str(optionsFile.Task.nSize),')']);

        load([char(optionsFile.paths.resultsDir),'\mouse',num2str(currMouse)]);

        try
%             %% HGF model fit
%             disp('fitting HGF to data...');
%             eHGFFit = tapas_fitModel(ExperimentTaskTable.Choice, ...
%                 ExperimentTaskTable.RewardingLeverSide, ...
%                 'tapas_ehgf_binary_config', ...
%                 'tapas_unitsq_sgm_config', ...
%                 'tapas_quasinewton_optim_config');
% 
%             %Plot standard HGF trajectory plot
%             tapas_hgf_plotTraj_mod(eHGFFit);
%             figdir = fullfile([char(optionsFile.paths.plotsDir),'\mouse',num2str(currMouse),'_HGFFit']);
%             save([figdir,'.fig']);
%             print([figdir,'.png'], '-dpng');
%             close all;
% 
%             %Save model fit
%             save([char(optionsFile.paths.resultsDir),'\mouse',num2str(currMouse), optionsFile.fileName.rawFitFile],'eHGFFit'); % TO DO: Softcode the filename extension
% 
%             %Add currMouse ID to ModelFitTable column
%             ModelFitTable.MouseID(n) = currMouse
%             %SaveHGFFit LME to ModelFitTable
%             ModelFitTable.eHGFFitLME(n) = eHGFFit.optim.LME

            
            %% Rescorla-Wagner fit
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


            %Save RW LME to vector with mice as rows
            ModelFitTable.RWFitLME(n) = RWFit.optim.LME


            %Save RWFit alpha (learning rate)
            ModelFitTable.RWFit_Alpha(n) = RWFit.p_prc.al



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


%Plot RWFit alpha (learning rate values per treatmentgroup)
% for m = 1:length(optionsFile.Task.MouseID)
%     if endsWith(num2str(ModelFitTable.MouseID(m)),"2")  %If MouseID ends in "2" and is UCMS
%         bar(ModelFitTable,ModelFitTable.RWFit_Alpha(m,4),Color="#7E2F8E"); hold on  %Plot alpha value in purple
%     else   %Or if MouseID doesn't end in 2 and is considered control
%         bar(ModelFitTable,ModelFitTable.RWFit_Alpha(m),Color="#000000"); hold on %Plot alpha value in black
%     end
% end

p = bar(ModelFitTable.RWFit_Alpha,0.5, "FaceColor","flat");
for k = 1:10
p.CData(k,:) = [.5 0 .5];
end
title('RW alpha (learning rate) by TreatmentGroup');
xlabel('MouseID. Purple are UCMS. Blue are control');
ylabel('RW alpha (learning rate) value');
figdir = fullfile([char(optionsFile.paths.plotsDir),'\mouse',num2str(currMouse),'_RWFit_AlphaByTreatmentGroup']);
save([figdir,'.fig']);
print([figdir,'.png'], '-dpng');
close all;


%Plot LMEs
%LMEHeatMap = heatmap(ModelFitTable,"eHGFFitLME","RWFitLME")