function createHypothesis3_3_Table

% createHypothesis3_3_Table - Extract precision weights on prediction errors across treatment conditions
%
% This function extracts precision weights on prediction errors (psi) from fitted models
% across three treatment conditions (saline, 5mg, 10mg) for each mouse. It breaks down the
% prediction error precision weights into seven task phases (stable and volatile periods) for each
% treatment condition, allowing for analysis of how drug treatment affects precision weights
% during different volatility contexts. The resulting data table contains one row per mouse with
% precision weights from all phases and conditions, enabling statistical comparison of treatment
% effects on precision-weighted prediction errors. Exclusion criteria are applied per-condition
% rather than per-mouse. The output is saved as both .mat and .csv files.
%
% No input arguments required; configuration is loaded from optionsFile.mat.
% Output: Data table saved to the group-level results directory.
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

% Prespecify variables needed
iModel = 2;
iTask = 1;
iRep = 1;
nReps = 1;
cohortNo = 3;
subCohort = [];
currTask = optionsFile.cohort(cohortNo).testTask(1).name;
[mouseIDs, nSize] = getSampleVars(optionsFile, cohortNo, subCohort);

% Define the trial phases
phaseNames = {'stable1', 'volatile1', 'stable2', 'volatile2', 'stable3', 'volatile3', 'stable4'};
phaseRanges = {1:40, 41:80, 81:120, 121:160, 161:200, 201:240, 241:280};
numPhases = length(phaseNames);

%% EXCLUDE MICE that have NO data files at all
% Only exclude mice that have no data files for any condition
noDataArray = zeros(1, nSize);

for iMouse = 1:nSize
    currMouse = mouseIDs{iMouse};
    % Check if data exists for any condition
    hasData = false;
    for iCond = 1:length(optionsFile.cohort(cohortNo).conditions)
        loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], optionsFile.cohort(cohortNo).conditions{iCond}, iRep, nReps, 'info');
        if isfile([char(optionsFile.paths.cohort(cohortNo).data), 'mouse', char(currMouse), '_', loadInfoName, '.mat'])
            hasData = true;
            break;
        end
    end
    if ~hasData
        disp(['Data for mouse ', currMouse, ' not available in any condition']);
        noDataArray(iMouse) = iMouse;
    end
end

noDataArray = sort(noDataArray, 'descend');
noDataArray(noDataArray == 0) = [];

for i = noDataArray
    mouseIDs(i) = [];
end
nSize = numel(mouseIDs);

fprintf('Total mice with at least some data: %d\n', nSize);

% Create variable names for each condition and phase
varNames = {'ID', 'sex'};
varTypes = {'string', 'string'};

% Add columns for each condition and phase
for iCond = 1:length(optionsFile.cohort(cohortNo).conditions)
    condition = optionsFile.cohort(cohortNo).conditions{iCond};
    for iPhase = 1:numPhases
        colName = ['psi_', condition, '_', phaseNames{iPhase}];
        varNames{end+1} = colName;
        varTypes{end+1} = 'double';
    end
end

% Create table with one row per mouse
RQ3_3_dataTable = table('Size', [nSize, length(varNames)], ...
    'VariableTypes', varTypes, ...
    'VariableNames', varNames);

