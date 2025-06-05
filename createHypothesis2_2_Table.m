function createHypothesis2_2_Table

% createHypothesis2_2_Table - Extract learning and volatility parameters across task repetitions
%
% This function extracts computational model parameters from fitted models across three task
% repetitions for each mouse. It collects volatility parameters from the
% hierarchical Gaussian filter models (2-level (omega2) and 3-level (omega2, omega3))
% and learning rate (alpha) from the Rescorla-Wagner model. The resulting data table contains
% one row per mouse with parameters from all models and repetitions, allowing for
% statistical analysis of how these parameters change with repeated task exposure.
% Exclusion criteria are applied per-repetition rather than per-mouse.
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
nReps = 3;
cohortNo = 2;
subCohort = [];
currTask = optionsFile.cohort(cohortNo).testTask(1).name;
[mouseIDs, nSize] = getSampleVars(optionsFile, cohortNo, subCohort);

%% EXCLUDE MICE that have NO data files at all
% Only exclude mice that have no data files for any repetition
noDataArray = zeros(1, nSize);

for iMouse = 1:nSize
    currMouse = mouseIDs{iMouse};
    % Check if data exists for any repetition
    hasData = false;
    for iRep = 1:nReps
        loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], [], iRep, nReps, 'info');
        if isfile([char(optionsFile.paths.cohort(cohortNo).data), 'mouse', char(currMouse), '_', loadInfoName, '.mat'])
            hasData = true;
            break;
        end
    end
    if ~hasData
        disp(['Data for mouse ', currMouse, ' not available in any repetition']);
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

% Create table with one row per mouse and columns for each parameter/repetition
RQ2_2_dataTable = table('Size', [nSize, 2+12], ...  % 2 basic columns + 12 parameter columns (4 parameters x 3 reps)
    'VariableTypes', {'string', 'string', ...
    'double', 'double', 'double', ... % HGF2 omega2
    'double', 'double', 'double', ... % HGF3 omega2
    'double', 'double', 'double', ... % HGF3 omega3
    'double', 'double', 'double'}, ... % RW alpha
    'VariableNames', {'ID', 'sex', ...
    'HGF2_omega2_rep1', 'HGF2_omega2_rep2', 'HGF2_omega2_rep3', ...
    'HGF3_omega2_rep1', 'HGF3_omega2_rep2', 'HGF3_omega2_rep3', ...
    'HGF3_omega3_rep1', 'HGF3_omega3_rep2', 'HGF3_omega3_rep3', ...
    'RW_alpha_rep1', 'RW_alpha_rep2', 'RW_alpha_rep3'});

