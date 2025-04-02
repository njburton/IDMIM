function [exclArray,optionsFile] = excludeData(optionsFile,cohortNo,subCohort,fExecution,exclMode)

%% excludeData
%  excludeData analysis analyses the datasets for exclusion criteria being
%  met (defined in runOptions) and codes the respespective
%  participant/mouse indices in the inclIdArray as zeros
%
%   SYNTAX:  inclIDs = excludeData(optionsFile,cohortNo,mode)
%
%   IN:      optionsFile: struct, contains all settings for this analysis,
%                                 incl exclusion criteria for each cohort
%            cohortNo:    integer, cohort number, see optionsFile for what cohort
%                                  corresponds to what number in the
%                                  optionsFile.cohort(cohortNo).name struct. This
%                                  allows to run the pipeline and its functions for different
%                                  cohorts whose expcifications have been set in runOptions.m
%            fExecution: string, function execution, i.e. {'excludeData','updateDataInfo'},mode in which
%                           this function should run.
%                           'updateDataInfo' updates the dataInfo Tables
%                           with the info on exclusion criteria 
%                           'excludeData', determines what data should be excluded
%                           and checks if data info table are up-to-date
%           exclMode:    cell of strings, {'withinConditions','withinSubCohorts','withinTasks','withinReps',
%                                  'acrossConditions','acrossSubCohorts','acrossTasks','acrossReps'},
%
%   OUT:    inclIdArray: array, contains ones for IDs that will be included
%                               and zeros for IDs that will not be. The sequence of
%                               IDs are the same as optionsFile.cohort(cohortNo).mouseIDs
%            optionsFile: struct, contains all settings for this analysis,
%                                 incl exclusion criteria for each cohort
%
% Original: 19-03-2025; Katharina V. Wellstein,
%           katharina.wellstein@newcastle.edu.au
%
% -------------------------------------------------------------------------
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

%% INITIALIZE Variables for running this function
% specifications for this analysis
if exist('optionsFile.mat','file')==2
    load('optionsFile.mat');
else
    optionsFile = runOptions();
end

% get sample specifics for loops
[mouseIDs,nSize] = getSampleSpecs(optionsFile,cohortNo,subCohort);
nTasks = numel(optionsFile.cohort(cohortNo).testTask);
nReps  = optionsFile.cohort(cohortNo).taskRepetitions;
if isempty(optionsFile.cohort(cohortNo).conditions) % if the cohort had different conditions
    nConditions   = 1;
    currCondition = [];
else
    nConditions = numel(optionsFile.cohort(cohortNo).conditions);
end

%% INITIALIZE
disp([' ====== excludeData function running in ',fExecution,' mode ====== ']);

exclArray  = ones(1,nSize);
inclIDMatrix = ones(nReps,nConditions*nSize,nTasks);


for iTask = 1:nTasks
    currTask = optionsFile.cohort(cohortNo).testTask(iTask).name;
    for iCondition = 1:nConditions
        for iRep = 1:nReps
            for iMouse = 1:nSize
                currMouse = mouseIDs{iMouse};
                if ~isempty(optionsFile.cohort(cohortNo).conditions) % if the cohort had different conditions
                    currCondition = optionsFile.cohort(cohortNo).conditions{iCondition};
                end

                try
                    % load trial-by-trial data file
                    loadName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,'',currTask,subCohort,currCondition,iRep,nReps);
                    load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                        loadName,'.mat']);
                    % load mouse info file
                    loadName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,'info',currTask,subCohort,currCondition,iRep,nReps);
                    load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                        loadName]);
                catch
                    disp(['mouse dataset',currMouse,' not loaded']);
                    exclArray(iMouse) = 0;
                end

                % create vector of indices with NaNs
                NaNrows     = find(isnan(ExperimentTaskTable.Choice));
                % create vector of differences between indices with NaNs (a 1
                % means there are two indices in a row with a NaN)
                NaNDiffs    = [NaNrows;optionsFile.cohort(cohortNo).nTrials+1]-[0;NaNrows];
                consecNaNs  = zeros(1,numel(NaNDiffs));
                consecNaNs(NaNDiffs==1) = 1;
                f           = find(diff([0,consecNaNs,0]==1));
                NaNIdx      = f(1:2:end-1);
                nConsecNaNs = f(2:2:end)-NaNIdx;
                if ~isempty(NaNrows)
                    numNaNs       = numel(NaNrows);
                else
                    numNaNs       = 0;
                end
                if ~isempty(nConsecNaNs)
                    numConsecNans = max(nConsecNaNs);
                else
                    numConsecNans = 0;
                end

                if numel(NaNrows)>optionsFile.cohort(cohortNo).nTrials*optionsFile.cohort(cohortNo).exclCriteria(1).cutoff
                    exclCrit1_met       = true;
                    exclArray(iMouse) = 0;

                    % Exclude datasets with specific no. of consecutive omissions
                elseif any(nConsecNaNs>optionsFile.cohort(cohortNo).exclCriteria(2).cutoff)
                    exclCrit2_met       = true;
                    exclArray(iMouse) = 0;
                else
                    exclCrit1_met = false;
                    exclCrit2_met = false;
                end

                % update mouseInfoTables with exclusion criteria info
                if strcmp(fExecution,'updateDataInfo')
                    if ~isfield(table2struct(MouseInfoTable),'exclCrit1_met')
                        MouseInfoTable = addvars(MouseInfoTable,exclCrit1_met,numNaNs,exclCrit2_met,numConsecNans);
                    else
                        MouseInfoTable.exclCrit1_met = exclCrit1_met;
                        MouseInfoTable.numNaNs       = numNaNs;
                        MouseInfoTable.exclCrit2_met = exclCrit2_met;
                        MouseInfoTable.numConsecNans = numConsecNans;
                    end

                    % create savepath and filename as a .mat file
                    saveName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,subCohort,currCondition,iRep);
                    savePath = [char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                        saveName,'_info.mat'];
                    save(savePath,'MouseInfoTable');
                end
            end

            if iCondition == 1
                inclIDMatrix(iRep,iCondition:nSize,iTask) = exclArray;
                conditionIdx = iCondition+nSize;
                exclArray  = ones(1,nSize);
            else
                inclIDMatrix(iRep,conditionIdx:(conditionIdx+nSize-1),iTask) = exclArray;
                conditionIdx = conditionIdx+nSize;
                exclArray  = ones(1,nSize);
            end
        end
    end