% Populate the table
for iMouse = 1:nSize
    currMouse = mouseIDs{iMouse};

    % Set ID
    RQ3_3_dataTable.ID(iMouse) = currMouse;

    % Get basic info (sex) from the first available condition file
    for iCond = 1:length(optionsFile.cohort(cohortNo).conditions)
        loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], optionsFile.cohort(cohortNo).conditions{iCond}, iRep, nReps, 'info');
        infoPath = [char(optionsFile.paths.cohort(cohortNo).data), 'mouse', char(currMouse), '_', loadInfoName, '.mat'];

        if isfile(infoPath)
            load(infoPath, 'MouseInfoTable');
            RQ3_3_dataTable.sex(iMouse) = MouseInfoTable.Sex;
            break;
        end
    end

    % Get precision weights (psi) for each condition and phase
    for iCond = 1:length(optionsFile.cohort(cohortNo).conditions)
        condition = optionsFile.cohort(cohortNo).conditions{iCond};

        % Check exclusion criteria for this specific condition
        shouldExcludeThisCondition = false;

        % Load info file to check exclusion criteria
        loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], condition, iRep, nReps, 'info');
        infoPath = [char(optionsFile.paths.cohort(cohortNo).data), 'mouse', char(currMouse), '_', loadInfoName, '.mat'];

        if isfile(infoPath)
            load(infoPath, 'MouseInfoTable');

            % Check if exclusion criteria fields exist and if criteria are met
            if isfield(table2struct(MouseInfoTable), 'exclCrit1_met') && ...
                    isfield(table2struct(MouseInfoTable), 'exclCrit2_met')

                if MouseInfoTable.exclCrit1_met || MouseInfoTable.exclCrit2_met
                    shouldExcludeThisCondition = true;
                    disp(['Mouse ', currMouse, ' excluded for condition ', condition, ' based on exclusion criteria']);
                end
            end
        end

        % Only extract parameters if this mouse-condition combination should not be excluded
        if ~shouldExcludeThisCondition
            loadName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], condition, iRep, nReps, []);
            fitPath = [char(optionsFile.paths.cohort(cohortNo).results), 'mouse', char(currMouse), '_', ...
                loadName, '_', optionsFile.dataFiles.rawFitFile{iModel}, '.mat'];

            if isfile(fitPath)
                load(fitPath, 'est');

                % Check if est.traj.psi exists
                if isfield(est.traj, 'psi')
                    % Calculate mean psi for each phase
                    for iPhase = 1:numPhases
                        colName = ['psi_', condition, '_', phaseNames{iPhase}];
                        phaseTrials = phaseRanges{iPhase};

                        % Make sure the psi data has enough trials
                        if size(est.traj.psi, 1) >= max(phaseTrials)
                            % Calculate mean precision weight for this phase
                            % Using column 2 for level 2 precision weights
                            RQ3_3_dataTable.(colName)(iMouse) = mean(est.traj.psi(phaseTrials, 2), 'omitnan');
                        else
                            warning('Not enough trials for mouse %s in condition %s', currMouse, condition);
                            RQ3_3_dataTable.(colName)(iMouse) = NaN;
                        end
                    end
                else
                    warning('est.traj.psi not found for mouse %s in condition %s', currMouse, condition);
                    % Set all phases to NaN for this condition if psi is missing
                    for iPhase = 1:numPhases
                        colName = ['psi_', condition, '_', phaseNames{iPhase}];
                        RQ3_3_dataTable.(colName)(iMouse) = NaN;
                    end
                end
            else
                % If fit file doesn't exist, set all phases to NaN for this condition
                for iPhase = 1:numPhases
                    colName = ['psi_', condition, '_', phaseNames{iPhase}];
                    RQ3_3_dataTable.(colName)(iMouse) = NaN;
                end
            end
        else
            % Set all phases to NaN for this excluded condition
            for iPhase = 1:numPhases
                colName = ['psi_', condition, '_', phaseNames{iPhase}];
                RQ3_3_dataTable.(colName)(iMouse) = NaN;
            end
        end
    end
end

% Only remove rows where all psi values are NaN across ALL conditions
% (i.e., mice that have no valid data for any condition)
allNanRows = true(height(RQ3_3_dataTable), 1);

for iCond = 1:length(optionsFile.cohort(cohortNo).conditions)
    condition = optionsFile.cohort(cohortNo).conditions{iCond};
    conditionAllNaN = true(height(RQ3_3_dataTable), 1);

    for iPhase = 1:numPhases
        colName = ['psi_', condition, '_', phaseNames{iPhase}];
        conditionAllNaN = conditionAllNaN & isnan(RQ3_3_dataTable.(colName));
    end

    % If any condition has valid data, don't mark row for removal
    allNanRows = allNanRows & conditionAllNaN;
