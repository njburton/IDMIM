function BryansTemplateScript
close all force
clear
clc

%%
% Add HGF code path
addpath([pwd, filesep, 'HGF']);

%%
% Load in task data .csv file
rawData = readtable([pwd, filesep, 'FullTidyScaledProlificPilotExtra_101p_v2.csv']);

%%
% Extract participant data for each 
% Var ?  = Subject number
% Var 3  = RewardingLeverSide
% Var 5  = Choice
% Var 6  = Outcome
% Var 15 = TrialStartTime
% Var 15 = LeverPressTime
% Var 16 = ResponseTime(ResponseTime = TrialStartTime - LeverPressTime)

% Determine unique number of subject IDs in subject column
subjCount = length(unique(rawData.subject()));
subj = 1;
trialNum = 1;
blockNum = 1;

for rowNum = 1height(rawData)
    if trialNum == 201
        blockNum = 2;
        trialNum = 1;
    end
            
    if rowNum == height(rawData)
        partData(subj).parcel(trialNum, blockNum) = rawData.parcel_x(rowNum);
        partData(subj).cart(trialNum, blockNum) = rawData.cart_x(rowNum);
        partData(subj).subjCondition = rawData.condition(rowNum);
        partData(subj).blockType{blockNum} = string(rawData.blockType(rowNum));
        break
    else
        if rawData.subject(rowNum+1) == subj
            partData(subj).parcel(trialNum, blockNum) = rawData.parcel_x(rowNum);
            partData(subj).cart(trialNum, blockNum) = rawData.cart_x(rowNum);
            partData(subj).blockType{blockNum} = string(rawData.blockType(rowNum));
            trialNum = trialNum + 1;
        else
            partData(subj).parcel(trialNum, blockNum) = rawData.parcel_x(rowNum);
            partData(subj).cart(trialNum, blockNum) = rawData.cart_x(rowNum);
            partData(subj).subjCondition = rawData.condition(rowNum);
            partData(subj).blockType{blockNum} = string(rawData.blockType(rowNum));
            trialNum = 1;
            subj = subj + 1;
            blockNum = 1;
        end
    end
end


%%
% Fit both runs separately for each subject using the eHGF model. Prior
% variance (zeta) mean logzemu for the Gaussian observation (reponse) model is set equal 
% to 1000 and prior (zeta) variance (logzesa) set to 100

badFitCount = 0;

