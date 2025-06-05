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
            disp(['Group ', groupLabels{groupCounter}, ': ', num2str(validMice), ' valid mice']);
        else
            % Still create the structure even if no valid mice
            allTrialData(groupCounter).rewardRate = [];
            allTrialData(groupCounter).nMice = 0;
            allTrialData(groupCounter).label = groupLabels{groupCounter};
            disp(['Group ', groupLabels{groupCounter}, ': No valid mice found']);
        end
    end

else
    % Processing for Cohorts 1 and 3
    if cohortNo == 1
        % Process treatment vs control groups
        groupTypes = {'treatment', 'control'};

        for iGroup = 1:length(groupTypes)
            currGroupType = groupTypes{iGroup};
            groupCounter = groupCounter + 1;
            groupLabels{groupCounter} = [upper(currGroupType(1)), currGroupType(2:end)];

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
            conditionStr = char(currCondition);
            groupLabels{groupCounter} = [upper(conditionStr(1)), conditionStr(2:end)];

            % Process mice with exclusion criteria checking
            [groupTrialData, validMice] = processValidMiceWithExclusion(mouseIDs, currCondition, nTasks, nReps, 1, optionsFile, cohortNo);

            if validMice > 0
                groupRewardRate = calculateTrialByTrialRate(groupTrialData, windowSize, stepSize);
                allTrialData(groupCounter).rewardRate = groupRewardRate;
                allTrialData(groupCounter).nMice = validMice;
                allTrialData(groupCounter).label = groupLabels{groupCounter};
                disp(['Group ', groupLabels{groupCounter}, ': ', num2str(validMice), ' valid mice']);
            else
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

                    % Check exclusion criteria
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

% Set up colours based on cohort
if cohortNo == 1
    % Treatment vs Control
    colours = {
        [0.4, 0.0, 0.6],        % Magenta for treatment
        [0.5, 0.5, 0.5],        % Grey for control
        [0.2, 0.7, 0.3],        % Green (backup)
        [0.6, 0.2, 0.8],        % Purple (backup)
        [0.8, 0.8, 0.2],        % Yellow (backup)
        [0.2, 0.4, 0.8]         % Blue (backup)
        };
elseif cohortNo == 2
    % Task repetitions
    colours = {
        [0.8, 0.0, 0.0],        % Red for Rep 1
        [0.20, 0.63, 0.17],        % Green for Rep 2
        [0.12, 0.47, 0.71],       % Blue for Rep 3
        [0.0, 0.0, 0.0],        % Black (not used anymore)
        [0.6, 0.2, 0.8],        % Purple (backup)
        [0.8, 0.8, 0.2]         % Yellow (backup)
        };
elseif cohortNo == 3
    % Drug conditions
    colours = {
        [0.1, 0.5, 0.8],        % Steel blue for 5mg
        [0.8, 0.0, 0.0],        % Red for 10mg
        [0.5, 0.5, 0.5],        % Grey for saline
        [0.2, 0.7, 0.3],        % Green (backup)
        [0.6, 0.2, 0.8],        % Purple (backup)
        [0.8, 0.8, 0.2]         % Yellow (backup)
        };
else
    % Default colors for any other cohorts
    colours = {
        [0.2, 0.4, 0.8],    % Blue
        [0.8, 0.2, 0.2],    % Red
        [0.2, 0.7, 0.3],    % Green
        [0.9, 0.5, 0.1],    % Orange
        [0.6, 0.2, 0.8],    % Purple
        [0.8, 0.8, 0.2]     % Yellow
        };
end

nTrials = optionsFile.cohort(cohortNo).nTrials;
trials = 1:nTrials;

hold on;

% Plot each group
for iGroup = 1:length(allTrialData)
    if isfield(allTrialData(iGroup), 'rewardRate') && ~isempty(allTrialData(iGroup).rewardRate)
        plot(trials, allTrialData(iGroup).rewardRate, ...
            'LineWidth', 2.5, ...
            'Color', colours{mod(iGroup-1, length(colours)) + 1}, ...
            'DisplayName', sprintf('%s (n=%d)', allTrialData(iGroup).label, allTrialData(iGroup).nMice));
    end
end

% Add phase shading and labels
addPhaseShading(cohortNo);
addPhaseLabels(gca, cohortNo);

% Formatting
xlabel('Trial Number', 'FontSize', 24);
ylabel(sprintf('Reward Rate (moving avg)', windowSize), 'FontSize', 24, 'FontName', 'Arial');

% Set title based on cohort with Study numbering
switch cohortNo
    case 1
        title('Study 1: Trial-by-Trial Performance', 'FontSize', 24);
    case 2
        title('Study 2: Trial-by-Trial Performance', 'FontSize', 24);
    case 3
        title('Study 3: Trial-by-Trial Performance', 'FontSize', 24);
    otherwise
        title(sprintf('Trial-by-Trial Performance - %s', optionsFile.cohort(cohortNo).name), 'FontSize', 24);
end

% Set axis limits and ticks based on cohort
if cohortNo == 1
    xlim([0, 180]);
    ylim([-0.1, 1.1]);
    set(gca, 'XTick', 0:20:180, 'YTick', 0:0.1:1);  % Ticks every 20 from 0 to 180, Y-ticks every 0.1
elseif cohortNo == 2 || cohortNo == 3
    xlim([0, 280]);
    ylim([-0.1, 1.1]);
    set(gca, 'XTick', 0:40:280, 'YTick', 0:0.1:1);  % Ticks every 40 from 0 to 280, Y-ticks every 0.1
else
    % Default for any other cohorts
    xlim([1, nTrials]);
    ylim([-0.1, 1.1]);
    set(gca, 'YTick', 0:0.1:1);  % Y-ticks every 0.1
