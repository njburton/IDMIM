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
diary on

tic % recording how long the function takes to complete
load("optionsFile.mat");
load(char(fullfile(optionsFile.paths.databaseDir,optionsFile.fileName.dataBaseFileName)));

addpath(genpath(optionsFile.paths.HGFtoolboxDir)); %add TAPAS toolbox via path
addpath(genpath(optionsFile.paths.VKFtoolboxDir)); %add VKF toolbox via path

for modeli = 1:numel(optionsFile.model.space) %for each model in the model space
    if modeli < 4
        diaryName = optionsFile.fileName.fitDiaryName{modeli};
        disp(['fitting  ', optionsFile.model.space{modeli},' to data...']);

        for filei = 1:length(dataInfoTable.TaskPath)  % for each mouse(agent) in the cohort
            currMouse = dataInfoTable.MouseID(filei); % currMouse vector for each mouseID in cohort
            disp(['fitting mouse ', num2str(currMouse), ' (',num2str(filei),' of ',num2str(length(dataInfoTable.MouseID)),')']);

            currFileData = load(dataInfoTable.TaskPath(filei)); %load currMouse's results from data extraction
            inputs       = currFileData.ExperimentTaskTable.RewardingLeverSide;
            responses    = currFileData.ExperimentTaskTable.Choice;
            task         = erase(currFileData.ExperimentTaskTable.Task(filei),optionsFile.task.taskPrefix,'_');
            date         = currFileData.ExperimentTaskTable.TaskDate(filei);

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
            figdir = fullfile([char(optionsFile.paths.plotsDir),filesep,char(date),'_',...
                'mouse',num2str(currMouse),'_',char(task),'_',optionsFile.fileName.rawFitFile{modeli}]);
            save([figdir,'.fig']);
            print([figdir,'.png'], '-dpng');
            close all;

            %Save model fit
            save([char(optionsFile.paths.mouseModelFitFilesDir),filesep,char(date),'_',...
                'mouse',num2str(currMouse),'_',char(task),'_',optionsFile.fileName.rawFitFile{modeli},'.mat'], 'est');
            modelInv.allMice(filei,modeli).est = est;
        end
    else
        for filei = 1:length(dataInfoTable.TaskPath) %for each mouse(agent) in the cohort

            disp('Starting VKF fitting');
            currMouse = dataInfoTable.MouseID(filei); %currMouse vector for each mouseID in cohort
            disp(['fitting mouse ', num2str(currMouse), ' (',num2str(filei),' of ',num2str(length(dataInfoTable.MouseID)),')']);

            currFileData = load(dataInfoTable.TaskPath(filei)); %load currMouse's results from data extraction
            responses    = currFileData.ExperimentTaskTable.Choice;
            outcomes     = currFileData.ExperimentTaskTable.Outcome;
            inputs       = currFileData.ExperimentTaskTable.RewardingLeverSide;
            task         = erase(currFileData.ExperimentTaskTable.Task(filei),optionsFile.task.taskPrefix,'_');
            date         = currFileData.ExperimentTaskTable.TaskDate(filei);

            % VKF model fit
            [resp,signals] = vkf_bin(outcomes,...
                optionsFile.modelVKF.lambda,...  % volatility learning rate
                optionsFile.modelVKF.v0,...      % initial volatility
                optionsFile.modelVKF.omega);     % noise parameter
            %vkfEstParams = vkfEst.signals;

            % save struct
            save([char(optionsFile.paths.mouseModelFitFilesDir),filesep,char(date),'_',...
                'mouse',num2str(currMouse),'_',char(task),'_',optionsFile.fileName.rawFitFile{modeli},'.mat'], 'vkfEst');
        end
    end
end
save([optionsFile.paths.mouseModelFitFilesDir,filesep,optionsFile.fileName.fittedData], '-struct', 'modelInv','allMice');
toc % end timer

diary off
save([diaryName,'.txt'])
end

