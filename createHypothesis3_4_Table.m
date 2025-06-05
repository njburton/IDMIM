function createHypothesis3_4_Table

% createHypothesis3_4_Table - Extract prior precision parameters across treatment conditions
%
% This function extracts prior precision parameters from fitted models across three treatment
% conditions (saline, 5mg, 10mg) for each mouse. It collects prior precision estimates for
% volatility parameters from the hierarchical Gaussian filter models (2-level HGF omega2
% prior precision, 3-level HGF omega2 prior precision, and 3-level HGF omega3 prior precision).
% The resulting data table contains one row per mouse with all prior precision parameters
% across conditions, allowing for statistical analysis of how drug treatment affects
% the precision of volatility estimates. Exclusion criteria are applied per-condition
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
model_HGF3 = 1;  % HGF 3-level model
model_HGF2 = 2;  % HGF 2-level model

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
RQ3_4_dataTable = table('Size', [nSize, 2+9], ...  % 2 basic columns + 9 parameter columns (3 parameters x 3 conditions)
    'VariableTypes', {'string', 'string', ...
    'double', 'double', 'double', ... % HGF2 prior precision omega2
    'double', 'double', 'double', ... % HGF3 prior precision omega2
    'double', 'double', 'double'}, ... % HGF3 prior precision omega3
    'VariableNames', {'ID', 'sex', ...
    'HGF2_priorPrec_omega2_saline', 'HGF2_priorPrec_omega2_5mg', 'HGF2_priorPrec_omega2_10mg', ...
    'HGF3_priorPrec_omega2_saline', 'HGF3_priorPrec_omega2_5mg', 'HGF3_priorPrec_omega2_10mg', ...
    'HGF3_priorPrec_omega3_saline', 'HGF3_priorPrec_omega3_5mg', 'HGF3_priorPrec_omega3_10mg'});

% Populate the table
for iMouse = 1:nSize
    currMouse = mouseIDs{iMouse};

    % Set ID
    RQ3_4_dataTable.ID(iMouse) = currMouse;

    % Get basic info (sex) from the first available condition file
    for iCond = 1:length(optionsFile.cohort(cohortNo).conditions)
        loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], optionsFile.cohort(cohortNo).conditions{iCond}, iRep, nReps, 'info');
        infoPath = [char(optionsFile.paths.cohort(cohortNo).data), 'mouse', char(currMouse), '_', loadInfoName, '.mat'];
        if isfile(infoPath)
            load(infoPath, 'MouseInfoTable');
            RQ3_4_dataTable.sex(iMouse) = MouseInfoTable.Sex;
            break;
        end
    end

    % Get prior precision values for each condition from optionsFile
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

            % HGF 2-level - prior precision of omega2
            hgf2_col = ['HGF2_priorPrec_omega2_', currCondition];
            fitPath = [char(optionsFile.paths.cohort(cohortNo).results), 'mouse', char(currMouse), '_', ...
                loadName, '_', optionsFile.dataFiles.rawFitFile{model_HGF2}, '.mat'];

            if isfile(fitPath)
                load(fitPath, 'est');
                if isfield(est.traj, 'sahat') && size(est.traj.sahat, 2) >= 2
                    RQ3_4_dataTable.(hgf2_col)(iMouse) = est.traj.sahat(1, 2);  % First precision estimate of omega2
                else
                    warning('Prior precision field est.traj.sahat(1,2) not found for mouse %s in condition %s (HGF2)', currMouse, currCondition);
                    RQ3_4_dataTable.(hgf2_col)(iMouse) = NaN;
                end
            else
                RQ3_4_dataTable.(hgf2_col)(iMouse) = NaN;
            end

            % HGF 3-level - load file once for both omega2 and omega3
            fitPath = [char(optionsFile.paths.cohort(cohortNo).results), 'mouse', char(currMouse), '_', ...
                loadName, '_', optionsFile.dataFiles.rawFitFile{model_HGF3}, '.mat'];

            if isfile(fitPath)
                load(fitPath, 'est');

                % HGF 3-level - prior precision of omega2
                hgf3_omega2_col = ['HGF3_priorPrec_omega2_', currCondition];
                if isfield(est.traj, 'sahat') && size(est.traj.sahat, 2) >= 2
                    RQ3_4_dataTable.(hgf3_omega2_col)(iMouse) = est.traj.sahat(1, 2);  % First precision estimate of omega2
                else
                    warning('Prior precision field est.traj.sahat(1,2) not found for mouse %s in condition %s (HGF3)', currMouse, currCondition);
                    RQ3_4_dataTable.(hgf3_omega2_col)(iMouse) = NaN;
                end

                % HGF 3-level - prior precision of omega3
                hgf3_omega3_col = ['HGF3_priorPrec_omega3_', currCondition];
                if isfield(est.traj, 'sahat') && size(est.traj.sahat, 2) >= 3
                    RQ3_4_dataTable.(hgf3_omega3_col)(iMouse) = est.traj.sahat(1, 3);  % First precision estimate of omega3
                else
                    warning('Prior precision field est.traj.sahat(1,3) not found for mouse %s in condition %s', currMouse, currCondition);
                    RQ3_4_dataTable.(hgf3_omega3_col)(iMouse) = NaN;
                end
            else
                % If file doesn't exist, set both HGF3 parameters to NaN
                hgf3_omega2_col = ['HGF3_priorPrec_omega2_', currCondition];
                hgf3_omega3_col = ['HGF3_priorPrec_omega3_', currCondition];
                RQ3_4_dataTable.(hgf3_omega2_col)(iMouse) = NaN;
                RQ3_4_dataTable.(hgf3_omega3_col)(iMouse) = NaN;
            end
        else
            % Set all parameters to NaN for this excluded condition
            hgf2_col = ['HGF2_priorPrec_omega2_', currCondition];
            hgf3_omega2_col = ['HGF3_priorPrec_omega2_', currCondition];
            hgf3_omega3_col = ['HGF3_priorPrec_omega3_', currCondition];

            RQ3_4_dataTable.(hgf2_col)(iMouse) = NaN;
            RQ3_4_dataTable.(hgf3_omega2_col)(iMouse) = NaN;
            RQ3_4_dataTable.(hgf3_omega3_col)(iMouse) = NaN;
        end
    end
