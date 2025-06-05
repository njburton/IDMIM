function createHypothesis3_2_Table

% createHypothesis3_2_Table - Extract volatility parameters across treatment conditions
%
% This function extracts computational model parameters from fitted models across three treatment
% conditions (saline, 5mg, 10mg) for each mouse. It collects volatility parameters from the
% hierarchical Gaussian filter models (2-level (omega2) and 3-level (omega2, omega3))
% and learning rate (alpha) from the Rescorla-Wagner model. The resulting data table contains
% one row per mouse with parameters from all models and conditions, allowing for
% statistical analysis of how these parameters are affected by different drug treatments.
% Exclusion criteria are applied per-condition rather than per-mouse.
% The output is saved as both .mat and .csv files.
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

% Prespecify models to extract parameters from
model_HGF3 = 1;  % HGF 3-level model
model_HGF2 = 2;  % HGF 2-level model
model_RW = 3;    % Rescorla-Wagner model

% Prespecify variables needed
iTask = 1;
iRep = 1;
nReps = 1;
cohortNo = 3;
subCohort = [];
currTask = optionsFile.cohort(cohortNo).testTask(1).name;
[mouseIDs, nSize] = getSampleVars(optionsFile, cohortNo, subCohort);

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

% Create table with one row per mouse and columns for each parameter/condition
RQ3_2_dataTable = table('Size', [nSize, 2+12], ...  % 2 basic columns + 12 parameter columns (4 parameters x 3 conditions)
    'VariableTypes', {'string', 'string', ...
    'double', 'double', 'double', ... % HGF2 omega2
    'double', 'double', 'double', ... % HGF3 omega2
    'double', 'double', 'double', ... % HGF3 omega3
    'double', 'double', 'double'}, ... % RW alpha
    'VariableNames', {'ID', 'sex', ...
    'HGF2_omega2_saline', 'HGF2_omega2_5mg', 'HGF2_omega2_10mg', ...
    'HGF3_omega2_saline', 'HGF3_omega2_5mg', 'HGF3_omega2_10mg', ...
    'HGF3_omega3_saline', 'HGF3_omega3_5mg', 'HGF3_omega3_10mg', ...
    'RW_alpha_saline', 'RW_alpha_5mg', 'RW_alpha_10mg'});

