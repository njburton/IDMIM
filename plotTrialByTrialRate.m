function plotTrialByTrialRate(cohortNo)

% plotTrialByTrialRate - Plot trial-by-trial reward rate across task phases
%
% This function creates a trial-by-trial analysis of reward rate (success rate)
% across all trials of the task, showing how different groups perform as they
% encounter different task phases (stable vs volatile periods, contingency changes).
% The plot reveals learning dynamics, adaptation patterns, and group differences
% in behavioural flexibility across the task.
%
% SYNTAX: plotTrialByTrialRate(cohortNo)
%
% INPUT: cohortNo - integer, cohort number (1, 2, or 3)
%                   1: 2023_UCMS (180 trials, treatment vs control)
%                   2: 2024_HGFPilot (280 trials, task repetitions)
%                   3: 5HT (280 trials, drug conditions)
%
% OUTPUT: Figure showing trial-by-trial reward rate with:
%         - X-axis: Trial number (1 to totalTrials)
%         - Y-axis: Reward rate (moving average)
%         - Different lines for each group
%         - Shaded regions indicating task phases
%         - Saved as high-resolution .png and .fig files
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

% Load options and setup paths
if exist('optionsFile.mat','file')==2
    load('optionsFile.mat');
else
    optionsFile = runOptions();
end

disp(['Creating trial-by-trial reward rate plot for cohort ', num2str(cohortNo), ': ', optionsFile.cohort(cohortNo).name]);

%% Get cohort-specific variables
nTasks = numel(optionsFile.cohort(cohortNo).testTask);
nReps = optionsFile.cohort(cohortNo).taskRepetitions;
nTrials = optionsFile.cohort(cohortNo).nTrials;
[mouseIDs, nSize] = getSampleVars(optionsFile, cohortNo, []);

% Handle different condition structures
if isempty(optionsFile.cohort(cohortNo).conditions)
    nConditions = 1;
    conditions = {[]};
else
    nConditions = numel(optionsFile.cohort(cohortNo).conditions);
    conditions = optionsFile.cohort(cohortNo).conditions;
end

%% Set up parameters for reward rate calculation
windowSize = 10; % Moving average window size
stepSize = 1;    % Step size for sliding window

%% Load and process trial-by-trial data with exclusion criteria checking
allTrialData = struct();
groupLabels = {};
groupCounter = 0;

% Special handling for Cohort 2 (repetitions)
if cohortNo == 2
    % Process each repetition separately
    for iRep = 1:nReps
        groupCounter = groupCounter + 1;
        groupLabels{groupCounter} = sprintf('Repetition %d', iRep);
        
        % Process mice with exclusion criteria checking
        [groupTrialData, validMice] = processValidMiceWithExclusion(mouseIDs, [], nTasks, nReps, iRep, optionsFile, cohortNo);
        
        if validMice > 0
            groupRewardRate = calculateTrialByTrialRate(groupTrialData, windowSize, stepSize);
            allTrialData(groupCounter).rewardRate = groupRewardRate;
            allTrialData(groupCounter).nMice = validMice;
            allTrialData(groupCounter).label = groupLabels{groupCounter};
            allTrialData(groupCounter).repetitionData = groupTrialData; % Store for combined calculation
            disp(['Group ', groupLabels{groupCounter}, ': ', num2str(validMice), ' valid mice']);
        else
            % Still create the structure even if no valid mice
            allTrialData(groupCounter).rewardRate = [];
            allTrialData(groupCounter).nMice = 0;
            allTrialData(groupCounter).label = groupLabels{groupCounter};
            allTrialData(groupCounter).repetitionData = [];
            disp(['Group ', groupLabels{groupCounter}, ': No valid mice found']);
        end
    end
    
    % Add combined line (all repetitions together)
    groupCounter = groupCounter + 1;
    groupLabels{groupCounter} = 'All Repetitions Combined';
    
    % Combine all repetition data
    allRepData = [];
    totalValidMice = 0;
    for iGroup = 1:groupCounter-1
        if isfield(allTrialData(iGroup), 'repetitionData') && ~isempty(allTrialData(iGroup).repetitionData)
            allRepData = [allRepData; allTrialData(iGroup).repetitionData];
            totalValidMice = totalValidMice + allTrialData(iGroup).nMice;
        end
    end
    
    if ~isempty(allRepData)
        combinedRewardRate = calculateTrialByTrialRate(allRepData, windowSize, stepSize);
        allTrialData(groupCounter).rewardRate = combinedRewardRate;
        allTrialData(groupCounter).nMice = totalValidMice;
        allTrialData(groupCounter).label = groupLabels{groupCounter};
    end