end

% Only remove rows where ALL parameters across ALL conditions are NaN
% (i.e., mice that have no valid data for any condition)
allNanRows = true(height(RQ3_4_dataTable), 1);

for iCond = 1:length(optionsFile.cohort(cohortNo).conditions)
    currCondition = optionsFile.cohort(cohortNo).conditions{iCond};
    hgf2_col = ['HGF2_priorPrec_omega2_', currCondition];
    hgf3_omega2_col = ['HGF3_priorPrec_omega2_', currCondition];
    hgf3_omega3_col = ['HGF3_priorPrec_omega3_', currCondition];

    % Check if all parameters are NaN for this condition
    conditionAllNaN = isnan(RQ3_4_dataTable.(hgf2_col)) & ...
        isnan(RQ3_4_dataTable.(hgf3_omega2_col)) & ...
        isnan(RQ3_4_dataTable.(hgf3_omega3_col));

    % If any condition has valid data, don't mark row for removal
    allNanRows = allNanRows & conditionAllNaN;
end

if any(allNanRows)
    fprintf('Removing %d mice with no valid prior precision values across all conditions.\n', sum(allNanRows));
    RQ3_4_dataTable(allNanRows, :) = [];
end

fprintf('Final table contains %d mice.\n', height(RQ3_4_dataTable));

% Save table as both .mat and .csv
savePath = [optionsFile.paths.cohort(cohortNo).groupLevel, optionsFile.cohort(cohortNo).taskPrefix, ...
    optionsFile.cohort(cohortNo).name, '_RQ3_4_dataTable'];

save([savePath, '.mat'], 'RQ3_4_dataTable');
writetable(RQ3_4_dataTable, [savePath, '.csv']);

disp(['Table saved to: ', savePath, '.csv']);

%% CREATE RAINCLOUD PLOT OF HGF 2-LEVEL PRIOR PRECISION PARAMETERS ACROSS SEROTONIN TREATMENT CONDITIONS
plotSaveDir = [optionsFile.paths.cohort(cohortNo).groupLevel, 'plots', filesep];
if ~exist(plotSaveDir, 'dir'); mkdir(plotSaveDir); end

% Define colour scheme for different serotonin treatment conditions and sexes
col = struct();

% Saline group: grey (control/baseline condition on the left)
col.saline = struct('male', [0.3 0.3 0.3], 'female', [0.7 0.7 0.7], 'group', [0.5 0.5 0.5], 'edge', 'black');

% 5mg group: Burnt orange - matching BMS function orange [0.929 0.490 0.192]
col.mg5 = struct('male', [0.85 0.42 0.15], 'female', [0.95 0.65 0.4], 'group', [0.929 0.490 0.192], 'edge', [0.7 0.35 0.1]);

