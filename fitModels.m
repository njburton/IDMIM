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

% try
     load('optionsFile.mat');
% catch
%     optionsFile = runOptions; % specifications for this analysis
% end

addpath(genpath(optionsFile.paths.HGFtoolboxDir));
optionsFile.hgf.opt_config = eval('tapas_quasinewton_optim_config')

%CreatemodelFit table to capture LME's and other important free parameters
%in models

for m = 1:numel(optionsFile.model.space)
    disp(['fitting  ', optionsFile.model.space{m},' to data...']);

    for n = 1:optionsFile.Task.nSize
        currMouse = optionsFile.Task.MouseID(n);
        disp(['fitting mouse ', num2str(currMouse), ' (',num2str(n),' of ',num2str(optionsFile.Task.nSize),')']);

        load([char(optionsFile.paths.resultsDir),filesep,'mouse',num2str(currMouse)]);
        responses = ExperimentTaskTable.Choice;

        %optionsFile.model.opt_config.maxStep = Inf;
        strct=eval(optionsFile.model.opt_config);
        strct.maxStep      = inf;
        strct.nRandInit    = 100 %optionsFile.rng.nRandInit;
        strct.seedRandInit = optionsFile.rng.settings.State(optionsFile.rng.idx, 1);
        
        %% model fit
        est = tapas_fitModel(responses, ...
            optionsFile.Task.inputs, ...
            optionsFile.model.prc_config{m}, ...
            optionsFile.model.obs_config{m}, ...             
            strct); % info for optimization and multistart

        %Plot standard HGF trajectory plot
        optionsFile.plot(m).plot_fits(est);
        figdir = fullfile([char(optionsFile.paths.plotsDir),filesep,'mouse',num2str(currMouse),'_',optionsFile.fileName.rawFitFile{m}]);
        save([figdir,'.fig']);
        print([figdir,'.png'], '-dpng');
        close all;

        %Save model fit
        save([char(optionsFile.paths.resultsDir),filesep,'mouse',num2str(currMouse),'_',optionsFile.fileName.rawFitFile{m},'.mat'], 'est');
        modelInv.allMice(n,m).est = est;
    end
end
save([optionsFile.paths.resultsDir,filesep,'modelInv.mat'], '-struct', 'modelInv','allMice');
end
