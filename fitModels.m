function fitModels()
%% fitModels
%
%  SYNTAX:  fitModels
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

if exist('optionsFile.mat','file')==2
    load("optionsFile.mat");
else
    optionsFile = runOptions();
end

load(char(fullfile(optionsFile.paths.cohort(cohortNo).databaseDir,optionsFile.fileName.dataBaseFileName)));

optionsFile = setup_configFiles(optionsFile,cohortNo);

addpath(genpath([optionsFile.paths.toolboxDir,'HGF']));

for iModel = 1:numel(optionsFile.model.space) %for each model in the model space
        diaryName = optionsFile.fileName.fitDiaryName{iModel};
        disp(['fitting  ', optionsFile.model.space{iModel},' to data...']);

        for iFile = 1:length(rawDataFileInfo.TaskPath)  % for each mouse(agent) in the cohort: Could this also be
            currMouse = rawDataFileInfo.MouseID(iFile); % currMouse vector for each mouseID in cohort: is this not in the optionsFile?
            disp(['fitting mouse ', num2str(currMouse), ' (',num2str(iFile),' of ',num2str(length(rawDataFileInfo.MouseID)),')']);

            currFileData = load(rawDataFileInfo.TaskPath(iFile)); %load currMouse's results from data extraction
            inputs       = currFileData.ExperimentTaskTable.RewardingLeverSide;
            responses    = currFileData.ExperimentTaskTable.Choice;
            task         = erase(currFileData.ExperimentTaskTable.Task(iFile),optionsFile.task.taskPrefix);
            date         = currFileData.ExperimentTaskTable.TaskDate(iFile);

            strct              = eval(char(optionsFile.model.opt_config));
            strct.maxStep      = inf;
            strct.nRandInit    = optionsFile.rng.nRandInit;
            strct.seedRandInit = optionsFile.rng.settings.State(optionsFile.rng.idx, 1);

            %% model fit
            est = tapas_fitModel(responses, ...
                inputs, ...
                optionsFile.model.prc_config{iModel}, ...
                optionsFile.model.obs_config{1}, ... % only ever take first entry because all perceptual models use the same observational model, if this changes, in runOptions add different observational models and add a loop
                strct); % info for optimization and multistart

            %Plot standard trajectory plot
            optionsFile.plot(iModel).plot_fits(est);
            figdir = fullfile([char(optionsFile.paths.plotsDir),filesep,char(date),'_',...
                'mouse',num2str(currMouse),'_',char(task),'_',optionsFile.fileName.rawFitFile{iModel}]);
            save([figdir,'.fig']);
            print([figdir,'.png'], '-dpng');
            close all;

            %Save model fit
            save([char(optionsFile.paths.mouseModelFitFilesDir),filesep,char(date),'_',...
                'mouse',num2str(currMouse),'_',char(task),'_',optionsFile.fileName.rawFitFile{iModel},'.mat'], 'est');
            modelInv.allMice(iFile,iModel).est = est;
        end
end
save([optionsFile.paths.mouseModelFitFilesDir,filesep,optionsFile.fileName.fittedData], '-struct', 'modelInv','allMice');
toc % end timer

diary off
save([diaryName,'.txt'])
end

