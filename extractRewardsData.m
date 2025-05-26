function extractRewardsData(cohortNo)

% extractRewardsData - Extract total rewards received per mouse for a specific study
%
% This function processes a specified cohort to extract the total number of rewards 
% received by each mouse during their experimental tasks. It handles different 
% experimental designs across cohorts (treatment vs control groups, task repetitions, 
% drug conditions). Results are saved as both .mat and .csv files for the specified cohort.
%
% SYNTAX: extractRewardsData(cohortNo)
%
% INPUT: cohortNo - integer, cohort number (1, 2, or 3)
%                   1: 2023_UCMS (treatment vs control)
%                   2: 2024_HGFPilot (task repetitions)  
%                   3: 5HT (drug conditions)
%
% OUTPUT: Reward data table saved to the specified cohort's group-level results directory.
%
% -------------------------------------------------------------------------
%
% Coded by: 2025; Nicholas J. Burton,
%           nicholasjburton91@gmail.com.au
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
% -------------------------------------------------------------------------

% Load options file
if exist('optionsFile.mat','file')==2
    load('optionsFile.mat');
else
    optionsFile = runOptions();
end

% Process the specified cohort
disp(['Processing cohort ', num2str(cohortNo), ': ', optionsFile.cohort(cohortNo).name]);
    
    % Get cohort-specific variables
    nTasks = numel(optionsFile.cohort(cohortNo).testTask);
    nReps = optionsFile.cohort(cohortNo).taskRepetitions;
    [mouseIDs, nSize] = getSampleVars(optionsFile, cohortNo, []);
    
    % Handle different condition structures
    if isempty(optionsFile.cohort(cohortNo).conditions)
        nConditions = 1;
        conditions = {[]};
    else
        nConditions = numel(optionsFile.cohort(cohortNo).conditions);
        conditions = optionsFile.cohort(cohortNo).conditions;
    end
    
    % Counter for row indexing
    rowCounter = 0;
    
    % Process each mouse
    for iMouse = 1:nSize
        currMouse = mouseIDs{iMouse};
        
        % Process each condition
        for iCondition = 1:nConditions
            currCondition = conditions{iCondition};
            
            % Process each task
            for iTask = 1:nTasks
                currTask = optionsFile.cohort(cohortNo).testTask(iTask).name;
                
                % Process each repetition
                for iRep = 1:nReps
                    try
                        % Load experimental data
                        loadExpName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, ...
                            [], currCondition, iRep, nReps, []);
                        expPath = [char(optionsFile.paths.cohort(cohortNo).data), 'mouse', char(currMouse), '_', ...
                            loadExpName, '.mat'];
                        
                        % Load mouse info
                        loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, ...
                            [], currCondition, iRep, nReps, 'info');
                        infoPath = [char(optionsFile.paths.cohort(cohortNo).data), 'mouse', char(currMouse), '_', ...
                            loadInfoName, '.mat'];
                        
                        if isfile(expPath) && isfile(infoPath)
                            load(expPath, 'ExperimentTaskTable');
                            load(infoPath, 'MouseInfoTable');
                            
                            % Convert condition to string for consistency 
                            if isempty(currCondition)
                                conditionStr = "none";
                            else
                                conditionStr = string(currCondition);
                            end
                            
                            % Check exclusion criteria before processing
                            shouldExclude = false;
                            
                            % Check if exclusion criteria fields exist
                            if isfield(table2struct(MouseInfoTable), 'exclCrit1_met') && ...
                               isfield(table2struct(MouseInfoTable), 'exclCrit2_met')
                                
                                % Exclude if either exclusion criterion is met
                                if MouseInfoTable.exclCrit1_met || MouseInfoTable.exclCrit2_met
                                    shouldExclude = true;
                                    disp(['Mouse ', currMouse, ' excluded based on exclusion criteria']);
                                end
                            else
                                % If exclusion criteria haven't been calculated, calculate them now
                                NaNrows = find(isnan(ExperimentTaskTable.Choice));
                                numNaNs = numel(NaNrows);
                                
                                % Check exclusion criterion 1: proportion of omissions
                                if numNaNs > optionsFile.cohort(cohortNo).nTrials * optionsFile.cohort(cohortNo).exclCriteria(1).cutoff
                                    shouldExclude = true;
                                    disp(['Mouse ', currMouse, ' excluded: too many omissions (', num2str(numNaNs), '/', num2str(optionsFile.cohort(cohortNo).nTrials), ')']);
                                end
                                
                                % Check exclusion criterion 2: consecutive omissions
                                if ~isempty(NaNrows)
                                    NaNDiffs = [NaNrows; optionsFile.cohort(cohortNo).nTrials+1] - [0; NaNrows];
                                    consecNaNs = zeros(1,numel(NaNDiffs));
                                    consecNaNs(NaNDiffs==1) = 1;
                                    f = find(diff([0,consecNaNs,0]==1));
                                    if ~isempty(f)
                                        NaNIdx = f(1:2:end-1);
                                        nConsecNaNs = f(2:2:end)-NaNIdx;
                                        
                                        if any(nConsecNaNs > optionsFile.cohort(cohortNo).exclCriteria(2).cutoff)
                                            shouldExclude = true;
                                            disp(['Mouse ', currMouse, ' excluded: too many consecutive omissions (max: ', num2str(max(nConsecNaNs)), ')']);
                                        end
                                    end
                                end
                            end
                            
                            % Only process if mouse should not be excluded
                            if ~shouldExclude
                                % Calculate total rewards (sum of outcomes, excluding NaN)
                                totalRewards = nansum(ExperimentTaskTable.Outcome);
                                
                                % Calculate total trials attempted (non-NaN choices)
                                totalTrials = sum(~isnan(ExperimentTaskTable.Choice));
                                
                                % Calculate reward rate
                                rewardRate = totalRewards / totalTrials;
                                
                                % Determine group label for current mouse
                                if ismember(currMouse, [optionsFile.cohort(cohortNo).treatment.maleMice, ...
                                        optionsFile.cohort(cohortNo).treatment.femaleMice])
                                    if isempty(currCondition)
                                        groupLabel = 'Treatment';
                                    else
                                        groupLabel = ['Treatment_', char(currCondition)];
                                    end
                                elseif ismember(currMouse, [optionsFile.cohort(cohortNo).control.maleMice, ...
                                        optionsFile.cohort(cohortNo).control.femaleMice])
                                    if isempty(currCondition)
                                        groupLabel = 'Control';
                                    else
                                        groupLabel = ['Control_', char(currCondition)];
                                    end
                                else
                                    % For cohorts without treatment/control distinction (like 5HT study)
                                    if isempty(currCondition)
                                        groupLabel = 'Experimental';
                                    else
                                        groupLabel = char(currCondition);
                                    end
                                end
                                
                                % Store individual mouse data
                                rowCounter = rowCounter + 1;
                                mouseData(rowCounter, :) = {
                                    currMouse, ...
                                    MouseInfoTable.Sex, ...
                                    groupLabel, ...
                                    currTask, ...
                                    iRep, ...
                                    conditionStr, ...
                                    totalRewards, ...
                                    totalTrials, ...
                                    rewardRate
                                };
                            end
                            
                        else
                            disp(['Warning: Data files not found for mouse ', currMouse, ...
                                ', task ', currTask, ', condition ', char(currCondition), ...
                                ', repetition ', num2str(iRep)]);
                        end
                        
                    catch ME
                        disp(['Error processing mouse ', currMouse, ': ', ME.message]);
                    end
                end % repetition loop
            end % task loop
        end % condition loop
    end % mouse loop
    
    % Convert to table
    if exist('mouseData', 'var') && ~isempty(mouseData)
        varNames = {'MouseID', 'Sex', 'Group', 'Task', 'Repetition', 'Condition', ...
            'TotalRewards', 'TotalTrials', 'RewardRate'};
        
        % Convert to table
        mouseTable = table(mouseData(:,1), mouseData(:,2), mouseData(:,3), mouseData(:,4), ...
            cell2mat(mouseData(:,5)), mouseData(:,6), cell2mat(mouseData(:,7)), ...
            cell2mat(mouseData(:,8)), cell2mat(mouseData(:,9)), ...
            'VariableNames', varNames);
        
        % Convert cell arrays to appropriate types
        mouseTable.MouseID = string(mouseTable.MouseID);
        mouseTable.Sex = string(mouseTable.Sex);
        mouseTable.Group = string(mouseTable.Group);
        mouseTable.Task = string(mouseTable.Task);
        mouseTable.Condition = string(mouseTable.Condition);
        
        % Save results
        savePath = [optionsFile.paths.cohort(cohortNo).groupLevel, optionsFile.cohort(cohortNo).taskPrefix, ...
            optionsFile.cohort(cohortNo).name, '_RewardsData'];
        
        % Save mouse data
        save([savePath, '.mat'], 'mouseTable');
        writetable(mouseTable, [savePath, '.csv']);
        
        disp(['Results saved for cohort ', optionsFile.cohort(cohortNo).name]);
        disp(['Mouse data: ', savePath, '.csv']);
        
    else
        disp(['No data found for cohort ', optionsFile.cohort(cohortNo).name]);
    end

disp(['Rewards data extraction completed for cohort ', optionsFile.cohort(cohortNo).name, '.']);
end