end

% Add reference lines
plot([1, nTrials], [0.5, 0.5], 'k--', 'LineWidth', 1, 'HandleVisibility', 'off');

% Add reward probability line
[~, rewardProb] = getInputSequenceData(cohortNo, optionsFile);
if ~isempty(rewardProb)
    h = plot(trials, rewardProb(1:nTrials), ':', 'LineWidth', 2, ...
        'Color', [0.84, 0.15, 0.16], ...  % Change color here (this is gray)
        'DisplayName', 'Reward Probability');
    h.Color(4) = 0.5;  % Set opacity (alpha) - 0.5 = 50% opacity
end

% Legend and grid
legend('Location', 'northeast', 'FontSize', 16, 'EdgeColor', 'none');
grid on;
set(gca, 'FontSize', 16, 'FontName', 'Arial', 'GridAlpha', 0.2, 'GridLineStyle', ':', ...
    'MinorGridColor', [0.149019607843137 0.149019607843137 0.149019607843137], ...
    'XGrid', 'on', 'XMinorTick', 'off');

% Add text box with task info
taskInfo = sprintf('Total Trials: %d\nWindow Size: %d trials', nTrials, windowSize);
annotation('textbox', [0.02, 0.98, 0.2, 0.1], 'String', taskInfo, ...
    'FitBoxToText', 'on', 'BackgroundColor', 'white', ...
    'EdgeColor', 'black', 'FontSize', 10);

end

%% Helper function to add phase shading
function addPhaseShading(cohortNo)
% Add blue shading for stable phases
alpha = 0.1;
stableColor = [0.3, 0.6, 0.9];

switch cohortNo
    case 1 % UCMS
        stablePhases = [1, 60; 121, 180];
    case {2, 3} % HGF Pilot and 5HT
        stablePhases = [1, 40; 81, 120; 161, 200; 241, 280];
end

for i = 1:size(stablePhases, 1)
    fill([stablePhases(i,1), stablePhases(i,2), stablePhases(i,2), stablePhases(i,1)], ...
        [-0.1, -0.1, 1.1, 1.1], ...
        stableColor, 'FaceAlpha', alpha, 'EdgeColor', 'none', ...
        'HandleVisibility', 'off');
end
end

%% Helper function to add phase labels
function addPhaseLabels(axes1, cohortNo)
% Add phase labels centered above the first instance of each phase type
switch cohortNo
    case 1 % UCMS cohort - ABA2_R task
        % First stable phase - center at trial 30
        text(axes1, 30, 1.05, 'Stable', ...
            'Color', [0 0.447058823529412 0.741176470588235], ...
            'FontWeight', 'bold', 'FontSize', 16, ...
            'HorizontalAlignment', 'center', 'HandleVisibility', 'off');
        % First volatile phase - center at trial 90
        text(axes1, 90, 1.05, 'Volatile', ...
            'Color', [0.635294117647059 0.0784313725490196 0.184313725490196], ...
            'FontWeight', 'bold', 'FontSize', 16, ...
            'HorizontalAlignment', 'center', 'HandleVisibility', 'off');
    case {2, 3} % HGF Pilot and 5HT cohorts - TestTaskA structure
        % First stable phase - center at trial 20
        text(axes1, 20, 1.05, 'Stable', ...
            'Color', [0 0.447058823529412 0.741176470588235], ...
            'FontWeight', 'bold', 'FontSize', 16, ...
            'HorizontalAlignment', 'center', 'HandleVisibility', 'off');
        % First volatile phase - center at trial 60
        text(axes1, 60, 1.05, 'Volatile', ...
            'Color', [0.635294117647059 0.0784313725490196 0.184313725490196], ...
            'FontWeight', 'bold', 'FontSize', 16, ...
            'HorizontalAlignment', 'center', 'HandleVisibility', 'off');
end
end

%% Helper function to get input sequence and reward probability
function [inputSeq, rewardProb] = getInputSequenceData(cohortNo, optionsFile)
switch cohortNo
    case 1 % UCMS - ABA2_R task
        % Read the input sequence file
        inputFile = fullfile(optionsFile.paths.inputsDir, optionsFile.cohort(1).name, ...
            [optionsFile.cohort(1).taskPrefix, optionsFile.cohort(1).testTask(1).name, '.txt']);
        if isfile(inputFile)
            inputSeq = readmatrix(inputFile);
        else
            disp('Error: No input sequence found.');
        end
        % Create reward probability sequence for ABA_R
        rewardProb = [0.8*ones(1,60), 0.5*ones(1,10), 0.65*ones(1,5), 0.3*ones(1,8), ...
            0.45*ones(1,12), 0.75*ones(1,6), 0.55*ones(1,11), 0.25*ones(1,8), 0.8*ones(1,60)];

    case {2, 3} % HGF Pilot and 5HT - TestTaskA
        % Read the input sequence file
        inputFile = fullfile(optionsFile.paths.inputsDir, optionsFile.cohort(cohortNo).name, ...
            [optionsFile.cohort(cohortNo).taskPrefix, optionsFile.cohort(cohortNo).testTask(1).name, '.txt']);
        if isfile(inputFile)
            inputSeq = readmatrix(inputFile);
        else
            disp('Error: No input sequence found.');
        end
        % Create reward probability sequence for TestTaskA
        rewardProb = [0.8*ones(1,40), 0.3*ones(1,20), 0.7*ones(1,20), 0.2*ones(1,40), ...
            0.7*ones(1,20), 0.3*ones(1,20), 0.8*ones(1,40), 0.3*ones(1,20), ...
            0.7*ones(1,20), 0.2*ones(1,40)];

    otherwise
        inputSeq = [];
        rewardProb = [];
end
end