% Populate the table with one row per mouse
for iMouse = 1:nSize
    currMouse = mouseIDs{iMouse};

    % Load basic info from first available repetition (for ID and sex)
    for iRep = 1:nReps
        loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], [], iRep, nReps, 'info');
        infoPath = [char(optionsFile.paths.cohort(cohortNo).data), 'mouse', char(currMouse), '_', loadInfoName, '.mat'];

        if isfile(infoPath)
            load(infoPath, 'MouseInfoTable');
            RQ2_2_dataTable.ID(iMouse) = currMouse;
            RQ2_2_dataTable.sex(iMouse) = MouseInfoTable.Sex;
            break;
        end
    end

    % If no info file found, still set ID
    if isempty(RQ2_2_dataTable.ID(iMouse)) || ismissing(RQ2_2_dataTable.ID(iMouse))
        RQ2_2_dataTable.ID(iMouse) = currMouse;
        RQ2_2_dataTable.sex(iMouse) = "";
    end

    % For each repetition, check exclusion criteria and extract parameters
    for iRep = 1:nReps
        % Check exclusion criteria for this specific repetition
        shouldExcludeThisRep = false;

        % Load info file to check exclusion criteria
        loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], [], iRep, nReps, 'info');
        infoPath = [char(optionsFile.paths.cohort(cohortNo).data), 'mouse', char(currMouse), '_', loadInfoName, '.mat'];

        if isfile(infoPath)
            load(infoPath, 'MouseInfoTable');

            % Check if exclusion criteria fields exist and if criteria are met
            if isfield(table2struct(MouseInfoTable), 'exclCrit1_met') && ...
                    isfield(table2struct(MouseInfoTable), 'exclCrit2_met')

                if MouseInfoTable.exclCrit1_met || MouseInfoTable.exclCrit2_met
                    shouldExcludeThisRep = true;
                    disp(['Mouse ', currMouse, ' excluded for repetition ', num2str(iRep), ' based on exclusion criteria']);
                end
            end
        end

        % Only extract parameters if this mouse-repetition combination should not be excluded
        if ~shouldExcludeThisRep
            % Get file name for this repetition
            loadName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], [], iRep, nReps, []);

            % Extract HGF 2-level omega2
            hgf2_col = ['HGF2_omega2_rep', num2str(iRep)];
            fitPath = [char(optionsFile.paths.cohort(cohortNo).results), 'mouse', char(currMouse), '_', ...
                loadName, '_', optionsFile.dataFiles.rawFitFile{model_HGF2}, '.mat'];

            if isfile(fitPath)
                load(fitPath, 'est');
                RQ2_2_dataTable.(hgf2_col)(iMouse) = est.p_prc.om(2);
            else
                RQ2_2_dataTable.(hgf2_col)(iMouse) = NaN;
            end

            % Extract HGF 3-level omega2 and omega3
            hgf3_omega2_col = ['HGF3_omega2_rep', num2str(iRep)];
            hgf3_omega3_col = ['HGF3_omega3_rep', num2str(iRep)];
            fitPath = [char(optionsFile.paths.cohort(cohortNo).results), 'mouse', char(currMouse), '_', ...
                loadName, '_', optionsFile.dataFiles.rawFitFile{model_HGF3}, '.mat'];

            if isfile(fitPath)
                load(fitPath, 'est');
                RQ2_2_dataTable.(hgf3_omega2_col)(iMouse) = est.p_prc.om(2);
                RQ2_2_dataTable.(hgf3_omega3_col)(iMouse) = est.p_prc.om(3);
            else
                RQ2_2_dataTable.(hgf3_omega2_col)(iMouse) = NaN;
                RQ2_2_dataTable.(hgf3_omega3_col)(iMouse) = NaN;
            end

            % Extract Rescorla-Wagner alpha parameter
            rw_col = ['RW_alpha_rep', num2str(iRep)];
            fitPath = [char(optionsFile.paths.cohort(cohortNo).results), 'mouse', char(currMouse), '_', ...
                loadName, '_', optionsFile.dataFiles.rawFitFile{model_RW}, '.mat'];

            if isfile(fitPath)
                load(fitPath, 'est');
                if isfield(est.p_prc, 'al')
                    RQ2_2_dataTable.(rw_col)(iMouse) = est.p_prc.al;
                else
                    RQ2_2_dataTable.(rw_col)(iMouse) = NaN;
                end
            else
                RQ2_2_dataTable.(rw_col)(iMouse) = NaN;
            end
        else
            % Set all parameters to NaN for this excluded repetition
            hgf2_col = ['HGF2_omega2_rep', num2str(iRep)];
            hgf3_omega2_col = ['HGF3_omega2_rep', num2str(iRep)];
            hgf3_omega3_col = ['HGF3_omega3_rep', num2str(iRep)];
            rw_col = ['RW_alpha_rep', num2str(iRep)];

            RQ2_2_dataTable.(hgf2_col)(iMouse) = NaN;
            RQ2_2_dataTable.(hgf3_omega2_col)(iMouse) = NaN;
            RQ2_2_dataTable.(hgf3_omega3_col)(iMouse) = NaN;
            RQ2_2_dataTable.(rw_col)(iMouse) = NaN;
        end
    end
end

% Only remove rows where ALL parameters across ALL repetitions are NaN
% (i.e., mice that have no valid data for any repetition)
allNanRows = true(height(RQ2_2_dataTable), 1);

for iRep = 1:nReps
    hgf2_col = ['HGF2_omega2_rep', num2str(iRep)];
    hgf3_omega2_col = ['HGF3_omega2_rep', num2str(iRep)];
    hgf3_omega3_col = ['HGF3_omega3_rep', num2str(iRep)];
    rw_col = ['RW_alpha_rep', num2str(iRep)];

    % Check if all parameters are NaN for this repetition
    repAllNaN = isnan(RQ2_2_dataTable.(hgf2_col)) & ...
        isnan(RQ2_2_dataTable.(hgf3_omega2_col)) & ...
        isnan(RQ2_2_dataTable.(hgf3_omega3_col)) & ...
        isnan(RQ2_2_dataTable.(rw_col));

    % If any repetition has valid data, don't mark row for removal
    allNanRows = allNanRows & repAllNaN;
