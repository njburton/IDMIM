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


optionsFile = runOptions; % Load specifications for this analysis
addpath(genpath(optionsFile.paths.HGFtoolboxDir)); %add TAPAS toolbox via path
addpath(genpath(optionsFile.paths.VKFtoolboxDir)); %add VKF toolbox via path

for m = 1:numel(optionsFile.model.space) %for each model in the model space
    disp(['fitting  ', optionsFile.model.space{m},' to data...']); 

    for n = 1:optionsFile.cohort.nSize %for each mouse(agent) in the cohort
        currMouse = optionsFile.task.MouseID(n); %currMouse vector for each mouseID in cohort
        disp(['fitting mouse ', num2str(currMouse), ' (',num2str(n),' of ',num2str(optionsFile.cohort.nSize),')']);

        load([char(optionsFile.paths.resultsDir),filesep,'mouse',num2str(currMouse)]); %load currMouse's results from data extraction
        responses = ExperimentTaskTable.Choice;

        %optionsFile.model.opt_config.maxStep = Inf;
        strct=eval(optionsFile.model.opt_config);
        strct.maxStep      = inf;
        strct.nRandInit    = 100 %optionsFile.rng.nRandInit;
        strct.seedRandInit = optionsFile.rng.settings.State(optionsFile.rng.idx, 1);
        
        %% model fit
        est = tapas_fitModel(responses, ...
            optionsFile.task.inputs, ...
            optionsFile.model.prc_config{m}, ...
            optionsFile.model.obs_config{m}, ...             
            strct); % info for optimization and multistart

        %Plot standard trajectory plot
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