end

if strcmp(fExecution,'excludeData')
exclMode = cell2mat(exclMode);
exclArray = struct();
switch exclMode

    case 'withinConditionswithinSubCohortswithinTaskswithinReps'
        i = 1;
        for iCondition=1:nConditions
            for iTask=1:nTasks
                for iRep=1:nReps
                    if iCondition==1
                        exclArray(i).ID = find(inclIDMatrix(iRep,iCondition:nSize,iTask)==0);
                        condIdx = iCondition+nSize;
                        if isempty(exclArray(i).ID)
                            exclArray(i).ID = 0;
                        end
                        i = i +1;
                    else
                        exclArray(i).ID = find(inclIDMatrix(iRep,condIdx:(condIdx+nSize-1),iTask)==0);
                        condIdx = condIdx+nSize;
                        if isempty(exclArray(i).ID)
                            exclArray(i).ID = 0;
                        end
                        i = i +1;
                    end
                end
            end
        end

    case 'acrossConditionsacrossSubCohortsacrossTasksacrossReps'
        i = 1;
        for iCondition=1:nConditions
            for iTask=1:nTasks
                for iRep=1:nReps
                    if iCondition==1
                        exclArray(i).ID = find(inclIDMatrix(iRep,iCondition:nSize,iTask)==0);
                        condIdx = iCondition+nSize;
                        if isempty(exclArray(i).ID)
                            exclArray(i).ID = 0;
                        end
                        i = i +1;
                    else
                        exclArray(i).ID = [exclArray(i-1).ID,find(inclIDMatrix(iRep,condIdx:(condIdx+nSize-1),iTask)==0)];
                        unique(exclArray(i).ID)
                        condIdx = condIdx+nSize;
                        if isempty(exclArray(i).ID)
                            exclArray(i).ID = 0;
                        end
                        i = i +1;
                    end
                end
            end
        end

    case 'withinConditionsacrossSubCohortsacrossTasksacrossReps'
        i = 1;
        j = 1;
        for iCondition=1:nConditions
            for iTask=1:nTasks
                for iRep=1:nReps
                    if i==1 && iCondition==1
                        exclArray(i).ID = find(inclIDMatrix(iRep,iCondition:nSize,iTask)==0);
                        condIdx = iCondition+nSize;
                        if isempty(exclArray(i).ID)
                            exclArray(i).ID = 0;
                        end
                        i = i +1;
                    elseif i<=j % across everything else
                        exclArray(i).ID = [exclArray(i-1).ID,find(inclIDMatrix(iRep,condIdx:(condIdx+nSize-1),iTask)==0)];
                        unique(exclArray(i).ID)
                        condIdx = condIdx+nSize;
                        if isempty(exclArray(i).ID)
                            exclArray(i).ID = 0;
                        end
                        i = i +1;
                    elseif i>j % within conditions
                        exclArray(i).ID = find(inclIDMatrix(iRep,condIdx:(condIdx+nSize-1),iTask)==0);
                        condIdx = condIdx+nSize;
                        if isempty(exclArray(i).ID)
                            exclArray(i).ID = 0;
                        end
                        i = i +1;
                    end
                end
            end
            j = j+1;
        end

    case 'withinConditionswithinSubCohortsacrossTasksacrossReps'
        i = 1;
        j = 1;
        for iCondition=1:nConditions
            for iTask=1:nTasks
                for iRep=1:nReps
                    if i==1 && iCondition==1
                        exclArray(i).ID = find(inclIDMatrix(iRep,iCondition:nSize,iTask)==0);
                        condIdx = iCondition+nSize;
                        if isempty(exclArray(i).ID)
                            exclArray(i).ID = 0;
                        end
                        i = i +1;
                    elseif i<=j % across everything else
                        exclArray(i).ID = [exclArray(i-1).ID,find(inclIDMatrix(iRep,condIdx:(condIdx+nSize-1),iTask)==0)];
                        unique(exclArray(i).ID)
                        condIdx = condIdx+nSize;
                        if isempty(exclArray(i).ID)
                            exclArray(i).ID = 0;
                        end
                        i = i +1;
                    elseif i>j % within conditions
                        exclArray(i).ID = find(inclIDMatrix(iRep,condIdx:(condIdx+nSize-1),iTask)==0);
                        condIdx = condIdx+nSize;
                        if isempty(exclArray(i).ID)
                            exclArray(i).ID = 0;
                        end
                        i = i +1;
                    end
                end
            end
            j = j+1;
        end
        % case 'withinConditionswithinSubCohortswithinTasksacrossReps'
        %              i = 1;
        %     j = 1;
        %     for iCondition=1:nConditions
        %         for iTask=1:nTasks
        %             for iRep=1:nReps
        %                 if i==1 && iCondition==1
        %                     exclArray(i).ID = find(inclIDMatrix(iRep,iCondition:nSize,iTask)==0);
        %                     condIdx = iCondition+nSize;
        %                     if isempty(exclArray(i).ID)
        %                         exclArray(i).ID = 0;
        %                     end
        %                     i = i +1;
        %                 elseif i<=j % across everything else
        %                     exclArray(i).ID = [exclArray(i-1).ID,find(inclIDMatrix(iRep,condIdx:(condIdx+nSize-1),iTask)==0)];
        %                     unique(exclArray(i).ID)
        %                     condIdx = condIdx+nSize;
        %                     if isempty(exclArray(i).ID)
        %                         exclArray(i).ID = 0;
        %                     end
        %                     i = i +1;
        %                 elseif i>j % within conditions
        %                     exclArray(i).ID = find(inclIDMatrix(iRep,condIdx:(condIdx+nSize-1),iTask)==0);
        %                     condIdx = condIdx+nSize;
        %                     if isempty(exclArray(i).ID)
        %                         exclArray(i).ID = 0;
        %                     end
        %                     i = i +1;
        %                 end
        %             end
        %         end
        %     end
        %
        %
        % case 'withinConditionsacrossSubCohortswithinTasksacrossReps'
        %             i = 1;
        %     for iCondition=1:nConditions
        %         for iTask=1:nTasks
        %             for iRep=1:nReps
        %                 if i==1 && iCondition==1
        %                     exclArray(i).ID = find(inclIDMatrix(iRep,iCondition:nSize,iTask)==0);
        %                     condIdx = iCondition+nSize;
        %                     if isempty(exclArray(i).ID)
        %                         exclArray(i).ID = 0;
        %                     end
        %                     i = i +1;
        %                 elseif i<=nConditions % within conditions
        %                     exclArray(i).ID = find(inclIDMatrix(iRep,condIdx:(condIdx+nSize-1),iTask)==0);
        %                     condIdx = condIdx+nSize;
        %                     if isempty(exclArray(i).ID)
        %                         exclArray(i).ID = 0;
        %                     end
        %                     i = i +1;
        %                 elseif i>nConditions % across everything else
        %                     exclArray(i).ID = [exclArray(i-1).ID,find(inclIDMatrix(iRep,condIdx:(condIdx+nSize-1),iTask)==0)];
        %                     unique(exclArray(i).ID)
        %                     condIdx = condIdx+nSize;
        %                     if isempty(exclArray(i).ID)
        %                         exclArray(i).ID = 0;
        %                     end
        %                     i = i +1;
        %                 end
        %             end
        %         end
        %     end
        %
        % case 'acrossConditionsacrossSubCohortswithinTasksacrossReps'
        %
        % case 'acrossConditionsacrossSubCohortsacrossTaskswithinReps'
end

end
end
