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

%CreatemodelFit table to capture LME's and other important free parameters
%in models
% TO DO, adaptive to m models
ModelFitTableVarTypes = {'string','double','double','double'};
ModelFitTableVarNames = {'MouseID','eHGFFitLME','RWFitLME','RWFit_Alpha'};
ModelFitTable = table('Size',[optionsFile.Task.nSize length(ModelFitTableVarNames)],'VariableTypes', ModelFitTableVarTypes,'VariableNames',ModelFitTableVarNames);

for m = 2:numel(optionsFile.model.space)
    disp(['fitting  ', optionsFile.model.space{m},' to data...']);

    for n = optionsFile.Task.nSize-1:optionsFile.Task.nSize
            currMouse = optionsFile.Task.MouseID(n);
            disp(['fitting mouse ', num2str(currMouse), ' (',num2str(n),' of ',num2str(optionsFile.Task.nSize),')']);

            load([char(optionsFile.paths.resultsDir),'\mouse',num2str(currMouse)]);
            responses = ExperimentTaskTable.Choice;
            
            try
                %% model fit
                est = tapas_fitModel(responses, ...
                    optionsFile.Task.inputs, ...
                    optionsFile.model.prc_config{m}, ...
                    optionsFile.model.obs_config{m}, ...
                    optionsFile.model.opt_config);

                %Plot standard HGF trajectory plot
                optionsFile.plot(m).plot_fits(est);
                figdir = fullfile([char(optionsFile.paths.plotsDir),'\mouse',num2str(currMouse),'_',optionsFile.fileName.rawFitFile{m}]);
                save([figdir,'.fig']);
                print([figdir,'.png'], '-dpng');
                close all;

                %Save model fit
                save([char(optionsFile.paths.resultsDir),'\mouse',num2str(currMouse),'_',optionsFile.fileName.rawFitFile{m},'.mat'], 'est');

                % TO DO, this has to be done differently, just a hack for now.
                if optionsFile.model.space{m}
                    %Add currMouse ID to ModelFitTable column
                    ModelFitTable.MouseID(n)  = currMouse;
                    %Save LME to ModelFitTable
                    ModelFitTable.eHGFFitLME(n) = est.optim.LME;
                else
                    %Save RW LME to vector with mice as rows
                    ModelFitTable.RWFitLME(n)   = est.optim.LME;

                    %Save RWFit alpha (learning rate)
                    ModelFitTable.RWFit_Alpha(n) = est.p_prc.al;

                end

            catch
                disp('fit failed in some way...');
                % Fit failed in some way - likely parameters outside of valid
                % variational range
                %             badFitCount = badFitCount + 1;
                %             listBadFits(badFitCount) = MouseID;
            end
    end
end


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