else
    % Processing for Cohorts 1 and 3
    if cohortNo == 1
        % Process treatment vs control groups
        groupTypes = {'treatment', 'control'};
        
        for iGroup = 1:length(groupTypes)
            currGroupType = groupTypes{iGroup};
            groupCounter = groupCounter + 1;
            groupLabels{groupCounter} = currGroupType;
            
            % Get mice for this group
            groupMouseIDs = [optionsFile.cohort(cohortNo).(currGroupType).maleMice, ...
                            optionsFile.cohort(cohortNo).(currGroupType).femaleMice];
            
            % Process mice with exclusion criteria checking
            [groupTrialData, validMice] = processValidMiceWithExclusion(groupMouseIDs, [], nTasks, nReps, 1, optionsFile, cohortNo);
            
            if validMice > 0
                groupRewardRate = calculateTrialByTrialRate(groupTrialData, windowSize, stepSize);
                allTrialData(groupCounter).rewardRate = groupRewardRate;
                allTrialData(groupCounter).nMice = validMice;
                allTrialData(groupCounter).label = groupLabels{groupCounter};
                disp(['Group ', groupLabels{groupCounter}, ': ', num2str(validMice), ' valid mice']);
            else
                % Still create the structure even if no valid mice
                allTrialData(groupCounter).rewardRate = [];
                allTrialData(groupCounter).nMice = 0;
                allTrialData(groupCounter).label = groupLabels{groupCounter};
                disp(['Group ', groupLabels{groupCounter}, ': No valid mice found']);
            end
        end
        
    else % Cohort 3
        % Process drug conditions
        for iCondition = 1:nConditions
            currCondition = conditions{iCondition};
            groupCounter = groupCounter + 1;
            groupLabels{groupCounter} = char(currCondition);
            
            % Process mice with exclusion criteria checking
            [groupTrialData, validMice] = processValidMiceWithExclusion(mouseIDs, currCondition, nTasks, nReps, 1, optionsFile, cohortNo);
            
            if validMice > 0
                groupRewardRate = calculateTrialByTrialRate(groupTrialData, windowSize, stepSize);
                allTrialData(groupCounter).rewardRate = groupRewardRate;
                allTrialData(groupCounter).nMice = validMice;
                allTrialData(groupCounter).label = groupLabels{groupCounter};
                disp(['Group ', groupLabels{groupCounter}, ': ', num2str(validMice), ' valid mice']);
            else
                % Still create the structure even if no valid mice
                allTrialData(groupCounter).rewardRate = [];
                allTrialData(groupCounter).nMice = 0;
                allTrialData(groupCounter).label = groupLabels{groupCounter};
                disp(['Group ', groupLabels{groupCounter}, ': No valid mice found']);
            end
        end
    end
end

%% Create the plot
if ~isempty(allTrialData)
    fig = createTrialByTrialPlot(allTrialData, groupLabels, cohortNo, optionsFile, windowSize);
    
    % Save the figure
    savePath = [optionsFile.paths.cohort(cohortNo).groupLevel];
    if ~exist(savePath, 'dir')
        mkdir(savePath);
    end
    
    fileName = sprintf('%s_TrialByTrialRewardRate', optionsFile.cohort(cohortNo).name);
    
    % Save as both .fig and .png
    savefig(fig, [savePath, fileName, '.fig']);
    print(fig, [savePath, fileName, '.png'], '-dpng', '-r300');
    
    disp(['Figure saved: ', savePath, fileName]);
else
    error('No valid data found for any group in cohort %d', cohortNo);
end

end

