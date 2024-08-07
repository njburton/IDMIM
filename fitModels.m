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
            figdir = fullfile([char(optionsFile.paths.plotsDir),'\mouse',num2str(currMouse),'HGFFit']);
            save([figdir,'.fig']);
            print([figdir,'.png'], '-dpng');
                      
            %Save model fit
            save([char(optionsFile.paths.resultsDir),'\mouse',num2str(currMouse),'HGFFit.mat'],'eHGFFitTrajPlot'); % TO DO: Softcode the filename extension
            
                        %Create table and save HGF LME
%             LMEdiffVarTypes = {'string','double','double'};
%             LMEdiffVarNames = {'Treatment','HGFLME','RWLME'};
%             LMEdiff = table('Size',[22 3],'VariableTypes', LMEdiffVarTypes,'VariableNames',LMEdiffVarNames);
%             LMEdiff.HGFLME = eHGFFit.optim.LME;
%             
%             HGFLME = nan(22,1);
%             RWLME = nan(22,1);
% 
%             for p = 1:22
%                 HGFLME(p,1) = eHGFFit.optim.LME;
%             end
% 
%             T = table(HGFLME,RWLME,'VariableNames',{'HGFLME','RWLME'});

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
            figdir = fullfile([char(optionsFile.paths.plotsDir),'\mouse',num2str(currMouse),'RWFit']);
            save([figdir,'.fig']);
            print([figdir,'.png'], '-dpng');
            
            %Save RW LME

            %Save model fit
            save([char(optionsFile.paths.resultsDir),'\mouse',num2str(currMouse),'RWFit.mat'],'RWFit'); % TO DO: Softcode the filename extension    
            
            
         

        catch
            disp('fit failed in some way...'); 
            % Fit failed in some way - likely parameters outside of valid
            % variational range
            %             badFitCount = badFitCount + 1;
            %             listBadFits(badFitCount) = MouseID;
        end

    else
        disp('invalid mouse');
    end
end