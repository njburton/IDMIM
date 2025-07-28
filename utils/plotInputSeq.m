function plotInputSeq(cohortNo)
%% plotInputSeq - Visualize task structure and reward probability sequences
%
% This function creates publication-quality plots showing the structure of
% behavioral tasks used in operant decision-making experiments. It visualizes
% the reward probability sequences across trials, highlighting stable and
% volatile phases where reward contingencies change. The plots show both
% the actual rewarding lever assignments (binary sequence) and the underlying
% reward probability structure, making it easy to identify periods of
% environmental stability versus volatility.
%
% SYNTAX: plotInputSeq(cohortNo)
%
% INPUT:
%   cohortNo - Integer specifying which cohort to plot (1, 2, or 3)
%              1: UCMS cohort (ABA2_R task)
%              2: HGF Pilot cohort (TestTaskA)
%              3: 5HT cohort (TestTaskA)
%
% OUTPUT:
%   - Publication-ready figure (.fig and .png formats)
%   - Console confirmation of save location
%
% Coded by: 2025; Nicholas J. Burton,
%           nicholasjburton91@gmail.com.au
%
% -------------------------------------------------------------------------
% Copyright (C) 2025
%
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
% =========================================================================

%% LOAD CONFIGURATION
if exist('optionsFile.mat','file')==2
    load('optionsFile.mat');
else
    optionsFile = runOptions();
end

%% GET TASK-SPECIFIC DATA BASED ON COHORT
switch cohortNo
    case 1 % UCMS ABA_R
        Y1 = readmatrix(fullfile(optionsFile.paths.inputsDir, ...
            optionsFile.cohort(cohortNo).name, ...
            [optionsFile.cohort(cohortNo).taskPrefix, ...
            optionsFile.cohort(cohortNo).testTask(1).name, '.txt']));
        Y2 = [0.8*ones(1,60),0.5*ones(1,10),0.65*ones(1,5),0.3*ones(1,8),...
            0.45*ones(1,12),0.75*ones(1,6),0.55*ones(1,11),0.25*ones(1,8),...
            0.8*ones(1,60)];
        currTask = optionsFile.cohort(cohortNo).testTask(1).name;
        taskTitle = sprintf('Study %d: Task Structure', cohortNo);

    case {2, 3} % HGF Pilot and 5HT cohorts - TestTaskA
        Y1 = readmatrix(fullfile(optionsFile.paths.inputsDir, ...
            optionsFile.cohort(cohortNo).name, ...
            [optionsFile.cohort(cohortNo).taskPrefix, ...
            optionsFile.cohort(cohortNo).testTask(1).name, '.txt']));
        Y2 = [0.8*ones(1,40),0.3*ones(1,20),0.7*ones(1,20),...
            0.2*ones(1,40),0.7*ones(1,20),0.3*ones(1,20),...
            0.8*ones(1,40),0.3*ones(1,20),0.7*ones(1,20),...
            0.2*ones(1,40)];
        currTask = optionsFile.cohort(cohortNo).testTask(1).name;
        taskTitle = sprintf('Study %d: Task Structure', cohortNo);

    otherwise
        error('Invalid cohort number. Please specify 1, 2, or 3.');
end

%% CREATE FIGURE
figure1 = figure('WindowState','maximized','Color',[1 1 1]);
axes1 = axes('Parent',figure1);
hold(axes1,'on');

% Add blue shading for stable phases
if cohortNo == 2 || cohortNo == 3
    stable_phase_ranges = [1 40; 81 120; 161 200; 241 280];
    for i = 1:size(stable_phase_ranges, 1)
        phase_start = stable_phase_ranges(i, 1);
        phase_end = stable_phase_ranges(i, 2);
        patch([phase_start phase_end phase_end phase_start], ...
            [-0.1 -0.1 1.1 1.1], ...
            [0 0.447058823529412 0.741176470588235], ...
            'FaceAlpha', 0.1, 'EdgeColor', 'none', ...
            'HandleVisibility', 'off');
    end
elseif cohortNo == 1
    stable_phase_ranges = [1 60; 121 180];
    for i = 1:size(stable_phase_ranges, 1)
        phase_start = stable_phase_ranges(i, 1);
        phase_end = stable_phase_ranges(i, 2);
        patch([phase_start phase_end phase_end phase_start], ...
            [-0.1 -0.1 1.1 1.1], ...
            [0 0.447058823529412 0.741176470588235], ...
            'FaceAlpha', 0.1, 'EdgeColor', 'none', ...
            'HandleVisibility', 'off');
    end
end

% Plot rewarding lever assignments
h_lever = plot(Y1,'SeriesIndex',1,'DisplayName','Rewarding lever',...
    'MarkerFaceColor',[0 0.447058823529412 0.741176470588235],...
    'MarkerEdgeColor',[0 0.447058823529412 0.741176470588235],...
    'MarkerSize',20,...
    'Marker','|',...
    'LineWidth',1.4,...
    'LineStyle','none');