end

if any(allNanRows)
    fprintf('Removing %d mice with no valid parameter values across all repetitions.\n', sum(allNanRows));
    RQ2_2_dataTable(allNanRows, :) = [];
end

fprintf('Final table contains %d mice.\n', height(RQ2_2_dataTable));

% Save table as both .mat and .csv
savePath = [optionsFile.paths.cohort(cohortNo).groupLevel, optionsFile.cohort(cohortNo).taskPrefix, ...
    optionsFile.cohort(cohortNo).name, '_RQ2_2_dataTable'];

save([savePath, '.mat'], 'RQ2_2_dataTable');
writetable(RQ2_2_dataTable, [savePath, '.csv']);

disp(['Table saved to: ', savePath, '.csv']);

%% CREATE RAINCLOUD PLOT OF RW MODEL LEARNING RATE PARAMETER (ALPHA) ACROSS TASK REPETITIONS
plotSaveDir = [optionsFile.paths.cohort(cohortNo).groupLevel, 'plots', filesep];
if ~exist(plotSaveDir, 'dir'); mkdir(plotSaveDir); end

% Define colour scheme based on BMS function green [0.439 0.678 0.278]
% Progressive shades from light to dark while maintaining good contrast
col = struct();

% Rep 1: Lightest - based on BMS green but lightened
col.rep1 = struct('male', [0.5 0.75 0.35], 'female', [0.65 0.85 0.5], 'group', [0.58 0.8 0.43], 'edge', [0.35 0.6 0.25]);

% Rep 2: Medium - close to original BMS green
col.rep2 = struct('male', [0.44 0.68 0.28], 'female', [0.55 0.78 0.4], 'group', [0.5 0.73 0.34], 'edge', [0.3 0.5 0.2]);

% Rep 3: Darkest - darker version of BMS green
col.rep3 = struct('male', [0.32 0.55 0.18], 'female', [0.42 0.65 0.28], 'group', [0.37 0.6 0.23], 'edge', [0.2 0.4 0.1]);

% Prepare data by task repetition
rep1Data = RQ2_2_dataTable.RW_alpha_rep1;
rep1Sex = RQ2_2_dataTable.sex;
validRep1 = ~isnan(rep1Data);
rep1Data = rep1Data(validRep1);
rep1Sex = rep1Sex(validRep1);

rep2Data = RQ2_2_dataTable.RW_alpha_rep2;
rep2Sex = RQ2_2_dataTable.sex;
validRep2 = ~isnan(rep2Data);
rep2Data = rep2Data(validRep2);
rep2Sex = rep2Sex(validRep2);

rep3Data = RQ2_2_dataTable.RW_alpha_rep3;
rep3Sex = RQ2_2_dataTable.sex;
validRep3 = ~isnan(rep3Data);
rep3Data = rep3Data(validRep3);
rep3Sex = rep3Sex(validRep3);

% Create main figure with specified size and white background
figure('Position', [100 100 900 600], 'Color', 'white'); % Wider figure for 3 groups
hold on;

% Plot raincloud for each repetition at different x-positions
if ~isempty(rep1Data)
    plotRaincloudWithSex(rep1Data, rep1Sex, 1.0, col.rep1);    % Rep 1 at x = 1.0
end
if ~isempty(rep2Data)
    plotRaincloudWithSex(rep2Data, rep2Sex, 2.0, col.rep2);    % Rep 2 at x = 2.0
end
if ~isempty(rep3Data)
    plotRaincloudWithSex(rep3Data, rep3Sex, 3.0, col.rep3);    % Rep 3 at x = 3.0
end