% Populate the table
for iMouse = 1:nSize
    currMouse = mouseIDs{iMouse};

    % Set ID
    RQ3_2_dataTable.ID(iMouse) = currMouse;

    % Get basic info (sex) from the first available condition file
    for iCond = 1:length(optionsFile.cohort(cohortNo).conditions)
        loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], optionsFile.cohort(cohortNo).conditions{iCond}, iRep, nReps, 'info');
        infoPath = [char(optionsFile.paths.cohort(cohortNo).data), 'mouse', char(currMouse), '_', loadInfoName, '.mat'];

        if isfile(infoPath)
            load(infoPath, 'MouseInfoTable');
            RQ3_2_dataTable.sex(iMouse) = MouseInfoTable.Sex;
            break;
        end
    end

    % Get parameters for each condition - using actual conditions from optionsFile
    for iCond = 1:length(optionsFile.cohort(cohortNo).conditions)
        currCondition = optionsFile.cohort(cohortNo).conditions{iCond};

        % Check exclusion criteria for this specific condition
        shouldExcludeThisCondition = false;

        % Load info file to check exclusion criteria
        loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], currCondition, iRep, nReps, 'info');
        infoPath = [char(optionsFile.paths.cohort(cohortNo).data), 'mouse', char(currMouse), '_', loadInfoName, '.mat'];

        if isfile(infoPath)
            load(infoPath, 'MouseInfoTable');

            % Check if exclusion criteria fields exist and if criteria are met
            if isfield(table2struct(MouseInfoTable), 'exclCrit1_met') && ...
                    isfield(table2struct(MouseInfoTable), 'exclCrit2_met')

                if MouseInfoTable.exclCrit1_met || MouseInfoTable.exclCrit2_met
                    shouldExcludeThisCondition = true;
                    disp(['Mouse ', currMouse, ' excluded for condition ', currCondition, ' based on exclusion criteria']);
                end
            end
        end

        % Only extract parameters if this mouse-condition combination should not be excluded
        if ~shouldExcludeThisCondition
            % Get file name base for this condition
            loadName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], currCondition, iRep, nReps, []);

            % Extract HGF 2-level omega2
            hgf2_col = ['HGF2_omega2_', currCondition];
            fitPath = [char(optionsFile.paths.cohort(cohortNo).results), 'mouse', char(currMouse), '_', ...
                loadName, '_', optionsFile.dataFiles.rawFitFile{model_HGF2}, '.mat'];

            if isfile(fitPath)
                load(fitPath, 'est');
                RQ3_2_dataTable.(hgf2_col)(iMouse) = est.p_prc.om(2);
            else
                RQ3_2_dataTable.(hgf2_col)(iMouse) = NaN;
            end

            % Extract HGF 3-level omega2 and omega3
            hgf3_omega2_col = ['HGF3_omega2_', currCondition];
            hgf3_omega3_col = ['HGF3_omega3_', currCondition];
            fitPath = [char(optionsFile.paths.cohort(cohortNo).results), 'mouse', char(currMouse), '_', ...
                loadName, '_', optionsFile.dataFiles.rawFitFile{model_HGF3}, '.mat'];

            if isfile(fitPath)
                load(fitPath, 'est');
                RQ3_2_dataTable.(hgf3_omega2_col)(iMouse) = est.p_prc.om(2);
                RQ3_2_dataTable.(hgf3_omega3_col)(iMouse) = est.p_prc.om(3);
            else
                RQ3_2_dataTable.(hgf3_omega2_col)(iMouse) = NaN;
                RQ3_2_dataTable.(hgf3_omega3_col)(iMouse) = NaN;
            end

            % Extract Rescorla-Wagner alpha parameter
            rw_col = ['RW_alpha_', currCondition];
            fitPath = [char(optionsFile.paths.cohort(cohortNo).results), 'mouse', char(currMouse), '_', ...
                loadName, '_', optionsFile.dataFiles.rawFitFile{model_RW}, '.mat'];

            if isfile(fitPath)
                load(fitPath, 'est');
                if isfield(est.p_prc, 'al')
                    RQ3_2_dataTable.(rw_col)(iMouse) = est.p_prc.al;
                else
                    RQ3_2_dataTable.(rw_col)(iMouse) = NaN;
                end
            else
                RQ3_2_dataTable.(rw_col)(iMouse) = NaN;
            end
        else
            % Set all parameters to NaN for this excluded condition
            hgf2_col = ['HGF2_omega2_', currCondition];
            hgf3_omega2_col = ['HGF3_omega2_', currCondition];
            hgf3_omega3_col = ['HGF3_omega3_', currCondition];
            rw_col = ['RW_alpha_', currCondition];

            RQ3_2_dataTable.(hgf2_col)(iMouse) = NaN;
            RQ3_2_dataTable.(hgf3_omega2_col)(iMouse) = NaN;
            RQ3_2_dataTable.(hgf3_omega3_col)(iMouse) = NaN;
            RQ3_2_dataTable.(rw_col)(iMouse) = NaN;
        end
    end
end

% Only remove rows where ALL parameters across ALL conditions are NaN
% (i.e., mice that have no valid data for any condition)
allNanRows = true(height(RQ3_2_dataTable), 1);

for iCond = 1:length(optionsFile.cohort(cohortNo).conditions)
    currCondition = optionsFile.cohort(cohortNo).conditions{iCond};
    hgf2_col = ['HGF2_omega2_', currCondition];
    hgf3_omega2_col = ['HGF3_omega2_', currCondition];
    hgf3_omega3_col = ['HGF3_omega3_', currCondition];
    rw_col = ['RW_alpha_', currCondition];

    % Check if all parameters are NaN for this condition
    conditionAllNaN = isnan(RQ3_2_dataTable.(hgf2_col)) & ...
        isnan(RQ3_2_dataTable.(hgf3_omega2_col)) & ...
        isnan(RQ3_2_dataTable.(hgf3_omega3_col)) & ...
        isnan(RQ3_2_dataTable.(rw_col));

    % If any condition has valid data, don't mark row for removal
    allNanRows = allNanRows & conditionAllNaN;
end

if any(allNanRows)
    fprintf('Removing %d mice with no valid parameter values across all conditions.\n', sum(allNanRows));
    RQ3_2_dataTable(allNanRows, :) = [];
end

fprintf('Final table contains %d mice.\n', height(RQ3_2_dataTable));