% Plot reward probability structure
h_prob = stairs(Y2,'DisplayName','Reward probability','LineWidth',2,'LineStyle','-.',...
    'Color',[1 0 0]);

% Create the legend immediately after plotting
leg = legend('show', 'FontSize', 18, 'EdgeColor', 'none');
set(leg, 'Position', [0.735373260796898,0.743835507480257,0.162890628091991,0.079508641059661]);

% Formatting
ylabel('Right lever reward probability (%)','FontName','Arial','FontSize',24);
xlabel('Trial','FontName','Arial','FontSize',24);
title(taskTitle,'FontSize',26,'FontName','Arial');

% Set cohort-specific axis limits
if cohortNo == 1
    xlim(axes1, [0, 180]);
    set(axes1, 'XTick', 0:20:180);
else % cohortNo == 2 or 3
    xlim(axes1, [0, 280]);
    set(axes1, 'XTick', 0:40:280);
end

ylim(axes1, [-0.1, 1.1]);
hold(axes1,'off');

% Set remaining axes properties
set(axes1,'ClippingStyle','rectangle','FontName','Arial','FontSize',24,...
    'GridAlpha',0.2,'GridLineStyle',':','MinorGridColor',...
    [0.149019607843137 0.149019607843137 0.149019607843137],'XGrid','on',...
    'YTick',[0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1]);

% Add phase labels
addPhaseLabels(axes1, cohortNo);

% Add probability value labels
addProbabilityLabels(axes1, Y2);

%% SAVE FIGURE
savePath = fullfile(optionsFile.paths.cohort(cohortNo).plots, 'taskStructure');
if ~exist(savePath, 'dir')
    mkdir(savePath);
end

figdir = fullfile(savePath, [currTask, '_TrajPlot']);
savefig(figure1, figdir);
print(figdir, '-dpng');

disp(['Plot of ', currTask, ' successfully saved to ', savePath, '.']);

end

%% HELPER FUNCTIONS
function addPhaseLabels(axes1, cohortNo)
% Add phase labels centered above the first instance of each phase type

switch cohortNo
    case 1 % UCMS cohort - ABA2_R task
        % First stable phase - center at trial 30
        text(axes1, 30, 1.05, 'Stable', ...
            'Color', [0 0.447058823529412 0.741176470588235], ...
            'FontWeight', 'bold', 'FontSize', 20, ...
            'HorizontalAlignment', 'center', 'HandleVisibility', 'off');

        % First volatile phase - center at trial 90
        text(axes1, 90, 1.05, 'Volatile', ...
            'Color', [0.635294117647059 0.0784313725490196 0.184313725490196], ...
            'FontWeight', 'bold', 'FontSize', 20, ...
            'HorizontalAlignment', 'center', 'HandleVisibility', 'off');

    case {2, 3} % HGF Pilot and 5HT cohorts - TestTaskA structure
        % First stable phase - center at trial 20
        text(axes1, 20, 1.05, 'Stable', ...
            'Color', [0 0.447058823529412 0.741176470588235], ...
            'FontWeight', 'bold', 'FontSize', 20, ...
            'HorizontalAlignment', 'center', 'HandleVisibility', 'off');

        % First volatile phase - center at trial 60
        text(axes1, 60, 1.05, 'Volatile', ...
            'Color', [0.635294117647059 0.0784313725490196 0.184313725490196], ...
            'FontWeight', 'bold', 'FontSize', 20, ...
            'HorizontalAlignment', 'center', 'HandleVisibility', 'off');
end
end

%% Add probability value labels above the red dotted line
% Only shows each unique probability value once (first occurrence)
function addProbabilityLabels(axes1, Y2)

% Find where probability changes
changePoints = [1, find(diff(Y2) ~= 0) + 1];

% Track which probabilities have already been labeled
labeledProbs = [];

for i = 1:length(changePoints)
    startPos = changePoints(i);

    % Find end position
    if i < length(changePoints)
        endPos = changePoints(i+1) - 1;
    else
        endPos = length(Y2);
    end

    % Get probability value
    probValue = Y2(startPos);

    % Only add label if this probability hasn't been labeled yet
    if ~ismember(probValue, labeledProbs)
        % Calculate middle position
        middlePos = round((startPos + endPos) / 2);

        % Create label
        text(axes1, middlePos, probValue + 0.01, num2str(probValue), ...
            'Color', [0.8 0 0], 'FontSize', 16, 'FontWeight', 'bold', ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
            'HandleVisibility', 'off');

        % Add this probability to the labeled list
        labeledProbs = [labeledProbs, probValue];
    end
end
end