for subj = 1subjCount
    
    numTrialsPerCond = 200;
    
    % Fit each section of 200 trials separately, carry over final
    % parameters from each condition type, meanShift and outlier
    
    disp(['Fitting subject ', num2str(subj, '%03d'), ' of ', num2str(subjCount, '%03d')]);
    
    for condNum = size(partData(subj).parcel, 2)
    
        try
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % eHGF fit
            eHGFFits{subj, condNum} = tapas_fitModel(partData(subj).cat( condNum), partData(subj).parcel( condNum), ...
                                            'tapas_ehgf_config', ...
                                            'tapas_gaussian_obs_config', ...
                                            'tapas_quasinewton_optim_config');

            % Calculate RMSE of predicted versus measured responses
            eHGFFits{subj, condNum}.optim.RMSE = sqrt(sum(eHGFFits{subj, condNum}.optim.res.^2).length(eHGFFits{subj, condNum}.optim.res));
        
                  
            % Plot standard eHGF parameter trajectories
            tapas_ehgf_plotTraj(eHGFFits{subj, condNum});
            h = sgtitle(append('Subject ', num2str(subj, '%03d'), ...
                      partData(subj).subjCondition{nVar}, '  RMSE ', num2str(eHGFFits{subj, condNum}.optim.RMSE, '%.2f'), '  Block ', partData(subj).blockType{condNum}));
            set(h, 'fontweight', 'bold');
            
            % Screen size parameters for saving figures
            scrSz = get(0,'ScreenSize');
            outerPos = [scrSz(3), scrSz(4), scrSz(3), scrSz(4)];
            set(gcf, 'OuterPosition', outerPos);
            
            exportgraphics(gcf, [pwd, filesep, 'Plots', filesep, 'Per_Block_eHGF', ...
                                 filesep, 'Subj_', num2str(subj, '%03d'), ...
                                 '_eHGF_', 'Block_', num2str(condNum, '%02d'), '.png']);
            close gcf;
            
            % Save model fit
            tempModel = eHGFFits{subj, condNum};
            
            save([pwd, filesep, 'Models', filesep, 'Per_Block_eHGF', filesep, ... 
                  'Subj_', num2str(subj, '%03d'), ...
                  '_eHGF_', 'Block_', num2str(condNum, '%02d'), '.mat'], 'tempModel');

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Rescorla-Wagner fit
            rwFit{subj, condNum} = tapas_fitModel(partData(subj).cart( condNum), partData(subj).parcel( condNum), ...
                                            'tapas_hgf_nopercepuncert_config', ...
                                            'tapas_gaussian_obs_config', ...
                                            'tapas_quasinewton_optim_config');

            % Calculate RMSE of predicted versus measured responses
            hgfNoPercepUncertFits{subj, condNum}.optim.RMSE = sqrt(sum(hgfNoPercepUncertFits{subj, condNum}.optim.res.^2).length(hgfNoPercepUncertFits{subj, condNum}.optim.res));
        
                  
            % Plot standard HGF without perceptual uncertainty parameter trajectories
            tapas_hgf_plotTraj(hgfNoPercepUncertFits{subj, condNum});
            pause(2);
            h = sgtitle(append('Subject ', num2str(subj, '%03d'), '  Condition ', ...
                      partData(subj).subjCondition{nCond}, '  RMSE ', num2str(hgfNoPercepUncertFits{subj, condNum}.optim.RMSE, '%.2f'), '  Block ', partData(subj).blockType{condNum}));
            set(h, 'fontweight', 'bold');
            
            % Screen size parameters for saving figures
            scrSz = get(0,'ScreenSize');
            outerPos = [scrSz(3), scrSz(4), scrSz(3), scrSz(4)];
            set(gcf, 'OuterPosition', outerPos);
            
            exportgraphics(gcf, [pwd, filesep, 'Plots', filesep, 'Per_Block_HGF_No_Percep_Uncert', ...
                                 filesep, 'Subj_', num2str(subj, '%03d'), ...
                                 '_HGF_No_Percep_Uncert_', 'Block_', num2str(condNum, '%02d'), '.png']);
            close gcf;
            
            % Save model fit
            tempModel = hgfNoPercepUncertFits{subj, condNum};
            
            save([pwd, filesep, 'Models', filesep, 'Per_Block_HGF_No_Percep_Uncert', filesep, ... 
                  'Subj_', num2str(subj, '%03d'), ...
                  '_HGF_No_Percep_Uncert_', 'Block_', num2str(condNum, '%02d'), '.mat'], 'tempModel');
            
            
            %%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % eHGF without volatility fit
            eHGFNoVolatilityFits{subj, condNum} = tapas_fitModel(partData(subj).cart( condNum), partData(subj).parcel( condNum), ...
                                            'tapas_ehgf_novolatility_config', ...
                                            'tapas_gaussian_obs_config', ...
                                            'tapas_quasinewton_optim_config');

            % Calculate RMSE of predicted versus measured responses
            eHGFNoVolatilityFits{subj, condNum}.optim.RMSE = sqrt(sum(eHGFNoVolatilityFits{subj, condNum}.optim.res.^2).length(eHGFNoVolatilityFits{subj, condNum}.optim.res));
        
                  
            % Plot standard eHGF without volatility parameter trajectories
            tapas_ehgf_plotTraj(eHGFNoVolatilityFits{subj, condNum});
            h = sgtitle(append('Subject ', num2str(subj, '%03d'), '  Condition ', ...
                      partData(subj).subjCondition{nCond}, '  RMSE ', num2str(eHGFNoVolatilityFits{subj, condNum}.optim.RMSE, '%.2f'), '  Block ', partData(subj).blockType{condNum}));
            set(h, 'fontweight', 'bold');
            
            % Screen size parameters for saving figures
            scrSz = get(0,'ScreenSize');
            outerPos = [scrSz(3), scrSz(4), scrSz(3), scrSz(4)];
            set(gcf, 'OuterPosition', outerPos);
            
            exportgraphics(gcf, [pwd, filesep, 'Plots', filesep, 'Per_Block_eHGF_No_Volatility', ...
                                 filesep, 'Subj_', num2str(subj, '%03d'), ...
                                 '_eHGF_', 'Block_', num2str(condNum, '%02d'), '.png']);
            close gcf;
            
            % Save model fit
            tempModel = eHGFNoVolatilityFits{subj, condNum};
            
            save([pwd, filesep, 'Models', filesep, 'Per_Block_eHGF_No_Volatility', filesep, ... 
                  'Subj_', num2str(subj, '%03d'), ...
                  '_eHGF_No_Volatility_', 'Block_', num2str(condNum, '%02d'), '.mat'], 'tempModel');

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % eHGF without perceptual uncertainty fit
            eHGFNoPercpUncertFits{subj, condNum} = tapas_fitModel(partData(subj).cart( condNum), partData(subj).parcel( condNum), ...
                                            'tapas_ehgf_nopercepuncert_config', ...
                                            'tapas_gaussian_obs_config', ...
                                            'tapas_quasinewton_optim_config');

            % Calculate RMSE of predicted versus measured responses
            eHGFNoPercpUncertFits{subj, condNum}.optim.RMSE = sqrt(sum(eHGFNoPercpUncertFits{subj, condNum}.optim.res.^2).length(eHGFNoPercpUncertFits{subj, condNum}.optim.res));
        
                  
            % Plot standard eHGF without perceptual uncertainty parameter trajectories
            tapas_ehgf_plotTraj(eHGFNoPercpUncertFits{subj, condNum});
            pause(2);
            h = sgtitle(append('Subject ', num2str(subj, '%03d'), '  Condition ', ...
                      partData(subj).subjCondition{nCond}, '  RMSE ', num2str(eHGFNoPercpUncertFits{subj, condNum}.optim.RMSE, '%.2f'), '  Block ', partData(subj).blockType{condNum}));
            set(h, 'fontweight', 'bold');
            
            % Screen size parameters for saving figures
            scrSz = get(0,'ScreenSize');
            outerPos = [scrSz(3), scrSz(4), scrSz(3), scrSz(4)];
            set(gcf, 'OuterPosition', outerPos);
            
            exportgraphics(gcf, [pwd, filesep, 'Plots', filesep, 'Per_Block_eHGF_No_Percep_Uncert', ...
                                 filesep, 'Subj_', num2str(subj, '%03d'), ...
                                 '_eHGF_No_Percep_Uncert_', 'Block_', num2str(condNum, '%02d'), '.png']);
            close gcf;
            
            % Save model fit
            tempModel = eHGFNoPercpUncertFits{subj, condNum};
            
            save([pwd, filesep, 'Models', filesep, 'Per_Block_eHGF_No_Percep_Uncert', filesep, ... 
                  'Subj_', num2str(subj, '%03d'), ...
                  '_eHGF_No_Percep_Uncert_', 'Block_', num2str(condNum, '%02d'), '.mat'], 'tempModel');
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % eHGF without perceptual uncertainty and volatility fit 
            eHGFNoPercpUncertNoVolatilityFits{subj, condNum} = tapas_fitModel(partData(subj).cart(, condNum), partData(subj).parcel(, condNum), ...
                                            'tapas_ehgf_nopercepuncert_novolatility_config', ...
                                            'tapas_gaussian_obs_config', ...
                                            'tapas_quasinewton_optim_config');

            % Calculate RMSE of predicted versus measured responses
            eHGFNoPercpUncertNoVolatilityFits{subj, condNum}.optim.RMSE = sqrt(sum(eHGFNoPercpUncertNoVolatilityFits{subj, condNum}.optim.res.^2).length(eHGFNoPercpUncertNoVolatilityFits{subj, condNum}.optim.res));
        
                  
            % Plot standard eHGF without perceptual uncertainty and volatility parameter trajectories
            tapas_ehgf_plotTraj(eHGFNoPercpUncertNoVolatilityFits{subj, condNum});
            pause(2);
            h = sgtitle(append('Subject ', num2str(subj, '%03d'), '  Condition ', ...
                      partData(subj).subjCondition{}, '  RMSE ', num2str(eHGFNoPercpUncertNoVolatilityFits{subj, condNum}.optim.RMSE, '%.2f'), '  Block ', partData(subj).blockType{condNum}));
            set(h, 'fontweight', 'bold');
            
            % Screen size parameters for saving figures
            scrSz = get(0,'ScreenSize');
            outerPos = [0.2scrSz(3), 0.2scrSz(4), 0.8scrSz(3), 0.8scrSz(4)];
            set(gcf, 'OuterPosition', outerPos);
            
            exportgraphics(gcf, [pwd, filesep, 'Plots', filesep, 'Per_Block_eHGF_No_Percep_Uncert_No_Volatility', ...
                                 filesep, 'Subj_', num2str(subj, '%03d'), ...
                                 '_eHGF_No_Percep_Uncert_No_Volatility_', 'Block_', num2str(condNum, '%02d'), '.png']);
            close gcf;
            
            % Save model fit
            tempModel = eHGFNoPercpUncertNoVolatilityFits{subj, condNum};
            
            save([pwd, filesep, 'Models', filesep, 'Per_Block_eHGF_No_Percep_Uncert_No_Volatility', filesep, ... 
                  'Subj_', num2str(subj, '%03d'), ...
                  '_eHGF_No_Percep_Uncert_No_Volatility_', 'Block_', num2str(condNum, '%02d'), '.mat'], 'tempModel');
            
            
            
            %%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % HGF fit
            hgfFits{subj, condNum} = tapas_fitModel(partData(subj).cart(, condNum), partData(subj).parcel(, condNum), ...
                                            'tapas_hgf_config', ...
                                            'tapas_gaussian_obs_config', ...
                                            'tapas_quasinewton_optim_config');

            % Calculate RMSE of predicted versus measured responses
            hgfFits{subj, condNum}.optim.RMSE = sqrt(sum(hgfFits{subj, condNum}.optim.res.^2).length(hgfFits{subj, condNum}.optim.res));
        
                  
            % Plot standard HGF parameter trajectories
            tapas_hgf_plotTraj(hgfFits{subj, condNum});
            pause(2);
            h = sgtitle(append('Subject ', num2str(subj, '%03d'), '  Condition ', ...
                      partData(subj).subjCondition{}, '  RMSE ', num2str(hgfFits{subj, condNum}.optim.RMSE, '%.2f'), '  Block ', partData(subj).blockType{condNum}));
            set(h, 'fontweight', 'bold');
            
            % Screen size parameters for saving figures
            scrSz = get(0,'ScreenSize');
            outerPos = [0.2scrSz(3), 0.2scrSz(4), 0.8scrSz(3), 0.8scrSz(4)];
            set(gcf, 'OuterPosition', outerPos);
            
            exportgraphics(gcf, [pwd, filesep, 'Plots', filesep, 'Per_Block_HGF', ...
                                 filesep, 'Subj_', num2str(subj, '%03d'), ...
                                 '_HGF_', 'Block_', num2str(condNum, '%02d'), '.png']);
            close gcf;
            
            % Save model fit
            tempModel = hgfFits{subj, condNum};
            
            save([pwd, filesep, 'Models', filesep, 'Per_Block_HGF', filesep, ... 
                  'Subj_', num2str(subj, '%03d'), ...
                  '_HGF_', 'Block_', num2str(condNum, '%02d'), '.mat'], 'tempModel');
        
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % HGF without volatility fit
            hgfNoVolatilityFits{subj, condNum} = tapas_fitModel(partData(subj).cart(, condNum), partData(subj).parcel(, condNum), ...
                                            'tapas_hgf_novolatility_config', ...
                                            'tapas_gaussian_obs_config', ...
                                            'tapas_quasinewton_optim_config');

            % Calculate RMSE of predicted versus measured responses
            hgfNoVolatilityFits{subj, condNum}.optim.RMSE = sqrt(sum(hgfNoVolatilityFits{subj, condNum}.optim.res.^2).length(hgfNoVolatilityFits{subj, condNum}.optim.res));
        
                  
            % Plot standard HGF without volatility parameter trajectories
            tapas_hgf_plotTraj(hgfNoVolatilityFits{subj, condNum});
            pause(2);
            h = sgtitle(append('Subject ', num2str(subj, '%03d'), '  Condition ', ...
                      partData(subj).subjCondition{}, '  RMSE ', num2str(hgfNoVolatilityFits{subj, condNum}.optim.RMSE, '%.2f'), '  Block ', partData(subj).blockType{condNum}));
            set(h, 'fontweight', 'bold');
            
            % Screen size parameters for saving figures
            scrSz = get(0,'ScreenSize');
            outerPos = [0.2scrSz(3), 0.2scrSz(4), 0.8scrSz(3), 0.8scrSz(4)];
            set(gcf, 'OuterPosition', outerPos);
            
            exportgraphics(gcf, [pwd, filesep, 'Plots', filesep, 'Per_Block_HGF_No_Volatility', ...
                                 filesep, 'Subj_', num2str(subj, '%03d'), ...
                                 '_HGF_', 'Block_', num2str(condNum, '%02d'), '.png']);
            close gcf;
         
            % Save model fit
            tempModel = hgfNoVolatilityFits{subj, condNum};
            
            save([pwd, filesep, 'Models', filesep, 'Per_Block_HGF_No_Volatility', filesep, ... 
                  'Subj_', num2str(subj, '%03d'), ...
                  '_HGF_No_Volatility_', 'Block_', num2str(condNum, '%02d'), '.mat'], 'tempModel');

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % HGF without perceptual uncertainty fit
            hgfNoPercepUncertFits{subj, condNum} = tapas_fitModel(partData(subj).cart(, condNum), partData(subj).parcel(, condNum), ...
                                            'tapas_hgf_nopercepuncert_config', ...
                                            'tapas_gaussian_obs_config', ...
                                            'tapas_quasinewton_optim_config');

            % Calculate RMSE of predicted versus measured responses
            hgfNoPercepUncertFits{subj, condNum}.optim.RMSE = sqrt(sum(hgfNoPercepUncertFits{subj, condNum}.optim.res.^2).length(hgfNoPercepUncertFits{subj, condNum}.optim.res));
        
                  
            % Plot standard HGF without perceptual uncertainty parameter trajectories
            tapas_hgf_plotTraj(hgfNoPercepUncertFits{subj, condNum});
            pause(2);
            h = sgtitle(append('Subject ', num2str(subj, '%03d'), '  Condition ', ...
                      partData(subj).subjCondition{}, '  RMSE ', num2str(hgfNoPercepUncertFits{subj, condNum}.optim.RMSE, '%.2f'), '  Block ', partData(subj).blockType{condNum}));
            set(h, 'fontweight', 'bold');
            
            % Screen size parameters for saving figures
            scrSz = get(0,'ScreenSize');
            outerPos = [0.2scrSz(3), 0.2scrSz(4), 0.8scrSz(3), 0.8scrSz(4)];
            set(gcf, 'OuterPosition', outerPos);
            
            exportgraphics(gcf, [pwd, filesep, 'Plots', filesep, 'Per_Block_HGF_No_Percep_Uncert', ...
                                 filesep, 'Subj_', num2str(subj, '%03d'), ...
                                 '_HGF_No_Percep_Uncert_', 'Block_', num2str(condNum, '%02d'), '.png']);
            close gcf;
            
            % Save model fit
            tempModel = hgfNoPercepUncertFits{subj, condNum};
            
            save([pwd, filesep, 'Models', filesep, 'Per_Block_HGF_No_Percep_Uncert', filesep, ... 
                  'Subj_', num2str(subj, '%03d'), ...
                  '_HGF_No_Percep_Uncert_', 'Block_', num2str(condNum, '%02d'), '.mat'], 'tempModel');
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % HGF without perceptual uncertainty and volatility fit 
            hgfNoPercepUncertNoVolatilityFits{subj, condNum} = tapas_fitModel(partData(subj).cart(, condNum), partData(subj).parcel(, condNum), ...
                                            'tapas_hgf_nopercepuncert_novolatility_config', ...
                                            'tapas_gaussian_obs_config', ...
                                            'tapas_quasinewton_optim_config');

            % Calculate RMSE of predicted versus measured responses
            hgfNoPercepUncertNoVolatilityFits{subj, condNum}.optim.RMSE = sqrt(sum(hgfNoPercepUncertNoVolatilityFits{subj, condNum}.optim.res.^2).length(hgfNoPercepUncertNoVolatilityFits{subj, condNum}.optim.res));
        
                  
            % Plot standard HGF perceptual uncertainty and volatility parameter trajectories
            tapas_hgf_plotTraj(hgfNoPercepUncertNoVolatilityFits{subj, condNum});
            h = sgtitle(append('Subject ', num2str(subj, '%03d'), '  Condition ', ...
                      partData(subj).subjCondition{}, '  RMSE ', num2str(hgfNoPercepUncertNoVolatilityFits{subj, condNum}.optim.RMSE, '%.2f'), '  Block ', partData(subj).blockType{condNum}));
            set(h, 'fontweight', 'bold');
            
            % Screen size parameters for saving figures
            scrSz = get(0,'ScreenSize');
            outerPos = [0.2scrSz(3), 0.2scrSz(4), 0.8scrSz(3), 0.8scrSz(4)];
            set(gcf, 'OuterPosition', outerPos);
            
            exportgraphics(gcf, [pwd, filesep, 'Plots', filesep, 'Per_Block_HGF_No_Percep_Uncert_No_Volatility', ...
                                 filesep, 'Subj_', num2str(subj, '%03d'), ...
                                 '_HGF_No_Percep_Uncert_No_Volatility_', 'Block_', num2str(condNum, '%02d'), '.png']);
            close gcf;
            
            % Save model fit
            tempModel = hgfNoPercepUncertNoVolatilityFits{subj, condNum};
            
            save([pwd, filesep, 'Models', filesep, 'Per_Block_HGF_No_Percep_Uncert_No_Volatility', filesep, ... 
                  'Subj_', num2str(subj, '%03d'), ...
                  '_HGF_No_Percep_Uncert_No_Volatility_', 'Block_', num2str(condNum, '%02d'), '.mat'], 'tempModel');
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    
        catch
           % Fit failed in some way, likely parameters outside of valid variational range
           badFitCount = badFitCount + 1;
           listBadFits(badFitCount) = subj;
        end
        
    end

end
end









