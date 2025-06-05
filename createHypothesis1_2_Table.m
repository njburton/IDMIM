function createHypothesis1_2_Table

% createHypothesis1_2_Table - Extract learning parameters between experimental groups
%
% This function extracts computational model parameters from fitted models comparing
% treatment and control groups for each mouse. It collects reward predictability parameters from the
% hierarchical Gaussian filter model (2-level (omega2)) to examine group differences
% in reward predictability estimates. The resulting data table contains one row per mouse with
% model parameters and group information, allowing for statistical analysis of how
% experimental manipulations affect computational parameters of learning.
% Per-condition exclusion criteria are applied rather than per-mouse exclusion.
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

% load or run options for running this function
if exist('optionsFile.mat','file')==2
    load('optionsFile.mat');
else
    optionsFile = runOptions();
end

% Prespecify variables needed
iModel  = 2; % 2-level HGF as it was the winning model for the control group
iTask   = 1;
iRep    = 1;
nReps   = 1;
cohortNo = 1;
subCohort = [];
currTask = optionsFile.cohort(cohortNo).testTask(1).name;
[mouseIDs,nSize] = getSampleVars(optionsFile,cohortNo,subCohort);

%% EXCLUDE MICE that have NO data files at all
% Only exclude mice that have no data files for any condition
noDataArray = zeros(1,nSize);

for iMouse = 1:nSize
    currMouse = mouseIDs{iMouse};
    loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,...
        [],[],iRep,nReps,'info');
    if ~isfile([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',loadInfoName,'.mat'])
        disp(['data for mouse ', currMouse,' not available']);
        noDataArray(iMouse) = iMouse;
    end
end

noDataArray = sort(noDataArray,'descend');
noDataArray(noDataArray==0)=[];

for i=noDataArray
    mouseIDs(i) =[];
end
nSize = numel(mouseIDs);

fprintf('Total mice with at least some data: %d\n', nSize);

% Create the table with proper variable types from the beginning
RQ1_2_dataTable = table('Size', [nSize, 4], ...
    'VariableTypes', {'string', 'string', 'string', 'double'}, ...
    'VariableNames', {'ID', 'sex', 'condition', 'omega2'});

%% LOAD data with per-condition exclusion checking
% Load data and populate table
for iMouse = 1:nSize
    currMouse = mouseIDs{iMouse};

    % Load info file to get sex and condition, and check exclusion criteria
    loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], [], iRep, nReps, 'info');
    infoPath = [char(optionsFile.paths.cohort(cohortNo).data), 'mouse', char(currMouse), '_', loadInfoName, '.mat'];

    % Initialise variables
    shouldExclude = false;

    if isfile(infoPath)
        load(infoPath, 'MouseInfoTable');
        RQ1_2_dataTable.ID(iMouse) = currMouse;
        RQ1_2_dataTable.sex(iMouse) = MouseInfoTable.Sex;
        RQ1_2_dataTable.condition(iMouse) = MouseInfoTable.Condition;

        % Check exclusion criteria for this mouse
        if isfield(table2struct(MouseInfoTable), 'exclCrit1_met') && ...
                isfield(table2struct(MouseInfoTable), 'exclCrit2_met')

            if MouseInfoTable.exclCrit1_met || MouseInfoTable.exclCrit2_met
                shouldExclude = true;
                disp(['Mouse ', currMouse, ' excluded based on exclusion criteria']);
            end
        end
    end

    % Only extract parameters if this mouse should not be excluded
    if ~shouldExclude
        % Load model fit results to get omega2
        loadName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], [], iRep, nReps, []);
        fitPath = [char(optionsFile.paths.cohort(cohortNo).results), 'mouse', char(currMouse), '_', ...
            loadName, '_', optionsFile.dataFiles.rawFitFile{iModel}, '.mat'];

        if isfile(fitPath)
            load(fitPath, 'est');
            % Extract omega2 parameter from the HGF 2-level model
            RQ1_2_dataTable.omega2(iMouse) = est.p_prc.om(2);  % Access omega2 (level 2 parameter)
        else
            RQ1_2_dataTable.omega2(iMouse) = NaN;
        end
    else
        % Set parameter to NaN for excluded mouse
        RQ1_2_dataTable.omega2(iMouse) = NaN;
    end
end

% Remove any rows where parameters are NaN (i.e., mice that were excluded or had no valid data)
validRows = ~isnan(RQ1_2_dataTable.omega2);
RQ1_2_dataTable = RQ1_2_dataTable(validRows, :);

if sum(~validRows) > 0
    fprintf('Removed %d mice with no valid parameter values.\n', sum(~validRows));
end

fprintf('Final table contains %d mice.\n', height(RQ1_2_dataTable));

% Save table as both .mat and .csv
savePath = [optionsFile.paths.cohort(cohortNo).groupLevel, optionsFile.cohort(cohortNo).taskPrefix, ...
    optionsFile.cohort(cohortNo).name, '_RQ1_2_dataTable'];

save([savePath, '.mat'], 'RQ1_2_dataTable');
writetable(RQ1_2_dataTable, [savePath, '.csv']);

disp(['Table saved to: ', savePath, '.csv']);