% Save table as both .mat and .csv
savePath = [optionsFile.paths.cohort(cohortNo).groupLevel, optionsFile.cohort(cohortNo).taskPrefix, ...
    optionsFile.cohort(cohortNo).name, '_RQ3_2_dataTable'];

save([savePath, '.mat'], 'RQ3_2_dataTable');
writetable(RQ3_2_dataTable, [savePath, '.csv']);

disp(['Table saved to: ', savePath, '.csv']);

%% CREATE RAINCLOUD PLOT OF RW MODEL LEARNING RATE PARAMETER (ALPHA) ACROSS SEROTONIN TREATMENT CONDITIONS
plotSaveDir = [optionsFile.paths.cohort(cohortNo).groupLevel, 'plots', filesep];
if ~exist(plotSaveDir, 'dir'); mkdir(plotSaveDir); end

% Define colour scheme for different serotonin treatment conditions and sexes
col = struct();

% Saline group: grey (control/baseline condition on the left)
col.saline = struct('male', [0.3 0.3 0.3], 'female', [0.7 0.7 0.7], 'group', [0.5 0.5 0.5], 'edge', 'black');

% 5mg group: Medium green - matching Rep 2 from createHypothesis2_2Table
col.mg5 = struct('male', [0.44 0.68 0.28], 'female', [0.55 0.78 0.4], 'group', [0.5 0.73 0.34], 'edge', [0.3 0.5 0.2]);

% 10mg group: Dark green - matching Rep 3 from createHypothesis2_2Table
col.mg10 = struct('male', [0.32 0.55 0.18], 'female', [0.42 0.65 0.28], 'group', [0.37 0.6 0.23], 'edge', [0.2 0.4 0.1]);

% Prepare data by treatment condition
salineData = RQ3_2_dataTable.RW_alpha_saline;
salineSex = RQ3_2_dataTable.sex;
validSaline = ~isnan(salineData);
salineData = salineData(validSaline);
salineSex = salineSex(validSaline);

mg5Data = RQ3_2_dataTable.RW_alpha_5mg;
mg5Sex = RQ3_2_dataTable.sex;
validMg5 = ~isnan(mg5Data);
mg5Data = mg5Data(validMg5);
mg5Sex = mg5Sex(validMg5);

mg10Data = RQ3_2_dataTable.RW_alpha_10mg;
mg10Sex = RQ3_2_dataTable.sex;
validMg10 = ~isnan(mg10Data);
mg10Data = mg10Data(validMg10);
mg10Sex = mg10Sex(validMg10);

% Create main figure with specified size and white background
figure('Position', [100 100 900 700], 'Color', 'white'); % Wider figure for 3 groups
hold on;

% Plot raincloud for each treatment condition at different x-positions (saline on left)
if ~isempty(salineData)
    plotRaincloudWithSex(salineData, salineSex, 1.0, col.saline);    % Saline at x = 1.0
end
if ~isempty(mg5Data)
    plotRaincloudWithSex(mg5Data, mg5Sex, 2.0, col.mg5);           % 5mg at x = 2.0
end
if ~isempty(mg10Data)
    plotRaincloudWithSex(mg10Data, mg10Sex, 3.0, col.mg10);        % 10mg at x = 3.0
end

% Format plot appearance
set(gca, 'XTick', [1.0, 2.0, 3.0], 'XTickLabel', {'Saline', '5mg', '10mg'}, 'FontName', 'Arial', 'FontSize', 20);
ylabel('\alpha (Learning rate parameter)', 'FontSize', 20, 'FontName', 'Arial', 'Interpreter', 'tex');
title('RW Model: Learning Rate Across Serotonin Conditions', 'FontSize', 24, 'FontName', 'Arial');
set(get(gca,'Title'), 'Position', get(get(gca,'Title'), 'Position') + [0 0.02 0]); % Move title up slightly
grid on; set(gca, 'GridAlpha', 0.3,'GridLineStyle', ':');
xlim([0.4, 3.6]); % Set x-axis limits to frame the plot nicely

% Simplified legend showing marker shapes for sex coding
p1 = line(NaN, NaN, 'Marker', 's', 'MarkerSize', 10, 'MarkerFaceColor', col.mg5.male, 'MarkerEdgeColor', 'black', 'LineStyle', 'none', 'LineWidth', 0.5);
p2 = line(NaN, NaN, 'Marker', '^', 'MarkerSize', 10, 'MarkerFaceColor', col.mg5.female, 'MarkerEdgeColor', 'black', 'LineStyle', 'none', 'LineWidth', 0.5);