% 10mg group: Dark burnt orange - darker version of BMS orange
col.mg10 = struct('male', [0.7 0.3 0.1], 'female', [0.85 0.5 0.25], 'group', [0.78 0.4 0.15], 'edge', [0.55 0.25 0.05]);

% Prepare data by treatment condition - extract HGF2 prior precision omega2 values
salineData = RQ3_4_dataTable.HGF2_priorPrec_omega2_saline;
salineSex = RQ3_4_dataTable.sex;
validSaline = ~isnan(salineData);
salineData = salineData(validSaline);
salineSex = salineSex(validSaline);

mg5Data = RQ3_4_dataTable.HGF2_priorPrec_omega2_5mg;
mg5Sex = RQ3_4_dataTable.sex;
validMg5 = ~isnan(mg5Data);
mg5Data = mg5Data(validMg5);
mg5Sex = mg5Sex(validMg5);

mg10Data = RQ3_4_dataTable.HGF2_priorPrec_omega2_10mg;
mg10Sex = RQ3_4_dataTable.sex;
validMg10 = ~isnan(mg10Data);
mg10Data = mg10Data(validMg10);
mg10Sex = mg10Sex(validMg10);

% Create main figure with specified size and white background
figure('Position', [100 100 900 700], 'Color', 'white');
hold on;

% Plot raincloud for each treatment condition at different x-positions (saline on left)
if ~isempty(salineData)
    plotRaincloudWithSex(salineData, salineSex, 1.0, col.saline);
end
if ~isempty(mg5Data)
    plotRaincloudWithSex(mg5Data, mg5Sex, 2.0, col.mg5);
end
if ~isempty(mg10Data)
    plotRaincloudWithSex(mg10Data, mg10Sex, 3.0, col.mg10);
end

% Set fixed y-axis limits from 0 to 2.5
ylim([0, 2.5]);

% Format plot appearance
set(gca, 'XTick', [1.0, 2.0, 3.0], 'XTickLabel', {'Saline', '5mg', '10mg'}, ...
    'FontName', 'Arial', 'FontSize', 20, 'Box', 'off');

% Set x-axis limits
xlim([0.4, 3.6]);

% Add grid
grid on;
set(gca, 'GridAlpha', 0.3, 'GridLineStyle', ':');

% Add labels and title
ylabel('$\hat{\pi}$ (Prior precision)', 'FontSize', 22, 'FontName', 'Arial', 'Interpreter', 'latex');
h_title = title('HGF 2-Level: Prior Precision Across Serotonin Conditions', 'FontSize', 22, 'FontName', 'Arial');
h_title.Position(2) = h_title.Position(2) + 0.05;  % Move title up

ax = gca;
yLimits = ylim;
xLimits = xlim;

% Add left axis line
line([xLimits(1), xLimits(1)], yLimits, 'Color', 'black', 'LineWidth', 0.5);
% Add bottom axis line
line(xLimits, [yLimits(1), yLimits(1)], 'Color', 'black', 'LineWidth', 0.5);

% Simplified legend showing marker shapes for sex coding
p1 = line(NaN, NaN, 'Marker', 's', 'MarkerSize', 16, 'MarkerFaceColor', col.mg5.male, ...
    'MarkerEdgeColor', 'black', 'LineStyle', 'none', 'LineWidth', 0.5);
p2 = line(NaN, NaN, 'Marker', '^', 'MarkerSize', 16, 'MarkerFaceColor', col.mg5.female, ...
    'MarkerEdgeColor', 'black', 'LineStyle', 'none', 'LineWidth', 0.5);

lgd = legend([p1, p2], {'Male', 'Female'}, ...
    'FontSize', 16, 'FontName', 'Arial', 'EdgeColor', 'white', 'Box', 'off');
lgd.Position = [0.82 0.8 0.08 0.1];

hold off;

% Save plot in both .fig and .png formats
savePath = fullfile([optionsFile.paths.cohort(cohortNo).groupLevel, 'RQ3_4_HGF2PriorPrecisionSerotoninTreatmentRaincloudPlot']);
saveas(gcf, [savePath, '.fig']);
print(gcf, [savePath, '.png'], '-dpng', '-r300');
disp(['HGF 2-Level prior precision serotonin treatment raincloud plot saved to: ', savePath]);

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
                140, pointColour, 'filled', markerShape); % Marker size = 110
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

end