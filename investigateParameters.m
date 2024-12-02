function investigateParameters
%% investigateParameters - Process and extract experimental task data from MED-PC files
%
% SYNTAX:  investigateParameters(optionsFile)
% INPUT:   optionsFile - Structure containing analysis options and paths
% OUTPUT:  optionsFile - Updated structure after data processing
%
% Authors: Katharina Wellstein (30/5/2023), Nicholas Burton (23/2/2024)
% -------------------------------------------------------------------------

tic

% Load options
load("optionsFile.mat");
% Load modelInv.mat
load([optionsFile.paths.mouseModelFitFilesDir,filesep,'modelInv.mat']);
load(char(fullfile(optionsFile.paths.databaseDir, optionsFile.fileName.dataBaseFileName)));

%% CREATE TABLE
TASK_TABLE_SPEC = {...
    'MouseID',           'string';
    'Group',             'string';
    'Sex',               'string';
    'Task',              'string';
    'TaskRepetition',    'single';
    'HGF3_zeta',          'double';
    'HGF3_wt',            'double';
    'HGF3_omega2',        'single';
    'HGF3_omega3',        'double';
    'HGF3_sahat1',        'double';
    'HGF3_sahat2',        'double';
    'HGF3_sahat3',        'double';
    'HGF3_epsi2',         'double';
    'HGF3_epsi3',         'double';
    'HGF2_zeta',          'double';
    'HGF2_wt',            'double';
    'HGF2_omega2',        'single';
    'HGF2_sahat1',        'double';
    'HGF2_sahat2',        'double';
    'HGF2_sahat3',        'double';
    'HGF2_epsi2',         'double';
    'HGF2_epsi3',         'double';
    'RW_zeta',           'double';
    'RW_alpha',          'double';
    'omissions'          'double'};