lgd = legend([p1, p2], {'Male', 'Female'}, ...
    'FontSize', 13, 'FontName', 'Arial', 'EdgeColor', 'white');
lgd.Position = [0.82 0.8 0.08 0.1];

hold off;

% Save plot in both .fig and .png formats
savePath = fullfile([optionsFile.paths.cohort(cohortNo).groupLevel, 'RQ3_2_RWAlphaSerotoninTreatmentRaincloudPlot']);
saveas(gcf, [savePath, '.fig']);
print(gcf, [savePath, '.png'], '-dpng', '-r300');
disp(['RW Alpha serotonin treatment raincloud plot saved to: ', savePath]);

%% RAINCLOUD PLOTTING FUNCTION
% Creates a raincloud plot (violin + scatter + boxplot) for one group
% INPUTS:
%   data: vector of numerical values to plot
%   sexLabels: cell array of sex labels ('male'/'female') for each data point
%   xPos: x-axis position where this group should be plotted
%   colours: struct containing color specifications for this group
    function plotRaincloudWithSex(data, sexLabels, xPos, colours)
        if isempty(data); return; end

        %% 1. VIOLIN PLOT (Density Distribution)
        % Create kernel density estimate to show data distribution
        [f, xi] = ksdensity(data);                          % Get density function
        f = f / max(f) * 0.2;                              % Scale width to 0.2 units
        % Create filled violin shape extending rightward from xPos
        fill([xPos + f, xPos * ones(1, length(f))], [xi, fliplr(xi)], ...
            colours.group, 'FaceAlpha', 0.9, 'EdgeColor', 'none');

        %% 2. INDIVIDUAL DATA POINTS (Sex-Coded Scatter)
        % Add small random horizontal jitter to prevent overlapping points
        jitter = 0.05 * randn(length(data), 1);            % Random jitter values

        % Plot each data point with sex-specific color and shape
        for iSexMarker = 1:length(data)
            % Determine color and marker shape based on sex
            if strcmp(sexLabels{iSexMarker}, 'male')
                pointColour = colours.male;
                markerShape = 's';                          % Square for males
            else
                pointColour = colours.female;
                markerShape = '^';                          % Triangle for females
            end

            % Plot individual point with jitter, positioned left of violin
            h = scatter(xPos - 0.2 + jitter(iSexMarker), data(iSexMarker), ...
                110, pointColour, 'filled', markerShape); % Marker size = 110
            h.MarkerFaceAlpha = 0.9;                       % High opacity for visibility
            h.MarkerEdgeColor = colours.edge;              % Edge color
            h.LineWidth = 0.5;                             % Thin edge line
        end

        %% 3. BOX PLOT (Summary Statistics)
        % Calculate quartiles for box plot
        q = quantile(data, [0.25, 0.5, 0.75]);            % 25th, 50th, 75th percentiles

        % Choose box fill color based on group (lighter version of group color)
        boxFillColour = colours.group + 0.15;              % Lighten the group color
        boxFillColour(boxFillColour > 1) = 1;              % Ensure values don't exceed 1

        % Draw box (interquartile range)
        rectangle('Position', [xPos - 0.05, q(1), 0.1, q(3) - q(1)], ...
            'FaceColor', boxFillColour, 'EdgeColor', colours.group, 'LineWidth', 2);

        % Draw median line (thick horizontal line at 50th percentile)
        line([xPos - 0.05, xPos + 0.05], [q(2), q(2)], ...
            'Color', colours.group, 'LineWidth', 3);
    end

%% CUSTOMISATION NOTES:
% 1. Marker size: Change the value '110' in the scatter() call
% 2. Violin width: Modify the '0.2' scaling factor in the violin section
% 3. Jitter amount: Adjust the '0.05' multiplier for horizontal scatter
% 4. Colours: Modify the col.saline, col.mg5, col.mg10 struct values
% 5. X-positions: Change 1.0, 2.0, 3.0 values in main plotting calls
% 6. Box width: Modify the 0.1 value in rectangle width (3rd parameter)
% 7. Point positioning: Adjust the '-0.2' offset in scatter x-position
end