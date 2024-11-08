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
tic % recording how long the function takes to complete
load("optionsFile.mat");
load(char(fullfile(optionsFile.paths.databaseDir, 'toProcessWithPipeline_allFilesWithTaskOrder.mat')));

addpath(genpath(optionsFile.paths.HGFtoolboxDir)); %add TAPAS toolbox via path
addpath(genpath(optionsFile.paths.VKFtoolboxDir)); %add VKF toolbox via path

for modeli = 1:numel(optionsFile.model.spaceTAPAS) %for each model in the model space
    disp(['fitting  ', optionsFile.model.spaceTAPAS{modeli},' to data...']); 

    for filei = 1:length(groupTableSorted.TaskPath) %for each mouse(agent) in the cohort
        currMouse = groupTableSorted.MouseID(filei); %currMouse vector for each mouseID in cohort
        disp(['fitting mouse ', num2str(currMouse), ' (',num2str(filei),' of ',num2str(length(groupTableSorted.MouseID)),')']);

        currFileData = load(groupTableSorted.TaskPath(filei)); %load currMouse's results from data extraction
        inputs       = currFileData.ExperimentTaskTable.RewardingLeverSide;
        responses    = currFileData.ExperimentTaskTable.Choice;

        strct              = eval(char(optionsFile.model.opt_config));
        strct.maxStep      = inf;
        strct.nRandInit    = optionsFile.rng.nRandInit;
        strct.seedRandInit = optionsFile.rng.settings.State(optionsFile.rng.idx, 1);
        
        %% model fit
        est = tapas_fitModel(responses, ...
            inputs, ... 
            optionsFile.model.prc_config{modeli}, ...       
            optionsFile.model.obs_config{1}, ... % only ever take first entry because all perceptual models use the same observational model, if this changes, in runOptions add different observational models and add a loop   
            strct); % info for optimization and multistart

        %Plot standard trajectory plot
        optionsFile.plot(modeli).plot_fits(est);
        figdir = fullfile([char(optionsFile.paths.plotsDir),filesep,'mouse',...
            num2str(currMouse),'_',optionsFile.fileName.rawFitFile{modeli}]);
        save([figdir,'.fig']);
        print([figdir,'.png'], '-dpng');
        close all;

        %Save model fit
        save([char(optionsFile.paths.mouseMatFilesDir),filesep,'mouse',num2str(currMouse),'_',optionsFile.fileName.rawFitFile{modeli},'.mat'], 'est');
        modelInv.allMice(filei,modeli).est = est;
    end
end
save([optionsFile.paths.mouseMatFilesDir,filesep,'modelInv.mat'], '-struct', 'modelInv','allMice');
toc
end

