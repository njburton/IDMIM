function getExcludeData(optionsFile,cohortNo)

%% getExcludeData gets the dataset for exclusion criteria being

%   SYNTAX:  getExcludeData(optionsFile,cohortNo,subCohort)
%
%   IN:      optionsFile: struct, contains all settings for this analysis,
%                                 incl exclusion criteria for each cohort
%            cohortNo:    integer, cohort number, see optionsFile for what cohort
%                                  corresponds to what number in the
%                                  optionsFile.cohort(cohortNo).name struct. This
%                                  allows to run the pipeline and its functions for different
%                                  cohorts whose expcifications have been set in runOptions.m
%
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

%% GET EXCLUSION CRITERIA data and write into table
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
                    loadExpName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,[],currCondition,iRep,nReps,[]);
                    load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                        loadExpName,'.mat']);
                    % load mouse info file
                    loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,[],currCondition,iRep,nReps,'info');
                    load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                        loadInfoName]);


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
                        exclCrit1_met = true;
                    else
                        exclCrit1_met = false;
                    end

                    % Exclude datasets with specific no. of consecutive omissions
                    if any(nConsecNaNs>optionsFile.cohort(cohortNo).exclCriteria(2).cutoff)
                        exclCrit2_met = true;
                    else
                        exclCrit2_met = false;
                    end

                    % update mouseInfoTables with exclusion criteria info
                    if ~isfield(table2struct(MouseInfoTable),'exclCrit1_met')
                        MouseInfoTable = addvars(MouseInfoTable,exclCrit1_met,numNaNs,exclCrit2_met,numConsecNans);
                    else
                        MouseInfoTable.exclCrit1_met = exclCrit1_met;
                        MouseInfoTable.numNaNs       = numNaNs;
                        MouseInfoTable.exclCrit2_met = exclCrit2_met;
                        MouseInfoTable.numConsecNans = numConsecNans;
                    end

                    % create savepath and filename as a .mat file
                    saveName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,[],currCondition,iRep,nReps,'info');
                    savePath = [char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                        saveName,'.mat'];
                    save(savePath,'MouseInfoTable');

                catch
                    disp(['mouse dataset',currMouse,' not loaded']);
                end
            end % END MOUSE Loop
        end % END REPETITIONS Loop
    end % END CONDITIONS Loop
end % END TASKS Loop