%% Helper function to process valid mice with exclusion criteria checking
function [groupTrialData, validMice] = processValidMiceWithExclusion(mouseIDs, fileCondition, nTasks, nReps, repToProcess, optionsFile, cohortNo)
    groupTrialData = [];
    validMice = 0;
    
    for iMouse = 1:length(mouseIDs)
        currMouse = char(mouseIDs{iMouse});
        
        for iTask = 1:nTasks
            currTask = optionsFile.cohort(cohortNo).testTask(iTask).name;
            
            % For cohort 2, process specific repetition; for others, process all reps
            if cohortNo == 2
                repsToProcess = repToProcess;
            else
                repsToProcess = 1:nReps;
            end
            
            for iRep = repsToProcess
                try
                    % Load experimental data
                    loadExpName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, ...
                        [], fileCondition, iRep, nReps, []);
                    expPath = [char(optionsFile.paths.cohort(cohortNo).data), 'mouse', char(currMouse), '_', ...
                        loadExpName, '.mat'];
                    
                    % Load mouse info
                    loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, ...
                        [], fileCondition, iRep, nReps, 'info');
                    infoPath = [char(optionsFile.paths.cohort(cohortNo).data), 'mouse', char(currMouse), '_', ...
                        loadInfoName, '.mat'];
                    
                    if isfile(expPath) && isfile(infoPath)
                        load(expPath, 'ExperimentTaskTable');
                        load(infoPath, 'MouseInfoTable');
                        
                        % Check exclusion criteria - same logic as extractRewardsData
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
                            % Extract trial-by-trial outcomes
                            outcomes = ExperimentTaskTable.Outcome;
                            choices = ExperimentTaskTable.Choice;
                            outcomes(isnan(choices)) = NaN;
                            
                            % Store trial data
                            if isempty(groupTrialData)
                                groupTrialData = outcomes';
                            else
                                groupTrialData(end+1, :) = outcomes';
                            end
                            validMice = validMice + 1;
                        end
                    end
                catch ME
                    disp(['Warning: Could not load data for mouse ', currMouse, ': ', ME.message]);
                end
            end % repetition loop
        end % task loop
    end % mouse loop
end

%% Helper function to calculate trial-by-trial reward rate
function rewardRate = calculateTrialByTrialRate(trialData, windowSize, stepSize)
    % Calculate moving average reward rate across trials
    % Input: trialData (nMice x nTrials matrix)
    % Output: rewardRate (1 x nTrials vector)
    
    [nMice, nTrials] = size(trialData);
    rewardRate = NaN(1, nTrials);
    
    for trial = 1:stepSize:nTrials
        % Define window boundaries
        windowStart = max(1, trial - floor(windowSize/2));
        windowEnd = min(nTrials, trial + floor(windowSize/2));
        
        % Extract window data
        windowData = trialData(:, windowStart:windowEnd);
        
        % Calculate reward rate (excluding NaN/omissions)
        validTrials = ~isnan(windowData);
        if sum(validTrials(:)) > 0
            rewardRate(trial) = sum(windowData(validTrials)) / sum(validTrials(:));
        end
    end
    
    % Interpolate any remaining NaN values
    validIdx = ~isnan(rewardRate);
    if sum(validIdx) > 1
        rewardRate = interp1(find(validIdx), rewardRate(validIdx), 1:nTrials, 'linear', 'extrap');
    end
end

%% Helper function to create the actual plot
function fig = createTrialByTrialPlot(allTrialData, groupLabels, cohortNo, optionsFile, windowSize)
    
    fig = figure('Position', [100, 100, 1200, 700], 'Color', 'white');
    
    % Set up colors
    colors = {
        [0.2, 0.4, 0.8],    % Blue
        [0.8, 0.2, 0.2],    % Red  
        [0.2, 0.7, 0.3],    % Green
        [0.9, 0.5, 0.1],    % Orange
        [0.6, 0.2, 0.8],    % Purple
        [0.8, 0.8, 0.2]     % Yellow
    };
    
    nTrials = optionsFile.cohort(cohortNo).nTrials;
    trials = 1:nTrials;
    
    hold on;
    
    % Plot each group with appropriate styling
    for iGroup = 1:length(allTrialData)
        if isfield(allTrialData(iGroup), 'rewardRate') && ~isempty(allTrialData(iGroup).rewardRate)
            % Special styling for the combined line in Cohort 2
            if cohortNo == 2 && iGroup == length(allTrialData) % Last group is combined
                plot(trials, allTrialData(iGroup).rewardRate, ...
                    'LineWidth', 3, ... % Thicker line
                    'Color', [0.2, 0.2, 0.2], ... % Black
                    'LineStyle', '-', ...
                    'DisplayName', sprintf('%s (n=%d)', allTrialData(iGroup).label, allTrialData(iGroup).nMice));
            else
                plot(trials, allTrialData(iGroup).rewardRate, ...
                    'LineWidth', 2.5, ...
                    'Color', colors{mod(iGroup-1, length(colors)) + 1}, ...
                    'DisplayName', sprintf('%s (n=%d)', allTrialData(iGroup).label, allTrialData(iGroup).nMice));
            end
        end
    end
    
    % Add task phase annotations based on cohort
    addPhaseAnnotations(cohortNo, optionsFile);
    
    % Formatting
    xlabel('Trial Number', 'FontSize', 14);
    ylabel(sprintf('Reward Rate (moving avg, win)', windowSize), 'FontSize', 14, 'FontName', Arial );
    title(sprintf('Trial-by-Trial Performance - %s', optionsFile.cohort(cohortNo).name), 'FontSize', 16);
    
    % Set axis limits
    xlim([1, nTrials]);
    ylim([0, 1]);
    
    % Add reference lines
    plot([1, nTrials], [0.5, 0.5], 'k--', 'LineWidth', 1, 'HandleVisibility', 'off');
    
    % Legend and grid
    legend('Location', 'best', 'FontSize', 12);
    grid on;
    set(gca, 'FontSize', 12);
    
    % Add text box with task info
    taskInfo = sprintf('Total Trials: %d\nWindow Size: %d trials', nTrials, windowSize);
    annotation('textbox', [0.02, 0.98, 0.2, 0.1], 'String', taskInfo, ...
        'FitBoxToText', 'on', 'BackgroundColor', 'white', ...
        'EdgeColor', 'black', 'FontSize', 10);