dataTbl = table('Size', [length(rawDataFileInfo.MouseID), size(TASK_TABLE_SPEC, 1)], ...
    'VariableTypes', TASK_TABLE_SPEC(:,2)', ...
    'VariableNames', TASK_TABLE_SPEC(:,1)');

for mousei = 1:length(rawDataFileInfo.MouseID)
    dataTbl.MouseID(mousei)        = rawDataFileInfo.MouseID(mousei);
    dataTbl.Sex(mousei)            = rawDataFileInfo.sex(mousei);
    dataTbl.Group(mousei)          = rawDataFileInfo.group(mousei);
    dataTbl.Task(mousei)           = rawDataFileInfo.Task(mousei);
    dataTbl.TaskRepetition(mousei) = rawDataFileInfo.TaskRepetition(mousei);
    dataTbl.omissions(mousei)      = width(allMice(mousei).est.irr);  

    dataTbl.HGF3_zeta(mousei)       = allMice(mousei,1).est.p_obs.ze;
    dataTbl.HGF3_wt(mousei)         = mean(allMice(mousei,1).est.traj.wt(:,1));
    dataTbl.HGF3_omega2(mousei)     = allMice(mousei,1).est.p_prc.om(2);
    dataTbl.HGF3_omega3(mousei)     = allMice(mousei,1).est.p_prc.om(3);
    dataTbl.HGF3_sahat1(mousei)     = mean(allMice(mousei,1).est.traj.sahat(:,1));
    dataTbl.HGF3_sahat2(mousei)     = mean(allMice(mousei,1).est.traj.sahat(:,2));
    dataTbl.HGF3_sahat3(mousei)     = mean(allMice(mousei,1).est.traj.sahat(:,3));
    dataTbl.HGF3_epsi2(mousei)      = mean(allMice(mousei,1).est.traj.epsi(:,2));
    dataTbl.HGF3_epsi3(mousei)      = mean(allMice(mousei,1).est.traj.epsi(:,3));
    dataTbl.HGF2_zeta(mousei)       = allMice(mousei,2).est.p_obs.ze;
    dataTbl.HGF2_wt(mousei)         = mean(allMice(mousei,2).est.traj.wt(:,1));
    dataTbl.HGF2_omega2(mousei)     = allMice(mousei,2).est.p_prc.om(2);
    dataTbl.HGF2_sahat1(mousei)     = mean(allMice(mousei,2).est.traj.sahat(:,1));
    dataTbl.HGF2_sahat2(mousei)     = mean(allMice(mousei,2).est.traj.sahat(:,2));
    dataTbl.HGF2_sahat3(mousei)     = mean(allMice(mousei,2).est.traj.sahat(:,3));
    dataTbl.HGF2_epsi2(mousei)      = mean(allMice(mousei,2).est.traj.epsi(:,2));
    dataTbl.HGF2_epsi3(mousei)      = mean(allMice(mousei,2).est.traj.epsi(:,3));
    dataTbl.RW_zeta(mousei)         = allMice(mousei,3).est.p_obs.ze;
    dataTbl.RW_alpha(mousei)        = allMice(mousei,3).est.p_prc.al;
end

%save([optionsFile.paths.resultsDir,'investigateParametersResults.mat'],'dataTbl');

%% PLOT
%Check omissions and if below threshold plot the following!!!!
% for n = 1:length(optionsFile.Task.MouseID) 
%     if dataTbl.omissions(n) < 36

%create binary index of mice of who passed omission exclusion criteria


%omissions
% fig = boxplot(dataTbl.omissions,dataTbl.group,...
%     'Labels',{'HealthyControls','UCMS'}, 'Widths',0.3);
% xlabel('');
% ylabel('');
% title('Omissions');
% figDir = fullfile([char(optionsFile.paths.plotsDir),filesep,'avgRLeverPress']);
% save([figDir,'.fig']);
% print([figDir,'.png'], '-dpng');
% close all;

% Get unique tasks and max repetitions
uniqueTasks = unique(dataTbl.Task);
maxReps = max(dataTbl.TaskRepetition);

% Define a more professional color scheme and consistent markers
groupColors = containers.Map({'Control', 'UCMS'}, {[0.2 0.6 0.8], [0.8 0.3 0.3]});  % Blue and Red
sexMarkers = containers.Map({'Male', 'Female'}, {'o', 'd'});  % Circle and Diamond
markerSize = 60;  % Consistent marker size

% Create a figure for each task
for taskIdx = 1:length(uniqueTasks)
    currentTask = uniqueTasks(taskIdx);
    
    % Filter data for current task
    taskData = dataTbl(strcmp(dataTbl.Task, currentTask), :);
    
    % Get unique repetitions for this task
    taskReps = unique(taskData.TaskRepetition);
    
    % Create figure with adjusted size and resolution
    figure('Name', ['Task: ' char(currentTask)], 'Position', [100 100 1800 900], 'Color', 'white');
    
    % Create subplot for each repetition
    for repIdx = 1:length(taskReps)
        currentRep = taskReps(repIdx);
        
        % Filter data for current repetition
        repData = taskData(taskData.TaskRepetition == currentRep, :);
        
        % Subplot A: Group distributions with violin plots
        subplot(2, length(taskReps), repIdx);
        hold on;
        
        groups = unique(repData.Group);
        sexes = unique(repData.Sex);
        
        % Prepare data for violin plots
        plotData = {};
        plotLabels = {};
        xPositions = [];
        groupMeans = [];
        groupSEMs = [];
        
        xPos = 1;
        for groupIdx = 1:length(groups)
            for sexIdx = 1:length(sexes)
                currentData = repData(strcmp(repData.Group, groups(groupIdx)) & ...
                                    strcmp(repData.Sex, sexes(sexIdx)), :);
                if ~isempty(currentData)
                    plotData{end+1} = currentData.HGF_omega2;
                    plotLabels{end+1} = [char(groups(groupIdx)) '-' char(sexes(sexIdx))];
                    xPositions(end+1) = xPos;
                    
                    % Calculate statistics
                    groupMeans(end+1) = mean(currentData.HGF_omega2, 'omitnan');
                    groupSEMs(end+1) = std(currentData.HGF_omega2, 'omitnan') / sqrt(sum(~isnan(currentData.HGF_omega2)));
                    
                    % Plot individual points with jitter
                    jitter = (rand(height(currentData), 1) - 0.5) * 0.2;
                    scatter(xPos * ones(height(currentData), 1) + jitter, ...
                           currentData.HGF_omega2, markerSize, groupColors(char(groups(groupIdx))), ...
                           sexMarkers(char(sexes(sexIdx))), 'filled', 'MarkerFaceAlpha', 0.6);
                end
                xPos = xPos + 1;
            end
        end
        
        % Create violin plots with transparent fill
        violinplot(plotData, 'x', xPositions, 'facecolor', ...
               cell2mat(values(groupColors)), 'facealpha', 0.2, 'plotlegend', false);
        
        % Add mean and SEM with thicker error bars
        errorbar(xPositions, groupMeans, groupSEMs, 'k', 'LineWidth', 2, 'CapSize', 10);
        
        % Add statistical annotations (you'll need to implement your specific tests)
        % Example placeholder for statistical annotation:
        % sigstar({[1,2], [3,4]}, [0.05, 0.01]);
        
        % Improve axes and labels
        xticks(xPositions);
        xticklabels(plotLabels);
        xtickangle(45);
        ylabel('HGF\_\omega_2', 'Interpreter', 'tex', 'FontSize', 12);  % LaTeX formatting
        title(['Repetition ' num2str(currentRep) ' - Group Distributions'], 'FontSize', 14);
        box on;
        grid on;
        
        % Add sample size annotations
        for i = 1:length(plotData)
            text(xPositions(i), min(plotData{i}), ['n=' num2str(length(plotData{i}))], ...
                 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
        end
        
        % Subplot B: Individual mouse trajectories with enhanced visualization
        subplot(2, length(taskReps), repIdx + length(taskReps));
        hold on;
        
        % Sort mice by group and sex for clearer visualization
        uniqueMice = unique(repData.MouseID);
        [~, sortIdx] = sortrows([string(repData.Group), string(repData.Sex)]);
        uniqueMice = uniqueMice(sortIdx);
        
        % Plot individual mice with enhanced markers
        mousePositions = [];
        mouseValues = [];
        for mouseIdx = 1:length(uniqueMice)
            mouseName = uniqueMice(mouseIdx);
            mouseData = repData(strcmp(repData.MouseID, mouseName), :);
            
            if ~isempty(mouseData)
                groupColor = groupColors(char(mouseData.Group(1)));
                sexMarker = sexMarkers(char(mouseData.Sex(1)));
                
                % Store positions for connecting lines
                mousePositions(end+1) = mouseIdx;
                mouseValues(end+1) = mouseData.HGF_omega2(1);
                
                % Plot enhanced markers
                scatter(mouseIdx, mouseData.HGF_omega2, markerSize*1.2, groupColor, sexMarker, ...
                        'filled', 'DisplayName', [char(mouseName) ' (' char(mouseData.Group(1)) ...
                        '-' char(mouseData.Sex(1)) ')'], 'MarkerFaceAlpha', 0.8, 'LineWidth', 1.5);
            end
        end
        
        % Improve axes and labels
        xlim([0.5, length(uniqueMice)+0.5]);
        xticks(1:length(uniqueMice));
        xticklabels(uniqueMice);
        xtickangle(90);
        ylabel('HGF\_\omega_2', 'Interpreter', 'tex', 'FontSize', 12);
        title(['Repetition ' num2str(currentRep) ' - Individual Values'], 'FontSize', 14);
        
        % Add legend only for first repetition
        if repIdx == 1
            legend('Location', 'eastoutside', 'NumColumns', 2);
        end
        
        box on;
        grid on;
    end
    
    % Add informative overall title
    sgtitle({['Task: ' char(currentTask)], 'HGF \omega_2 Parameter Analysis'}, ...
            'FontSize', 16, 'FontWeight', 'bold', 'Interpreter', 'tex');
end

% Add a text box with analysis notes
annotation('textbox', [0.02 0.02 0.3 0.05], 'String', ...
           {'Notes:', '- Error bars represent SEM', '- n values shown below each group'}, ...
           'EdgeColor', 'none', 'FitBoxToText', 'on');


























% %% RW alpha parameter
% fig = boxplot(dataTbl.RW_alpha,dataTbl.group,...
%     'Colors','b','Labels',{'HealthyControls','UCMS'}, 'Widths',0.3);
% xlabel('');
% ylabel('alpha');
% title('RW alpha parameter posterior');
% figDir = fullfile([char(optionsFile.paths.plotsDir),filesep,'RW_alpha_plot']);
% save([figDir,'.fig']);
% print([figDir,'.png'], '-dpng');
% close all;

%% HGF omega1
fig = boxplot(dataTbl.HGF_omega1,dataTbl.group,...
    'Colors','b','Labels',{'HealthyControls','UCMS'}, 'Widths',0.3);
xlabel('');
ylabel('omega1');
title('HGF Omega1 parameter posterior or Belief above rewarding lever side');
figDir = fullfile([char(optionsFile.paths.plotsDir),filesep,'HGF_omega1_plot']);
save([figDir,'.fig']);
print([figDir,'.png'], '-dpng');
close all;

%% HGF omega2
fig = boxplot(dataTbl.HGF_omega2,dataTbl.group, ...
    'Colors','b','Labels',{'HealthyControls','UCMS'}, 'Widths',0.3);
xlabel('');
ylabel('omega2');
title('HGF Omega2 parameter posterior');
figDir = fullfile([char(optionsFile.paths.plotsDir),filesep,'HGF_omega2_plot']);
save([figDir,'.fig']);
print([figDir,'.png'], '-dpng');
close all;

%% STATS

[H,P,CI,STATS] = ttest(dataTbl.RW_alpha(find(groupCodes)),dataTbl.RW_alpha(find(~groupCodes)));
[H,P,CI,STATS] = ttest(dataTbl.HGF_omega1(find(groupCodes)),dataTbl.HGF_omega1(find(~groupCodes)));
[H,P,CI,STATS] = ttest(dataTbl.HGF_omega2(find(groupCodes)),dataTbl.HGF_omega2(find(~groupCodes)));

end