function extractRewardsData(cohortNo)

%% extractRewardsData - Extract and visualise reward performance data
%
% This function extracts reward-related behavioral data from mouse experiments
% and creates raincloud plots to visualize performance across treatment groups.
% The function generates plots for total rewards, total trials, reward rate,
% and a combined summary plot.
%
% SYNTAX: extractRewardsData(cohortNo)
%
% INPUT:
%   cohortNo - integer, cohort number (see optionsFile for cohort specifications)
%
% OUTPUT:
%   Creates raincloud plots and saves them as .fig and .png files
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

%% INITIALISE Variables
if exist('optionsFile.mat','file')==2
    load('optionsFile.mat');
else
    optionsFile = runOptions();
end

% Get cohort specifications
nTasks = numel(optionsFile.cohort(cohortNo).testTask);
nReps = optionsFile.cohort(cohortNo).taskRepetitions;
[mouseIDs, nSize] = getSampleVars(optionsFile, cohortNo, []);

% Determine grouping variable based on cohort
if ~isempty(optionsFile.cohort(cohortNo).subCohorts)
    % Cohort has treatment/control groups
    groupingVar = 'subCohort';
    groupNames = optionsFile.cohort(cohortNo).subCohorts;
elseif ~isempty(optionsFile.cohort(cohortNo).conditions)
    % Cohort has different conditions (e.g., drug doses)
    groupingVar = 'condition';
    groupNames = optionsFile.cohort(cohortNo).conditions;
elseif optionsFile.cohort(cohortNo).taskRepetitions > 1
    % Cohort has task repetitions - group by repetition
    groupingVar = 'repetition';
    groupNames = arrayfun(@(x) ['Rep', num2str(x)], 1:optionsFile.cohort(cohortNo).taskRepetitions, 'UniformOutput', false);
else
    % No grouping variables - treat all mice as single group
    warning('Cohort %d has no grouping variables. Creating single group analysis.', cohortNo);
    groupingVar = 'single';
    groupNames = {'all_mice'};
end

if isempty(optionsFile.cohort(cohortNo).conditions)
    nConditions = 1;
    currCondition = [];
else
    nConditions = numel(optionsFile.cohort(cohortNo).conditions);
end

%% CREATE DATA TABLE
% Initialise table to store all reward data
varTypes = {'string', 'string', 'string', 'string', 'double', 'double', 'double', 'double'};
varNames = {'MouseID', 'Sex', 'Group', 'Task', 'TotalRewards', 'TotalTrials', 'RewardRate', 'Omissions'};
rewardDataTable = table('Size', [0, length(varNames)], ...
    'VariableTypes', varTypes, 'VariableNames', varNames);

