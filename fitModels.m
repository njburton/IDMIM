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
            figdir = fullfile([char(optionsFile.paths.resultsDir),'\mouse',num2str(currMouse),'HGFFit']);
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
            figdir = fullfile([char(optionsFile.paths.resultsDir),'\mouse',num2str(currMouse),'RWFit']);
            save([figdir,'.fig']);
            print([figdir,'.png'], '-dpng');
            
            %Save RW LME

            %Save model fit
            save([char(optionsFile.paths.resultsDir),'\mouse',num2str(currMouse),'RWFit.mat'],'RWFit'); % TO DO: Softcode the filename extension
            
           %% I assume this is not relevant any longer? :
            %%HGF- Plot responses, perceptualModel prior & posterior params

            ResponsePriorPostParamPlot = tiledlayout(2,4,'TileSpacing','Compact');
            title(ResponsePriorPostParamPlot, 'Real mouse');

            %Tile1 - Response of currMouse
            ax1 = nexttile([1,2]);
            histogram(eHGFFit.y);
            title('Responses');

            %Tile2 - Omega percModel prior values of 3 levels of currMouse
            ax2 = nexttile([1,2]);
            X = categorical({'FirstLevel','SecondLevel','ThirdLevel'});
            X = reordercats(X,{'FirstLevel','SecondLevel','ThirdLevel'});
            Y = eHGFFit.c_prc.ommu; %perceptual Omega priors NEED TO INCLUDE VARIANCES
            bar(X,Y,0.5);
            %ylim([-5.0 5.0]); %ideally softcoded

%             if mouse.Omissions
%                 hold on
%                 plot(omissions over the bar graph in yellow with thicker width)
%             end
            title('omega prior of perc model');
            
            %Tile3 - Omega percModel posterior values of 3 levels of currMouse
            nexttile(6,[1,2]);
            X = categorical({'FirstLevel','SecondLevel','ThirdLevel'});
            X = reordercats(X,{'FirstLevel','SecondLevel','ThirdLevel'});
            Y = eHGFFit.p_prc.om; %perceptual omega posteriors
            bar(X,Y,0.5);
            %hold on
            %ylim([-5.0 5.0]); %ideally softcoded
            title('Omega posterior perc');
            
            %Save ResponsePriorPostParamPlot
            figdir = fullfile([char(optionsFile.paths.resultsDir),'\mouse',num2str(currMouse),'ResponsePriorPostParamPlot']);
            save([figdir,'.fig']);
            print([figdir,'.png'], '-dpng');         
            
            %% Create task performance graph tiles
            %Ommissions, responseTimes,
            mousePerformanceTile = tiledlayout(2,3);
            title(mousePerformanceTile, 'Mouse task performance graph','FontSize',20);

            %Tile1 - Response of currMouse
            ax1 = nexttile;
            histogram(eHGFFit.y);
            %ylim([0.3 0.8]);
            title('Responses');
            
            %Tile2 - Omissions
            ax2 = nexttile;
            Omits = length(eHGFFit.irr);
            Y = Omits;
            bar(Omits,Y,0.5);
            %ylim([0.3 0.8]);
            title('Omissions');

            %Tile3 - omissions over task timeline
            ax3 = nexttile;
            eHGFFit.irr;
            %Y = 
            title('omissions over task timeline');
                        
            %Tile 4 - responseTimes over Trial stemplot
            ax4 = nexttile([1 3]);
            responseTimes = ExperimentTaskTable.ResponseTime; 
            responseTimes(responseTimes(:,1) < 0.0) = 0.0;
            stem(responseTimes,'filled');
            %ylim([0.0 15]);
            title('ResponseTimes (TrialStartTime - LeverPressTime');
         
            %Save tiledPlot      
            figdir = fullfile([char(optionsFile.paths.resultsDir),'\mouse',num2str(currMouse),'HGFFitABA1']);
            save([figdir,'.fig'])
            print([figdir,'.png'], '-dpng')

            %% Compute CoarseChoiceStrategies 
            % lose-switch, lose-stay, win-switch, win-stay stickiness
            % explore/exploit
            % and plot on graph
            mouseCoarseChoiceStratTile = tiledlayout(2,4,'TileSpacing','Compact');
            %Tile 1 - lose-switch, lose-stay, win-switch, win-stay
            %Omits)
            nexttile([1,2])
            histogram(ChoiceColumn.Choices);

            %Tile 1 - 
            %Omits)
            nexttile([1,2])
            histogram(ChoiceColumn.Choices);

            %Tile 3 - 
            %Omits)
            nexttile(6,[1,2])
            histogram(ChoiceColumn.Choices);

            %%Win-stay
            % Initialize counters
            count_stay_win = 0; % Counter for P(stay | win)
            
         

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