end

if any(allNanRows)
    fprintf('Removing %d mice with no valid precision weight values across all conditions.\n', sum(allNanRows));
    RQ3_3_dataTable(allNanRows, :) = [];
end

fprintf('Final table contains %d mice.\n', height(RQ3_3_dataTable));

% Save table as both .mat and .csv
savePath = [optionsFile.paths.cohort(cohortNo).groupLevel, optionsFile.cohort(cohortNo).taskPrefix, ...
    optionsFile.cohort(cohortNo).name, '_RQ3_3_dataTable'];

save([savePath, '.mat'], 'RQ3_3_dataTable');
writetable(RQ3_3_dataTable, [savePath, '.csv']);

disp(['Table saved to: ', savePath, '.csv']);

%% CREATE IMPROVED LINE PLOT WITH BETTER VISUAL SEPARATION
plotSaveDir = [optionsFile.paths.cohort(cohortNo).groupLevel, 'plots', filesep];
if ~exist(plotSaveDir, 'dir'); mkdir(plotSaveDir); end

% Define color scheme
colors = struct();
colors.saline = [0.5 0.5 0.5];           % Grey for saline
colors.mg5 = [0.929 0.490 0.192];        % Burnt orange for 5mg
colors.mg10 = [0.78 0.4 0.15];           % Dark burnt orange for 10mg

% Define phase information
phaseNames = {'stable1', 'volatile1', 'stable2', 'volatile2', 'stable3', 'volatile3', 'stable4'};
phaseLabels = {'Stable1', 'Volatile1', 'Stable2', 'Volatile2', 'Stable3', 'Volatile3', 'Stable4'};
phaseTypes = [1, 0, 1, 0, 1, 0, 1]; % 1 = stable, 0 = volatile

% Calculate means and standard errors
conditions = {'saline', '5mg', '10mg'};
nPhases = length(phaseNames);
nConditions = length(conditions);

meanPsi = zeros(nConditions, nPhases);
sePsi = zeros(nConditions, nPhases);

for iCond = 1:nConditions
    condition = conditions{iCond};
    for iPhase = 1:nPhases
        colName = ['psi_', condition, '_', phaseNames{iPhase}];
        data = RQ3_3_dataTable.(colName);
        validData = data(~isnan(data));

        if ~isempty(validData)
            meanPsi(iCond, iPhase) = mean(validData);
            sePsi(iCond, iPhase) = std(validData) / sqrt(length(validData));
        else
            meanPsi(iCond, iPhase) = NaN;
            sePsi(iCond, iPhase) = NaN;
        end
    end
end

% Create figure with horizontal offset approach
figure('Position', [100 100 1000 600], 'Color', 'white');
hold on;