%% CREATE RAINCLOUD PLOT OF 2-LEVEL HGF (WINNING MODEL OF CONTROLS) REWARD PREDICTABILITY PARAMETER (OMEGA2)
% Define colour scheme for different groups and sexes
col = struct();
% Control group: dark grey males, light grey females, medium grey for violin/box
col.control = struct('male', [0.2 0.2 0.2], 'female', [0.8 0.8 0.8], 'group', [0.5 0.5 0.5], 'edge', 'black');
% Treatment group: dark orange males, light orange females, burnt orange for violin/box
col.treatment = struct('male', [0.7 0.35 0.1], 'female', [1.0 0.6 0.4], 'group', [0.929 0.490 0.192], 'edge', [0.7 0.35 0.1]);

% Prepare data by experimental group
controlIdx = strcmp(RQ1_2_dataTable.condition, 'control');
treatmentIdx = strcmp(RQ1_2_dataTable.condition, 'treatment');

% Extract control group data and remove NaN values
controlData = RQ1_2_dataTable.omega2(controlIdx);
controlSex = RQ1_2_dataTable.sex(controlIdx);
validControl = ~isnan(controlData);
controlData = controlData(validControl);
controlSex = controlSex(validControl);

% Extract treatment group data and remove NaN values
treatmentData = RQ1_2_dataTable.omega2(treatmentIdx);
treatmentSex = RQ1_2_dataTable.sex(treatmentIdx);
validTreatment = ~isnan(treatmentData);
treatmentData = treatmentData(validTreatment);
treatmentSex = treatmentSex(validTreatment);

% Create main figure with specified size and white background
figure('Position', [100 100 700 600], 'Color', 'white');
hold on;

% Plot raincloud for each group at different x-positions
if ~isempty(controlData)
    plotRaincloudWithSex(controlData, controlSex, 1.05, col.control);    % Control at x = 1.05
end
if ~isempty(treatmentData)
    plotRaincloudWithSex(treatmentData, treatmentSex, 1.75, col.treatment); % Treatment at x = 1.75
end

% Format plot appearance
set(gca, 'XTick', [1.05, 1.75], 'XTickLabel', {'Control', 'Treatment'}, 'FontName', 'Arial', 'FontSize', 20);
ylabel('\omega_2 (Reward predictability parameter)', 'FontSize', 20, 'FontName', 'Arial', 'Interpreter', 'tex');
title('HGF 2-Level Model: Treatment vs Control', 'FontSize', 24, 'FontName', 'Arial');
set(get(gca,'Title'), 'Position', get(get(gca,'Title'), 'Position') + [0 0.2 0]); % Move title up
grid on; set(gca, 'GridAlpha', 0.3,'GridLineStyle', ':');
xlim([0.5, 2.3]);

% Create custom legend with invisible lines to show marker styles
% Square markers for males, triangle markers for females
p1 = line(NaN, NaN, 'Marker', 's', 'MarkerSize', 10, 'MarkerFaceColor', col.control.male, 'MarkerEdgeColor', 'black', 'LineStyle', 'none', 'LineWidth', 0.5);
p2 = line(NaN, NaN, 'Marker', '^', 'MarkerSize', 10, 'MarkerFaceColor', col.control.female, 'MarkerEdgeColor', 'black', 'LineStyle', 'none', 'LineWidth', 0.5);
p3 = line(NaN, NaN, 'Marker', 's', 'MarkerSize', 10, 'MarkerFaceColor', col.treatment.male, 'MarkerEdgeColor', col.treatment.edge, 'LineStyle', 'none', 'LineWidth', 0.5);
p4 = line(NaN, NaN, 'Marker', '^', 'MarkerSize', 10, 'MarkerFaceColor', col.treatment.female, 'MarkerEdgeColor', col.treatment.edge, 'LineStyle', 'none', 'LineWidth', 0.5);
lgd = legend([p1, p2, p3, p4], {'Control Male', 'Control Female', 'Treatment Male', 'Treatment Female'}, 'FontSize', 13, 'FontName', 'Arial', 'EdgeColor', 'white');
lgd.Position = [0.763554686314116 0.740129589632828 0.132682294038435 0.145788336933045]; % Position legend in top-right

hold off;

% Save plot in both .fig and .png formats
savePath = fullfile([optionsFile.paths.cohort(cohortNo).groupLevel, 'RQ1_2_TreatmentControlRaincloudPlot']);
saveas(gcf, [savePath, '.fig']);
print(gcf, [savePath, '.png'], '-dpng', '-r300');
disp(['Raincloud plot saved to: ', savePath]);

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
            h.MarkerEdgeColor = colours.edge;              % Edge color (black or dark orange)
            h.LineWidth = 0.5;                             % Thin edge line
        end

        %% 3. BOX PLOT (Summary Statistics)
        % Calculate quartiles for box plot
        q = quantile(data, [0.25, 0.5, 0.75]);            % 25th, 50th, 75th percentiles

        % Choose box fill color based on group (control vs treatment)
        if isequal(colours.group, [0.5 0.5 0.5])
            boxFillColour = [0.9 0.95 1.0];                % Light blue-white for control
        else
            boxFillColour = [1.0 0.98 0.92];               % Light cream for treatment
        end

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
% 4. Colours: Modify the col.control and col.treatment struct values
% 5. X-positions: Change 1.05 and 1.75 values in main plotting calls
% 6. Box width: Modify the 0.1 value in rectangle width (3rd parameter)
% 7. Point positioning: Adjust the '-0.2' offset in scatter x-position
end