end

%% Helper function to add task phase annotations
function addPhaseAnnotations(cohortNo, optionsFile)
    
    % Get y-axis limits for shading
    ylims = ylim;
    alpha = 0.1; % Transparency for phase shading
    
    switch cohortNo
        case 1 % UCMS - ABA2_R task
            % Simple 3-phase structure: Stable - Volatile - Stable
            phases = [
                struct('start', 1, 'end', 60, 'label', 'Stable', 'color', [0.3, 0.6, 0.9]),
                struct('start', 61, 'end', 120, 'label', 'Volatile', 'color', [0.9, 0.6, 0.3]),
                struct('start', 121, 'end', 180, 'label', 'Stable', 'color', [0.3, 0.6, 0.9])
            ];
            
        case 2 % HGF Pilot - TestTaskA
            % Stable-Volatile-Stable pattern
            phases = [
                struct('start', 1, 'end', 40, 'label', 'Stable (0.8)', 'color', [0.3, 0.6, 0.9]),
                struct('start', 41, 'end', 80, 'label', 'Volatile (0.3→0.7)', 'color', [0.9, 0.6, 0.3]),
                struct('start', 81, 'end', 120, 'label', 'Stable (0.2)', 'color', [0.3, 0.6, 0.9]),
                struct('start', 121, 'end', 160, 'label', 'Volatile (0.7→0.3)', 'color', [0.9, 0.6, 0.3]),
                struct('start', 161, 'end', 200, 'label', 'Stable (0.8)', 'color', [0.3, 0.6, 0.9]),
                struct('start', 201, 'end', 240, 'label', 'Volatile (0.3→0.7)', 'color', [0.9, 0.6, 0.3]),
                struct('start', 241, 'end', 280, 'label', 'Stable (0.2)', 'color', [0.3, 0.6, 0.9])
            ];
            
        case 3 % 5HT - Same as TestTaskA
            phases = [
                struct('start', 1, 'end', 40, 'label', 'Stable (0.8)', 'color', [0.3, 0.6, 0.9]),
                struct('start', 41, 'end', 80, 'label', 'Volatile (0.3→0.7)', 'color', [0.9, 0.6, 0.3]),
                struct('start', 81, 'end', 120, 'label', 'Stable (0.2)', 'color', [0.3, 0.6, 0.9]),
                struct('start', 121, 'end', 160, 'label', 'Volatile (0.7→0.3)', 'color', [0.9, 0.6, 0.3]),
                struct('start', 161, 'end', 200, 'label', 'Stable (0.8)', 'color', [0.3, 0.6, 0.9]),
                struct('start', 201, 'end', 240, 'label', 'Volatile (0.3→0.7)', 'color', [0.9, 0.6, 0.3]),
                struct('start', 241, 'end', 280, 'label', 'Stable (0.2)', 'color', [0.3, 0.6, 0.9])
            ];
    end
    
    % Add shaded regions for each phase
    for i = 1:length(phases)
        % Add shaded background
        fill([phases(i).start, phases(i).end, phases(i).end, phases(i).start], ...
             [ylims(1), ylims(1), ylims(2), ylims(2)], ...
             phases(i).color, 'FaceAlpha', alpha, 'EdgeColor', 'none', ...
             'HandleVisibility', 'off');
        
        % Add phase label at the top
        midPoint = (phases(i).start + phases(i).end) / 2;
        text(midPoint, ylims(2) * 0.95, phases(i).label, ...
            'HorizontalAlignment', 'center', 'FontSize', 8, ...
            'BackgroundColor', 'white', 'EdgeColor', 'none');
    end
    
    % Add vertical lines at phase boundaries
    for i = 1:length(phases)-1
        line([phases(i).end, phases(i).end], ylims, 'Color', [0.5, 0.5, 0.5], ...
            'LineStyle', '--', 'LineWidth', 0.5, 'HandleVisibility', 'off');
    end
end