%% EXTRACT DATA
for iTask = 1:nTasks
    currTask = optionsFile.cohort(cohortNo).testTask(iTask).name;

    for iCondition = 1:max(nConditions, 1)
        if nConditions > 1
            currCondition = optionsFile.cohort(cohortNo).conditions{iCondition};
        end

        for iRep = 1:nReps
            for iMouse = 1:nSize
                currMouse = mouseIDs{iMouse};

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

                        % Check exclusion criteria first
                        if isfield(MouseInfoTable, 'exclCrit1_met') && isfield(MouseInfoTable, 'exclCrit2_met')
                            if MouseInfoTable.exclCrit1_met || MouseInfoTable.exclCrit2_met
                                % Skip this mouse - excluded based on criteria
                                continue;
                            end
                        else
                            % Calculate exclusion criteria if not already done
                            omissions = sum(isnan(ExperimentTaskTable.Choice));
                            totalTrials = height(ExperimentTaskTable);

                            % Check omission percentage
                            if omissions > (totalTrials * optionsFile.cohort(cohortNo).exclCriteria(1).cutoff)
                                continue; % Exclude this mouse
                            end

                            % Check consecutive omissions
                            NaNrows = find(isnan(ExperimentTaskTable.Choice));
                            if ~isempty(NaNrows)
                                NaNDiffs = [NaNrows; totalTrials+1] - [0; NaNrows];
                                consecNaNs = zeros(1, numel(NaNDiffs));
                                consecNaNs(NaNDiffs == 1) = 1;
                                f = find(diff([0, consecNaNs, 0] == 1));
                                if ~isempty(f)
                                    nConsecNaNs = f(2:2:end) - f(1:2:end-1);
                                    if any(nConsecNaNs > optionsFile.cohort(cohortNo).exclCriteria(2).cutoff)
                                        continue; % Exclude this mouse
                                    end
                                end
                            end
                        end

                        % Calculate reward metrics
                        totalRewards = sum(ExperimentTaskTable.Outcome, 'omitnan');
                        validTrials = ~isnan(ExperimentTaskTable.Choice);
                        totalTrials = sum(validTrials);
                        omissions = sum(isnan(ExperimentTaskTable.Choice));
                        rewardRate = totalRewards / totalTrials; % Keep as proportion (0-1)

                        % Determine group assignment
                        if strcmp(groupingVar, 'subCohort')
                            % Check which subCohort this mouse belongs to
                            if ismember(currMouse, [optionsFile.cohort(cohortNo).treatment.maleMice, ...
                                    optionsFile.cohort(cohortNo).treatment.femaleMice])
                                groupLabel = 'treatment';
                            else
                                groupLabel = 'control';
                            end
                        elseif strcmp(groupingVar, 'condition')
                            % Use condition as group
                            groupLabel = currCondition;
                        elseif strcmp(groupingVar, 'repetition')
                            % Use repetition as group
                            groupLabel = ['Rep', num2str(iRep)];
                        else
                            % Single group
                            groupLabel = 'all_mice';
                        end

                        % Create task label
                        if nReps > 1 && ~strcmp(groupingVar, 'repetition')
                            taskLabel = [currTask, '_Rep', num2str(iRep)];
                        else
                            taskLabel = currTask;
                        end

                        if nConditions > 1 && ~strcmp(groupingVar, 'condition')
                            taskLabel = [taskLabel, '_', currCondition];
                        end

                        % Add row to table
                        newRow = {currMouse, MouseInfoTable.Sex, groupLabel, taskLabel, ...
                            totalRewards, totalTrials, rewardRate, omissions};
                        rewardDataTable = [rewardDataTable; newRow];

                    end

                catch ME
                    warning('Could not load data for mouse %s: %s', currMouse, ME.message);
                end
            end
        end
    end
end

%% EXCLUDE DATA BASED ON CRITERIA (if needed)
% Remove any rows with missing essential data
validRows = ~isnan(rewardDataTable.TotalRewards) & ~isnan(rewardDataTable.TotalTrials);
rewardDataTable = rewardDataTable(validRows, :);

%% SAVE DATA TABLE
savePath = [optionsFile.paths.cohort(cohortNo).groupLevel, optionsFile.cohort(cohortNo).taskPrefix, ...
    optionsFile.cohort(cohortNo).name, '_RewardDataTable'];
save([savePath, '.mat'], 'rewardDataTable');
writetable(rewardDataTable, [savePath, '.csv']);
disp(['Reward data table saved to: ', savePath]);

%% CREATE RAINCLOUD PLOTS
createRewardRaincloudPlots(rewardDataTable, optionsFile, cohortNo, groupingVar);

end

%% RAINCLOUD PLOTTING FUNCTION
function createRewardRaincloudPlots(dataTable, optionsFile, cohortNo, groupingVar)

% Determine plot title and group order based on grouping
if strcmp(groupingVar, 'subCohort')
    plotTitle = 'Treatment vs Control';
    groupNames = {'Control', 'Treatment'};  % Control first (left side) with capital letters
elseif strcmp(groupingVar, 'single')
    plotTitle = 'All Mice';
    groupNames = {'all_mice'};
elseif strcmp(groupingVar, 'repetition')
    plotTitle = 'Across Task Repetitions';
    groupNames = unique(dataTable.Group);