% Format plot appearance
set(gca, 'XTick', [1.0, 2.0, 3.0], 'XTickLabel', {'Repetition 1', 'Repetition 2', 'Repetition 3'}, 'FontName', 'Arial', 'FontSize', 20);
ylabel('\alpha (Learning rate parameter)', 'FontSize', 20, 'FontName', 'Arial', 'Interpreter', 'tex');
title('RW Model: Learning Rate Across Task Repetitions', 'FontSize', 24, 'FontName', 'Arial');
set(get(gca,'Title'), 'Position', get(get(gca,'Title'), 'Position') + [0 0.02 0]); % Move title up
grid on; set(gca, 'GridAlpha', 0.3,'GridLineStyle', ':');
xlim([0.4, 3.6]); % Set x-axis limits to frame the plot nicely

%% Markers for all 3 reps with both sexes (legend may be a little too big)
% % Create custom legend with invisible lines to show marker styles
% % Square markers for males, triangle markers for females
% p1 = line(NaN, NaN, 'Marker', 's', 'MarkerSize', 10, 'MarkerFaceColor', col.rep1.male, 'MarkerEdgeColor', col.rep1.edge, 'LineStyle', 'none', 'LineWidth', 0.5);
% p2 = line(NaN, NaN, 'Marker', '^', 'MarkerSize', 10, 'MarkerFaceColor', col.rep1.female, 'MarkerEdgeColor', col.rep1.edge, 'LineStyle', 'none', 'LineWidth', 0.5);
% p3 = line(NaN, NaN, 'Marker', 's', 'MarkerSize', 10, 'MarkerFaceColor', col.rep2.male, 'MarkerEdgeColor', col.rep2.edge, 'LineStyle', 'none', 'LineWidth', 0.5);
% p4 = line(NaN, NaN, 'Marker', '^', 'MarkerSize', 10, 'MarkerFaceColor', col.rep2.female, 'MarkerEdgeColor', col.rep2.edge, 'LineStyle', 'none', 'LineWidth', 0.5);
% p5 = line(NaN, NaN, 'Marker', 's', 'MarkerSize', 10, 'MarkerFaceColor', col.rep3.male, 'MarkerEdgeColor', col.rep3.edge, 'LineStyle', 'none', 'LineWidth', 0.5);
% p6 = line(NaN, NaN, 'Marker', '^', 'MarkerSize', 10, 'MarkerFaceColor', col.rep3.female, 'MarkerEdgeColor', col.rep3.edge, 'LineStyle', 'none', 'LineWidth', 0.5);
% lgd = legend([p1, p2, p3, p4, p5, p6], {'Rep 1 Male', 'Rep 1 Female', 'Rep 2 Male', 'Rep 2 Female', 'Rep 3 Male', 'Rep 3 Female'}, ...
%     'FontSize', 13, 'FontName', 'Arial', 'EdgeColor', 'white');
% lgd.Position = [0.73 0.65 0.15 0.25]; % Position legend in top-right

%% Markers for sexes only (looks cleaner while still being informative)
% Legend showing marker shapes for sex coding
p1 = line(NaN, NaN, 'Marker', 's', 'MarkerSize', 10, 'MarkerFaceColor', col.rep2.male, 'MarkerEdgeColor', 'black', 'LineStyle', 'none', 'LineWidth', 0.5);
p2 = line(NaN, NaN, 'Marker', '^', 'MarkerSize', 10, 'MarkerFaceColor', col.rep2.female, 'MarkerEdgeColor', 'black', 'LineStyle', 'none', 'LineWidth', 0.5);

lgd = legend([p1, p2], {'Male', 'Female'}, ...
    'FontSize', 13, 'FontName', 'Arial', 'EdgeColor', 'white');
lgd.Position = [0.82 0.8 0.08 0.1];

hold off;

% Save plot in both .fig and .png formats
savePath = fullfile([optionsFile.paths.cohort(cohortNo).groupLevel, 'RQ2_2_RWAlphaTaskRepetitionsRaincloudPlot']);
saveas(gcf, [savePath, '.fig']);
print(gcf, [savePath, '.png'], '-dpng', '-r300');
disp(['RW Alpha raincloud plot saved to: ', savePath]);

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
% 4. Colours: Modify the col.rep1, col.rep2, col.rep3 struct values
% 5. X-positions: Change 1.0, 2.0, 3.0 values in main plotting calls
% 6. Box width: Modify the 0.1 value in rectangle width (3rd parameter)
% 7. Point positioning: Adjust the '-0.2' offset in scatter x-position
end