% Add background shading for stable vs volatile phases
yLims = [min(meanPsi(:) - sePsi(:)) * 1.2, max(meanPsi(:) + sePsi(:)) * 1.2];
for iPhase = 1:nPhases
    if phaseTypes(iPhase) == 1 % Stable phase
        fill([iPhase-0.45, iPhase+0.45, iPhase+0.45, iPhase-0.45], ...
            [yLims(1), yLims(1), yLims(2), yLims(2)], ...
            [0.95 0.95 1.0], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
    end
end

% Use horizontal offset to separate the groups
offsets = [-0.15, 0, 0.15]; % Left, center, right for each condition
lineWidth = 3;
markerSize = 10;
capSize = 8; % Error bar cap size

% Plot each condition with horizontal offset
xPositions = cell(nConditions, 1);
handles = zeros(nConditions, 1);

for iCond = 1:nConditions
    xPos = (1:nPhases) + offsets(iCond);
    xPositions{iCond} = xPos;

    % Choose colors and markers
    switch iCond
        case 1 % Saline
            color = colors.saline;
            marker = 'o';
        case 2 % 5mg
            color = colors.mg5;
            marker = 's';
        case 3 % 10mg
            color = colors.mg10;
            marker = '^';
    end

    % Plot line with error bars
    handles(iCond) = errorbar(xPos, meanPsi(iCond,:), sePsi(iCond,:), ...
        'Color', color, 'LineWidth', lineWidth, 'MarkerSize', markerSize, ...
        'MarkerFaceColor', color, 'MarkerEdgeColor', 'white', ...
        'Marker', marker, 'LineStyle', '-', 'CapSize', capSize);
end

% Format plot
set(gca, 'XTick', 1:nPhases, 'XTickLabel', phaseLabels, 'FontName', 'Arial', 'FontSize', 18);
xlabel('Task Phase', 'FontSize', 20, 'FontName', 'Arial');
ylabel('$\hat{\pi}$ (Precision weights)', 'FontSize', 20, 'FontName', 'Arial', 'Interpreter', 'latex');
title('HGF 2-Level: Precision Weights Across Task Phases', 'FontSize', 22, 'FontName', 'Arial');

% Set axis limits
xlim([0.4, nPhases + 0.6]);
ylim([0.15, 0.45]); % Fixed limits from 0.15 to 0.45
grid on;
set(gca, 'GridAlpha', 0.3,'GridLineStyle', ':');

% Add legend
lgd = legend(handles, {'Saline', '5mg', '10mg'}, ...
    'FontSize', 16, 'FontName', 'Arial', 'Location', 'northeast', ...
    'Box', 'off', 'EdgeColor', [0.7 0.7 0.7]);

hold off;

% Save plot
savePath = fullfile([optionsFile.paths.cohort(cohortNo).groupLevel, 'RQ3_3_HGF2PsiTaskPhasesLinePlot']);
saveas(gcf, [savePath, '.fig']);
print(gcf, [savePath, '.png'], '-dpng', '-r300');
disp(['HGF 2-Level precision weights task phases line plot saved to: ', savePath]);

%% BAR PLOT WITH ERROR BARS FOR CLEARER COMPARISON

figure('Position', [100 100 1200 600], 'Color', 'white');

% Prepare data for bar plot
barData = meanPsi'; % Transpose so phases are rows, conditions are columns
barErrors = sePsi';

% Create grouped bar plot
b = bar(barData, 'grouped');
hold on;

% Set colours for bars
b(1).FaceColor = colors.saline;
b(2).FaceColor = colors.mg5;
b(3).FaceColor = colors.mg10;

% Add error bars
ngroups = size(barData, 1);
nbars = size(barData, 2);
groupwidth = min(0.8, nbars/(nbars + 1.5));

for i = 1:nbars
    x = (1:ngroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*nbars);
    errorbar(x, barData(:,i), barErrors(:,i), 'k', 'linestyle', 'none', 'linewidth', 1.5);
end

% Format bar plot
set(gca, 'XTickLabel', phaseLabels, 'FontName', 'Arial', 'FontSize', 18);
xlabel('Task Phase', 'FontSize', 20,'FontName', 'Arial');
ylabel('$\hat{\pi}$ (Precision weights)', 'FontSize', 20, 'Interpreter', 'latex');
ylim([0.15, 0.45]);
title('HGF 2-Level: Precision Weights Across Task Phases', 'FontSize', 24);
legend({'Saline', '5mg', '10mg'}, 'FontSize', 16, 'Location', 'northeast','Box', 'off');
grid on;
set(gca, 'GridAlpha', 0.3,'GridLineStyle', ':');

hold off;

% Save plot
savePath = fullfile([optionsFile.paths.cohort(cohortNo).groupLevel, 'RQ3_3_HGF2PsiTaskPhasesBarPlot']);
saveas(gcf, [savePath, '.fig']);
print(gcf, [savePath, '.png'], '-dpng', '-r300');
disp(['HGF 2-Level precision weights task phases bar plot saved to: ', savePath]);

end