else
    plotTitle = 'Across Conditions';
    uniqueGroups = unique(dataTable.Group);

    % For cohort 3, ensure specific order: saline > 5mg > 10mg
    if cohortNo == 3
        desiredOrder = {'saline', '5mg', '10mg'};
        groupNames = {};
        for i = 1:length(desiredOrder)
            if any(strcmp(uniqueGroups, desiredOrder{i}))
                % Capitalize first letter
                if strcmp(desiredOrder{i}, 'saline')
                    groupNames{end+1} = 'Saline';
                else
                    groupNames{end+1} = desiredOrder{i};
                end
            end
        end
        % Add any remaining groups not in the desired order
        remainingGroups = setdiff(uniqueGroups, desiredOrder);
        groupNames = [groupNames, remainingGroups'];
    else
        groupNames = uniqueGroups;
    end
end

%% 1. TOTAL REWARDS RAINCLOUD PLOT
figure('Position', [100 100 800 600], 'Color', 'white');
% Use dark maroon color scheme for Total Rewards across all groups
rewardColors = struct('male', [0.4 0.1 0.1], 'female', [0.7 0.3 0.3], ...
    'group', [0.5 0.2 0.2], 'edge', [0.2 0.05 0.05]);
plotMetricRaincloud(dataTable.TotalRewards, dataTable.Group, dataTable.Sex, groupNames, rewardColors);
ylabel('Total Rewards', 'FontSize', 20, 'FontName', 'Arial');
title(['Total Rewards: ', plotTitle], 'FontSize', 24, 'FontName', 'Arial');
formatRaincloudPlot(groupNames, true, 'rewards', cohortNo);
savePlot([optionsFile.paths.cohort(cohortNo).groupLevel, 'TotalRewards_RaincloudPlot']);

%% 2. TOTAL TRIALS RAINCLOUD PLOT
figure('Position', [120 120 800 600], 'Color', 'white');
% Use teal color scheme for Total Trials across all groups
trialColors = struct('male', [0.1 0.4 0.4], 'female', [0.3 0.7 0.7], ...
    'group', [0.2 0.5 0.5], 'edge', [0.05 0.2 0.2]);
plotMetricRaincloud(dataTable.TotalTrials, dataTable.Group, dataTable.Sex, groupNames, trialColors);
ylabel('Total Trials Completed', 'FontSize', 20, 'FontName', 'Arial');
title(['Total Trials: ', plotTitle], 'FontSize', 24, 'FontName', 'Arial');
formatRaincloudPlot(groupNames, true, 'trials', cohortNo);
savePlot([optionsFile.paths.cohort(cohortNo).groupLevel, 'TotalTrials_RaincloudPlot']);

%% 3. REWARD RATE RAINCLOUD PLOT
figure('Position', [140 140 800 600], 'Color', 'white');
% Use consistent purple color scheme for Reward Rate across all groups
rateColors = struct('male', [0.4 0.1 0.4], 'female', [0.7 0.4 0.7], ...
    'group', [0.5 0.2 0.5], 'edge', [0.2 0.05 0.2]);
plotMetricRaincloud(dataTable.RewardRate, dataTable.Group, dataTable.Sex, groupNames, rateColors);
ylabel('Reward Rate (Proportion)', 'FontSize', 20, 'FontName', 'Arial');
title(['Reward Rate: ', plotTitle], 'FontSize', 24, 'FontName', 'Arial');
ylim([0, 1]); % Set limits from 0 to 1 for proportion
% Add chance line at 0.5
hold on;
plot(xlim, [0.5, 0.5], 'k--', 'LineWidth', 2, 'DisplayName', 'Chance Level');
hold off;
formatRaincloudPlot(groupNames, true, 'rate', cohortNo);
savePlot([optionsFile.paths.cohort(cohortNo).groupLevel, 'RewardRate_RaincloudPlot']);

%% 4. COMBINED SUMMARY PLOT (3 subplots)
figure('Position', [160 160 1200 400], 'Color', 'white');

% Total Rewards subplot
subplot(1, 3, 1);
rewardColors = struct('male', [0.4 0.1 0.1], 'female', [0.7 0.3 0.3], ...
    'group', [0.5 0.2 0.2], 'edge', [0.2 0.05 0.05]);
plotMetricRaincloud(dataTable.TotalRewards, dataTable.Group, dataTable.Sex, groupNames, rewardColors);
ylabel('Total Rewards', 'FontSize', 16, 'FontName', 'Arial');
title('Total Rewards', 'FontSize', 18, 'FontName', 'Arial');
formatRaincloudPlot(groupNames, false, 'rewards', cohortNo); % No legend for subplots

% Total Trials subplot
subplot(1, 3, 2);
trialColors = struct('male', [0.1 0.4 0.4], 'female', [0.3 0.7 0.7], ...
    'group', [0.2 0.5 0.5], 'edge', [0.05 0.2 0.2]);
plotMetricRaincloud(dataTable.TotalTrials, dataTable.Group, dataTable.Sex, groupNames, trialColors);
ylabel('Total Trials', 'FontSize', 16, 'FontName', 'Arial');
title('Total Trials', 'FontSize', 18, 'FontName', 'Arial');
formatRaincloudPlot(groupNames, false, 'trials', cohortNo);

% Reward Rate subplot
subplot(1, 3, 3);
rateColors = struct('male', [0.4 0.1 0.4], 'female', [0.7 0.4 0.7], ...
    'group', [0.5 0.2 0.5], 'edge', [0.2 0.05 0.2]);
plotMetricRaincloud(dataTable.RewardRate, dataTable.Group, dataTable.Sex, groupNames, rateColors);
ylabel('Reward Rate', 'FontSize', 16, 'FontName', 'Arial');
title('Reward Rate', 'FontSize', 18, 'FontName', 'Arial');
ylim([0, 1]);
% Add chance line
hold on;
plot(xlim, [0.5, 0.5], 'k--', 'LineWidth', 1.5);
hold off;
formatRaincloudPlot(groupNames, true, 'rate', cohortNo); % Include legend only on last subplot

% Add overall title
sgtitle(['Reward Performance Summary: ', plotTitle], 'FontSize', 20, 'FontName', 'Arial');

savePlot([optionsFile.paths.cohort(cohortNo).groupLevel, 'RewardSummary_RaincloudPlot']);

end

%% METRIC-BASED RAINCLOUD PLOTTING FUNCTION
function plotMetricRaincloud(data, groupLabels, sexLabels, groupNames, metricColors)

hold on;
nGroups = length(groupNames);
xPositions = 1:nGroups;

for iGroup = 1:nGroups
    groupName = groupNames{iGroup};
    % Match display names to data names
    if strcmp(groupName, 'Control')
        dataGroupName = 'control';
    elseif strcmp(groupName, 'Treatment')
        dataGroupName = 'treatment';
    elseif strcmp(groupName, 'Saline')
        dataGroupName = 'saline';
    else
        dataGroupName = groupName;
    end

    groupIdx = strcmp(groupLabels, dataGroupName);

    if sum(groupIdx) > 0
        groupData = data(groupIdx);
        groupSex = sexLabels(groupIdx);

        % Remove NaN values
        validIdx = ~isnan(groupData);
        groupData = groupData(validIdx);
        groupSex = groupSex(validIdx);

        if ~isempty(groupData)
            % Use consistent metric colors for all groups
            plotRaincloudWithSex(groupData, groupSex, xPositions(iGroup), metricColors);
        end
    end
end

xlim([0.5, nGroups + 0.5]);

end

%% INDIVIDUAL RAINCLOUD PLOTTING FUNCTION
function plotRaincloudWithSex(data, sexLabels, xPos, colours)

if isempty(data); return; end

%% 1. VIOLIN PLOT (Density Distribution)
try
    [f, xi] = ksdensity(data);
    f = f / max(f) * 0.2;
    fill([xPos + f, xPos * ones(1, length(f))], [xi, fliplr(xi)], ...
        colours.group, 'FaceAlpha', 0.9, 'EdgeColor', 'none');
catch
    % If ksdensity fails (e.g., all values identical), create simple rectangle
    dataRange = [min(data) - 0.1, max(data) + 0.1];
    if dataRange(1) == dataRange(2)
        dataRange = [dataRange(1) - 1, dataRange(2) + 1];
    end
    rectangle('Position', [xPos, dataRange(1), 0.2, diff(dataRange)], ...
        'FaceColor', colours.group, 'FaceAlpha', 0.9, 'EdgeColor', 'none');
end

%% 2. INDIVIDUAL DATA POINTS (Sex-Coded Scatter)
jitter = 0.05 * randn(length(data), 1);

for iPoint = 1:length(data)
    if strcmp(sexLabels{iPoint}, 'male')
        pointColour = colours.male;
        markerShape = 's';
    else
        pointColour = colours.female;
        markerShape = '^';
    end

    h = scatter(xPos - 0.2 + jitter(iPoint), data(iPoint), ...
        110, pointColour, 'filled', markerShape);
    h.MarkerFaceAlpha = 0.9;
    h.MarkerEdgeColor = colours.edge;
    h.LineWidth = 0.5;
end

%% 3. BOX PLOT (Summary Statistics)
q = quantile(data, [0.25, 0.5, 0.75]);

if isequal(colours.group, [0.5 0.5 0.5])
    boxFillColour = [0.9 0.95 1.0];
else
    boxFillColour = [1.0 0.98 0.92];
end

rectangle('Position', [xPos - 0.05, q(1), 0.1, q(3) - q(1)], ...
    'FaceColor', boxFillColour, 'EdgeColor', colours.group, 'LineWidth', 2);

line([xPos - 0.05, xPos + 0.05], [q(2), q(2)], ...
    'Color', colours.group, 'LineWidth', 3);

end

%% FORMATTING FUNCTION
function formatRaincloudPlot(groupNames, showLegend, groupingVar, cohortNo)

if nargin < 2
    showLegend = true;
end
if nargin < 3
    groupingVar = 'subCohort';
end
if nargin < 4
    cohortNo = 1;
end

set(gca, 'XTick', 1:length(groupNames), 'XTickLabel', groupNames, ...
    'FontName', 'Arial', 'FontSize', 16, 'Box', 'off');
grid on;
set(gca, 'GridAlpha', 0.3,'GridLineStyle', ':');

% Fix y-axis to end exactly at the last tick
ax = gca;
if strcmp(groupingVar, 'rate')
    % For reward rate, keep 0-1 limits regardless of cohort
    ax.YLim = [0, 1];
    ax.YTick = 0:0.1:1;
elseif cohortNo == 1
    ax.YLim = [0, 180];
    ax.YTick = 0:20:180;
else
    ax.YLim = [0, 280];
    ax.YTick = 0:40:280;
end

if showLegend
    % Create legend with metric-specific colors
    if strcmp(groupingVar, 'rewards')
        % Dark maroon colors for Total Rewards
        p1 = line(NaN, NaN, 'Marker', 's', 'MarkerSize', 10, 'MarkerFaceColor', [0.4 0.1 0.1], ...
            'MarkerEdgeColor', [0.2 0.05 0.05], 'LineStyle', 'none', 'LineWidth', 0.5);
        p2 = line(NaN, NaN, 'Marker', '^', 'MarkerSize', 10, 'MarkerFaceColor', [0.7 0.3 0.3], ...
            'MarkerEdgeColor', [0.2 0.05 0.05], 'LineStyle', 'none', 'LineWidth', 0.5);
    elseif strcmp(groupingVar, 'trials')
        % Teal colors for Total Trials
        p1 = line(NaN, NaN, 'Marker', 's', 'MarkerSize', 10, 'MarkerFaceColor', [0.1 0.4 0.4], ...
            'MarkerEdgeColor', [0.05 0.2 0.2], 'LineStyle', 'none', 'LineWidth', 0.5);
        p2 = line(NaN, NaN, 'Marker', '^', 'MarkerSize', 10, 'MarkerFaceColor', [0.3 0.7 0.7], ...
            'MarkerEdgeColor', [0.05 0.2 0.2], 'LineStyle', 'none', 'LineWidth', 0.5);
    elseif strcmp(groupingVar, 'rate')
        % Purple colors for Reward Rate
        p1 = line(NaN, NaN, 'Marker', 's', 'MarkerSize', 10, 'MarkerFaceColor', [0.4 0.1 0.4], ...
            'MarkerEdgeColor', [0.2 0.05 0.2], 'LineStyle', 'none', 'LineWidth', 0.5);
        p2 = line(NaN, NaN, 'Marker', '^', 'MarkerSize', 10, 'MarkerFaceColor', [0.7 0.4 0.7], ...
            'MarkerEdgeColor', [0.2 0.05 0.2], 'LineStyle', 'none', 'LineWidth', 0.5);
    else
        % Default colors for other cases
        p1 = line(NaN, NaN, 'Marker', 's', 'MarkerSize', 10, 'MarkerFaceColor', [0.3 0.3 0.3], ...
            'MarkerEdgeColor', 'black', 'LineStyle', 'none', 'LineWidth', 0.5);
        p2 = line(NaN, NaN, 'Marker', '^', 'MarkerSize', 10, 'MarkerFaceColor', [0.7 0.7 0.7], ...
            'MarkerEdgeColor', 'black', 'LineStyle', 'none', 'LineWidth', 0.5);
    end

    legend([p1, p2], {'Male', 'Female'}, 'FontSize', 12, 'FontName', 'Arial', ...
        'Location', 'northeast', 'EdgeColor', 'white', 'Color', 'white', ...
        'Box', 'on');
end

hold off;

end

%% SAVE PLOT FUNCTION
function savePlot(basePath)

saveas(gcf, [basePath, '.fig']);
print(gcf, [basePath, '.png'], '-dpng', '-r300');
disp(['Plot saved to: ', basePath]);

end