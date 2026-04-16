% %% ANALYSE TRAJECTORY CONFIDENCE INTERVALS AND SAVE METRICS
% % Calculate and save trajectory analysis metrics for comparison between studies
% analyseTrajectoryConfidence(sim, cohortNo, optionsFile);
% 
% %% ENHANCED PLOTTING - Task Structure with Simulated Trajectories
% if optionsFile.doCreatePlots
%     % Define model-specific colors
%     modelColors = {
%         [70, 130, 180]/255,   % Steel blue for HGF 3-level (model 1)
%         [255, 140, 0]/255,    % Burnt orange for HGF 2-level (model 2)
%         [34, 139, 34]/255     % Forest green for RW (model 3)
%         };
% 
%     for iTask = 1:nTasks
%         for iModel = 1:nModels
% 
%             % Get task-specific input sequence and probability structure
%             [Y1, Y2] = getTaskInputSequence(cohortNo, iTask, optionsFile);
% 
%             % Create figure with task structure
%             figure1 = figure('WindowState','maximized','Color',[1 1 1]);
%             axes1 = axes('Parent',figure1);
%             hold(axes1,'on');
% 
%             % ADD BLUE SHADING
%             if iTask == 1
%                 if cohortNo == 1
%                     % UCMS cohort stable phases: Stable(1-60) -> Volatile(61-120) -> Stable(121-180)
%                     stable_phase_ranges = [1 60; 121 180]; % Trial ranges for stable phases
%                 elseif cohortNo == 2 || cohortNo == 3
%                     % HGF Pilot and 5HT cohorts stable phases
%                     stable_phase_ranges = [1 40; 81 120; 161 200; 241 280]; % Trial ranges for stable phases
%                 end
% 
%                 % Add blue shading for stable phases using patch
%                 for i = 1:size(stable_phase_ranges, 1)
%                     phase_start = stable_phase_ranges(i, 1);
%                     phase_end = stable_phase_ranges(i, 2);
% 
%                     % Create patch for stable phase shading
%                     patch([phase_start phase_end phase_end phase_start], ...
%                         [-0.1 -0.1 1.1 1.1], ...
%                         [0 0.447058823529412 0.741176470588235], ...
%                         'FaceAlpha', 0.1, 'EdgeColor', 'none', ...
%                         'HandleVisibility', 'off');
%                 end
%             end
% 
%             % Plot input sequence (rewarding lever assignments)
%             h_input = plot(Y1,'SeriesIndex',1,...
%                 'MarkerFaceColor',[0 0.447058823529412 0.741176470588235],...
%                 'MarkerEdgeColor',[0 0.447058823529412 0.741176470588235],...
%                 'MarkerSize',20,...
%                 'Marker','|',...
%                 'LineWidth',1.4,...
%                 'LineStyle','none',...
%                 'HandleVisibility','off');
% 
%             % Plot reward probability structure
%             h_prob = stairs(Y2,'LineWidth',2,'LineStyle','-.',...
%                 'Color',[1 0 0],...
%                 'HandleVisibility','off');
% 
%             % Overlay simulated trajectories with model-specific colors and transparency
%             trajectoryAlpha = 0.3; % 30% opacity
%             currentColor = modelColors{iModel};
% 
%             for iAgent = 1:nSamples
%                 if any(strcmp('muhat',fieldnames(sim.agent(iAgent,iModel).task(iTask).data.traj)))
%                     plot(sim.agent(iAgent,iModel).task(iTask).data.traj.muhat(:,1), ...
%                         'Color', [currentColor, trajectoryAlpha], 'LineWidth', 1.0, ...
%                         'HandleVisibility','off');
%                 else
%                     plot(sim.agent(iAgent,iModel).task(iTask).data.traj.vhat(:,1), ...
%                         'Color', [currentColor, trajectoryAlpha], 'LineWidth', 1.0, ...
%                         'HandleVisibility','off');
%                 end
%             end
% 
%             % Calculate trajectory envelope for density visualisation
%             if nSamples > 1
%                 % Collect all trajectory data
%                 allTrajectories = [];
%                 for iAgent = 1:nSamples
%                     if any(strcmp('muhat',fieldnames(sim.agent(iAgent,iModel).task(iTask).data.traj)))
%                         allTrajectories(:,iAgent) = sim.agent(iAgent,iModel).task(iTask).data.traj.muhat(:,1);
%                     else
%                         allTrajectories(:,iAgent) = sim.agent(iAgent,iModel).task(iTask).data.traj.vhat(:,1);
%                     end
%                 end
% 
%                 % Calculate mean and confidence intervals
%                 meanTraj = mean(allTrajectories, 2);
%                 stdTraj = std(allTrajectories, 0, 2);
%                 upperBound = meanTraj + stdTraj;
%                 lowerBound = meanTraj - stdTraj;
% 
%                 % Plot confidence envelope
%                 x_trials = 1:length(meanTraj);
%                 fill([x_trials, fliplr(x_trials)], [upperBound', fliplr(lowerBound')], ...
%                     currentColor, 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'HandleVisibility', 'off');
% 
%                 % Plot mean trajectory
%                 plot(meanTraj, 'Color', currentColor, 'LineWidth', 3, 'HandleVisibility', 'off');
%             end
% 
%             % Create legend
%             h_legend_input = plot(NaN, NaN, '|', 'Color', [0 0.447058823529412 0.741176470588235], ...
%                 'MarkerSize', 8, 'LineWidth', 1.2, 'DisplayName', 'Rewarding lever');
%             h_legend_prob = plot(NaN, NaN, '-.', 'Color', [1 0 0], ...
%                 'LineWidth', 2, 'DisplayName', 'Reward probability');
%             h_legend_traj = plot(NaN, NaN, '-', 'Color', currentColor, ...
%                 'LineWidth', 2, 'DisplayName', 'Simulated trajectories');
% 
%             % Turn off hold BEFORE formatting and saving
%             hold(axes1,'off');
% 
%             % Formatting - Set axis properties based on cohort
%             ylabel('Right lever reward probability (%)','FontName','Arial','FontSize',22);
%             xlabel('Trial','FontName','Arial','FontSize',22);
%             title(sprintf('Simulation results (n=%d) using %s', nSamples, optionsFile.model.names{iModel}),...
%                 'FontSize',22,'FontName','Arial');
% 
%             % Set cohort-specific axis limits
%             if cohortNo == 1
%                 xlim(axes1, [0, 180]);
%                 set(axes1, 'XTick', 0:20:180);
%             else % cohortNo == 2 or 3
%                 xlim(axes1, [0, 280]);
%                 set(axes1, 'XTick', 0:40:280);
%             end
%             ylim(axes1, [-0.1, 1.1]);
% 
%             % Add grid and formatting
%             set(axes1,'FontName','Arial','FontSize',22,...
%                 'GridAlpha',0.2,'GridLineStyle',':',...
%                 'XGrid','on','YGrid','on',...
%                 'YTick',0:0.1:1.0);
% 
%             % Add phase labels
%             addPhaseLabels(axes1, cohortNo, iTask);
% 
%             % Create legend
%             legend1 = legend(axes1,'show','Location',[0.14683159403089,0.207163425913395,0.167057294857999,0.107181427880446]);
%             set(legend1,'FontSize',16,'EdgeColor','none','Color',[1 1 1 0.5]);
% 
%             % Save figure
%             figdir = fullfile([char(optionsFile.paths.cohort(cohortNo).groupSim),...
%                 optionsFile.cohort(cohortNo).taskPrefix,...
%                 optionsFile.cohort(cohortNo).name,'_predictions_',...
%                 optionsFile.cohort(cohortNo).testTask(iTask).name,'_',...
%                 optionsFile.model.space{iModel}]);
% 
%             % Hide axes toolbar to prevent it from appearing in saved images
%             set(axes1, 'Toolbar', []);
% 
%             % Save .fig files
%             savefig(figure1, [figdir,'.fig']);
% 
%             % Save PNG
%             print(figdir, '-dpng');
% 
%             % Close figure
%             close(figure1);
%         end
%         % reset rng state idx
%         optionsFile.rng.idx = 1;
%     end % END TASK loop
% end % END CREATE PLOTS loop
% 
% disp(['simulated data for cohort ',optionsFile.cohort(cohortNo).name,'  successfully created.'])
% 
% end
% 
% %% HELPER FUNCTIONS
% 
% function analyseTrajectoryConfidence(sim, cohortNo, optionsFile)
% % Analyse trajectory confidence intervals to quantify horizontal/weak beliefs
% % This function calculates various metrics to quantify the "flatness" or uncertainty
% % in the simulated belief trajectories
% 
% nTasks = numel(optionsFile.cohort(cohortNo).testTask);
% nModels = numel(optionsFile.model.space);
% nSamples = optionsFile.simulations.nSamples;
% 
% % Initialize results structure
% trajectory_analysis = struct();
% 
% for iTask = 1:nTasks
%     for iModel = 1:nModels
% 
%         % Collect all trajectory data for this model/task combination
%         allTrajectories = [];
%         for iAgent = 1:nSamples
%             if any(strcmp('muhat',fieldnames(sim.agent(iAgent,iModel).task(iTask).data.traj)))
%                 trajectory = sim.agent(iAgent,iModel).task(iTask).data.traj.muhat(:,1);
%             else
%                 trajectory = sim.agent(iAgent,iModel).task(iTask).data.traj.vhat(:,1);
%             end
%             allTrajectories(:,iAgent) = trajectory;
%         end
% 
%         % Calculate trajectory statistics
%         meanTraj = mean(allTrajectories, 2);
%         stdTraj = std(allTrajectories, 0, 2);
%         medianTraj = median(allTrajectories, 2);
% 
%         % Calculate confidence intervals (95%)
%         lowerCI = prctile(allTrajectories, 2.5, 2);
%         upperCI = prctile(allTrajectories, 97.5, 2);
%         ciWidth = upperCI - lowerCI;
% 
%         % Define task phases based on cohort
%         if cohortNo == 1
%             % UCMS: Stable(1-60) -> Volatile(61-120) -> Stable(121-180)
%             stable_phases = {1:60, 121:180};
%             volatile_phases = {61:120};
%             phase_names = {'Stable1', 'Volatile1', 'Stable2'};
%             phase_ranges = {1:60, 61:120, 121:180};
%         else
%             % HGF Pilot/5HT: S(1-40) -> V(41-80) -> S(81-120) -> V(121-160) -> S(161-200) -> V(201-240) -> S(241-280)
%             stable_phases = {1:40, 81:120, 161:200, 241:280};
%             volatile_phases = {41:80, 121:160, 201:240};
%             phase_names = {'Stable1', 'Volatile1', 'Stable2', 'Volatile2', 'Stable3', 'Volatile3', 'Stable4'};
%             phase_ranges = {1:40, 41:80, 81:120, 121:160, 161:200, 201:240, 241:280};
%         end
% 
%         % Calculate metrics for each phase
%         phase_metrics = struct();
%         for iPhase = 1:length(phase_names)
%             phase_trials = phase_ranges{iPhase};
%             phase_type = phase_names{iPhase};
% 
%             % Extract phase data
%             phase_mean = meanTraj(phase_trials);
%             phase_std = stdTraj(phase_trials);
%             phase_ci_width = ciWidth(phase_trials);
% 
%             % Calculate horizontal/weak belief metrics
%             phase_metrics.(phase_type).mean_trajectory = mean(phase_mean);
%             phase_metrics.(phase_type).std_trajectory = std(phase_mean);
%             phase_metrics.(phase_type).mean_ci_width = mean(phase_ci_width);
%             phase_metrics.(phase_type).max_ci_width = max(phase_ci_width);
%             phase_metrics.(phase_type).min_ci_width = min(phase_ci_width);
% 
%             % Horizontal belief index: how much the trajectory stays around 0.5
%             horizontal_index = 1 - mean(abs(phase_mean - 0.5) / 0.5);
%             phase_metrics.(phase_type).horizontal_belief_index = horizontal_index;
% 
%             % Uncertainty index: average confidence interval width
%             phase_metrics.(phase_type).uncertainty_index = mean(phase_ci_width);
% 
%             % Trajectory variability: how much the mean trajectory varies within phase
%             phase_metrics.(phase_type).trajectory_variability = std(phase_mean);
% 
%             % Distance from extremes: how far trajectories stay from 0 and 1
%             distance_from_extremes = min([phase_mean, 1-phase_mean], [], 2);
%             phase_metrics.(phase_type).mean_distance_from_extremes = mean(distance_from_extremes);
%         end
% 
%         % Calculate overall task metrics
%         overall_metrics = struct();
%         overall_metrics.mean_trajectory = mean(meanTraj);
%         overall_metrics.overall_std = std(meanTraj);
%         overall_metrics.mean_ci_width = mean(ciWidth);
%         overall_metrics.max_ci_width = max(ciWidth);
%         overall_metrics.min_ci_width = min(ciWidth);
%         overall_metrics.horizontal_belief_index = 1 - mean(abs(meanTraj - 0.5) / 0.5);
%         overall_metrics.uncertainty_index = mean(ciWidth);
%         overall_metrics.trajectory_variability = std(meanTraj);
%         overall_metrics.mean_distance_from_extremes = mean(min([meanTraj, 1-meanTraj], [], 2));
% 
%         % Calculate stable vs volatile comparisons
%         if cohortNo == 1
%             stable_trials = [1:60, 121:180];
%             volatile_trials = 61:120;
%         else
%             stable_trials = [1:40, 81:120, 161:200, 241:280];
%             volatile_trials = [41:80, 121:160, 201:240];
%         end
% 
%         stable_ci_width = mean(ciWidth(stable_trials));
%         volatile_ci_width = mean(ciWidth(volatile_trials));
%         stable_horizontal_index = 1 - mean(abs(meanTraj(stable_trials) - 0.5) / 0.5);
%         volatile_horizontal_index = 1 - mean(abs(meanTraj(volatile_trials) - 0.5) / 0.5);
% 
%         comparison_metrics = struct();
%         comparison_metrics.stable_vs_volatile_ci_ratio = stable_ci_width / volatile_ci_width;
%         comparison_metrics.stable_vs_volatile_horizontal_ratio = stable_horizontal_index / volatile_horizontal_index;
%         comparison_metrics.stable_ci_width = stable_ci_width;
%         comparison_metrics.volatile_ci_width = volatile_ci_width;
%         comparison_metrics.stable_horizontal_index = stable_horizontal_index;
%         comparison_metrics.volatile_horizontal_index = volatile_horizontal_index;
% 
%         % Store results
%         trajectory_analysis.task(iTask).model(iModel).phase_metrics = phase_metrics;
%         trajectory_analysis.task(iTask).model(iModel).overall_metrics = overall_metrics;
%         trajectory_analysis.task(iTask).model(iModel).comparison_metrics = comparison_metrics;
%         trajectory_analysis.task(iTask).model(iModel).model_name = optionsFile.model.space{iModel};
%         trajectory_analysis.task(iTask).model(iModel).task_name = optionsFile.cohort(cohortNo).testTask(iTask).name;
% 
%         % Store raw trajectory data for further analysis
%         trajectory_analysis.task(iTask).model(iModel).mean_trajectory = meanTraj;
%         trajectory_analysis.task(iTask).model(iModel).std_trajectory = stdTraj;
%         trajectory_analysis.task(iTask).model(iModel).ci_width = ciWidth;
%         trajectory_analysis.task(iTask).model(iModel).trial_numbers = 1:length(meanTraj);
%     end
% end
% 
% % Save trajectory analysis to .mat file
% analysisPath = fullfile(optionsFile.paths.cohort(cohortNo).groupSim, ...
%     [optionsFile.cohort(cohortNo).taskPrefix, optionsFile.cohort(cohortNo).name, '_trajectory_analysis.mat']);
% save(analysisPath, 'trajectory_analysis');
% 
% % Create and save CSV summary table
% createTrajectoryCSVSummary(trajectory_analysis, cohortNo, optionsFile);
% 
% disp(['Trajectory confidence analysis saved to: ', analysisPath]);
% end
% 
% %%
% function createTrajectoryCSVSummary(trajectory_analysis, cohortNo, optionsFile)
% % Create a CSV summary table of trajectory confidence metrics (overall and comparison only)
% 
% nTasks = numel(optionsFile.cohort(cohortNo).testTask);
% nModels = numel(optionsFile.model.space);
% 
% % Initialise table structure
% tableData = [];
% tableHeaders = {'Cohort', 'Task', 'Model', 'Metric_Type', 'Value'};
% 
% for iTask = 1:nTasks
%     for iModel = 1:nModels
%         task_data = trajectory_analysis.task(iTask).model(iModel);
%         cohort_name = optionsFile.cohort(cohortNo).name;
%         task_name = task_data.task_name;
%         model_name = task_data.model_name;
% 
%         % Add overall metrics
%         overall = task_data.overall_metrics;
%         metrics_to_add = {
%             'Overall_Horizontal_Belief_Index', overall.horizontal_belief_index;
%             'Overall_Uncertainty_Index', overall.uncertainty_index;
%             'Overall_Trajectory_Variability', overall.trajectory_variability;
%             'Overall_Mean_CI_Width', overall.mean_ci_width;
%             'Overall_Max_CI_Width', overall.max_ci_width;
%             'Overall_Mean_Distance_From_Extremes', overall.mean_distance_from_extremes
%             };
% 
%         for i = 1:size(metrics_to_add, 1)
%             tableData = [tableData; {cohort_name, task_name, model_name, ...
%                 metrics_to_add{i,1}, metrics_to_add{i,2}}];
%         end
% 
%         % Add comparison metrics
%         comp = task_data.comparison_metrics;
%         comparison_metrics_to_add = {
%             'Stable_vs_Volatile_CI_Ratio', comp.stable_vs_volatile_ci_ratio;
%             'Stable_vs_Volatile_Horizontal_Ratio', comp.stable_vs_volatile_horizontal_ratio;
%             'Stable_CI_Width', comp.stable_ci_width;
%             'Volatile_CI_Width', comp.volatile_ci_width;
%             'Stable_Horizontal_Index', comp.stable_horizontal_index;
%             'Volatile_Horizontal_Index', comp.volatile_horizontal_index
%             };
% 
%         for i = 1:size(comparison_metrics_to_add, 1)
%             tableData = [tableData; {cohort_name, task_name, model_name, ...
%                 comparison_metrics_to_add{i,1}, comparison_metrics_to_add{i,2}}];
%         end
%     end
% end
% 
% % Create table and save as CSV
% summaryTable = cell2table(tableData, 'VariableNames', tableHeaders);
% csvPath = fullfile(optionsFile.paths.cohort(cohortNo).groupSim, ...
%     [optionsFile.cohort(cohortNo).taskPrefix, optionsFile.cohort(cohortNo).name, '_trajectory_confidence_metrics.csv']);
% writetable(summaryTable, csvPath);
% 
% disp(['Trajectory confidence metrics CSV saved to: ', csvPath]);
% 
% % Also create a wide-format summary for easier comparison
% createWideFormatSummary(trajectory_analysis, cohortNo, optionsFile);
% end
% 
% %%
% function createWideFormatSummary(trajectory_analysis, cohortNo, optionsFile)
% % Create a wide-format CSV for easier comparison between models (overall metrics only)
% 
% nTasks = numel(optionsFile.cohort(cohortNo).testTask);
% nModels = numel(optionsFile.model.space);
% 
% % Initialize wide format table
% wideTableData = [];
% wideHeaders = {'Cohort', 'Task', 'Model'};
% 
% % Add headers for overall metrics
% overall_metrics = {'Overall_Horizontal_Belief_Index', 'Overall_Uncertainty_Index', ...
%     'Overall_Trajectory_Variability', 'Overall_Mean_CI_Width', ...
%     'Overall_Max_CI_Width', 'Overall_Mean_Distance_From_Extremes'};
% 
% % Add headers for comparison metrics
% comparison_metrics = {'Stable_vs_Volatile_CI_Ratio', 'Stable_vs_Volatile_Horizontal_Ratio', ...
%     'Stable_CI_Width', 'Volatile_CI_Width', ...
%     'Stable_Horizontal_Index', 'Volatile_Horizontal_Index'};
% 
% % Combine all headers
% all_headers = [wideHeaders, overall_metrics, comparison_metrics];
% 
% % Populate data
% for iTask = 1:nTasks
%     for iModel = 1:nModels
%         task_data = trajectory_analysis.task(iTask).model(iModel);
%         cohort_name = optionsFile.cohort(cohortNo).name;
%         task_name = task_data.task_name;
%         model_name = task_data.model_name;
% 
%         % Initialise row
%         row_data = {cohort_name, task_name, model_name};
% 
%         % Add overall metrics
%         overall_fields = {'horizontal_belief_index', 'uncertainty_index', ...
%             'trajectory_variability', 'mean_ci_width', ...
%             'max_ci_width', 'mean_distance_from_extremes'};
% 
%         for i = 1:length(overall_fields)
%             field_name = overall_fields{i};
%             if isfield(task_data.overall_metrics, field_name)
%                 row_data{end+1} = task_data.overall_metrics.(field_name);
%             else
%                 row_data{end+1} = NaN;
%             end
%         end
% 
%         % Add comparison metrics
%         comparison_fields = {'stable_vs_volatile_ci_ratio', 'stable_vs_volatile_horizontal_ratio', ...
%             'stable_ci_width', 'volatile_ci_width', ...
%             'stable_horizontal_index', 'volatile_horizontal_index'};
% 
%         for i = 1:length(comparison_fields)
%             field_name = comparison_fields{i};
%             if isfield(task_data.comparison_metrics, field_name)
%                 row_data{end+1} = task_data.comparison_metrics.(field_name);
%             else
%                 row_data{end+1} = NaN;
%             end
%         end
% 
%         wideTableData = [wideTableData; row_data];
%     end
% end
% 
% % Create and save wide format table
% wideTable = cell2table(wideTableData, 'VariableNames', all_headers);
% wideCSVPath = fullfile(optionsFile.paths.cohort(cohortNo).groupSim, ...
%     [optionsFile.cohort(cohortNo).taskPrefix, optionsFile.cohort(cohortNo).name, '_trajectory_confidence_wide.csv']);
% writetable(wideTable, wideCSVPath);
% 
% disp(['Wide format trajectory confidence metrics CSV saved to: ', wideCSVPath]);
% end
% 
% %%
% function addPhaseLabels(axes1, cohortNo, iTask)
% % Add phase labels centered above the first instance of each phase type
% % Different cohorts have different task structures
% 
% switch cohortNo
%     case 1 % UCMS cohort - ABA2_R task
%         if iTask == 1
%             % Task structure: Stable(1-60) -> Volatile(61-120) -> Stable(121-180)
%             % Place one label above first stable phase and one above first volatile phase
% 
%             % First stable phase - center at trial 30 (middle of 1-60)
%             text(axes1, 30, 1.05, 'Stable', ...
%                 'Color', [0 0.447058823529412 0.741176470588235], ...
%                 'FontWeight', 'bold', 'FontSize', 20, ...
%                 'HorizontalAlignment', 'center', 'HandleVisibility', 'off');
% 
%             % First volatile phase - center at trial 90 (middle of 61-120)
%             text(axes1, 90, 1.05, 'Volatile', ...
%                 'Color', [0.635294117647059 0.0784313725490196 0.184313725490196], ...
%                 'FontWeight', 'bold', 'FontSize', 20, ...
%                 'HorizontalAlignment', 'center', 'HandleVisibility', 'off');
%         end
% 
%     case {2, 3} % HGF Pilot and 5HT cohorts - TestTaskA structure
%         if iTask == 1
%             % Task structure: S(1-40) -> V(41-80) -> S(81-120) -> V(121-160) -> S(161-200) -> V(201-240) -> S(241-280)
%             % Place one label above first stable phase and one above first volatile phase
% 
%             % First stable phase - center at trial 20 (middle of 1-40)
%             text(axes1, 20, 1.05, 'Stable', ...
%                 'Color', [0 0.447058823529412 0.741176470588235], ...
%                 'FontWeight', 'bold', 'FontSize', 20, ...
%                 'HorizontalAlignment', 'center', 'HandleVisibility', 'off');
% 
%             % First volatile phase - center at trial 60 (middle of 41-80)
%             text(axes1, 60, 1.05, 'Volatile', ...
%                 'Color', [0.635294117647059 0.0784313725490196 0.184313725490196], ...
%                 'FontWeight', 'bold', 'FontSize', 20, ...
%                 'HorizontalAlignment', 'center', 'HandleVisibility', 'off');
%         end
% 
%     otherwise
%         return;
% end
% end
% 
% function [Y1, Y2] = getTaskInputSequence(cohortNo, iTask, optionsFile)
% % Get task-specific input sequence and probability structure
% 
% switch cohortNo
%     case 1 % UCMS cohort
%         Y1 = readmatrix(fullfile(optionsFile.paths.inputsDir, ...
%             optionsFile.cohort(cohortNo).name, ...
%             [optionsFile.cohort(cohortNo).taskPrefix, ...
%             optionsFile.cohort(cohortNo).testTask(iTask).name, '.txt']));
%         Y2 = [0.8*ones(1,60),0.5*ones(1,10),0.65*ones(1,5),0.3*ones(1,8),...
%             0.45*ones(1,12),0.75*ones(1,6),0.55*ones(1,11),0.25*ones(1,8),...
%             0.8*ones(1,60)];
% 
%     case 2 % HGF Pilot cohort
%         if iTask == 1 % TestTaskA
%             Y1 = readmatrix(fullfile(optionsFile.paths.inputsDir, ...
%                 optionsFile.cohort(cohortNo).name, ...
%                 [optionsFile.cohort(cohortNo).taskPrefix, ...
%                 optionsFile.cohort(cohortNo).testTask(iTask).name, '.txt']));
%             Y2 = [0.8*ones(1,40),0.3*ones(1,20),0.7*ones(1,20),...
%                 0.2*ones(1,40),0.7*ones(1,20),0.3*ones(1,20),...
%                 0.8*ones(1,40),0.3*ones(1,20),0.7*ones(1,20),...
%                 0.2*ones(1,40)];
%         else
%             % Default or other tasks
%             Y1 = optionsFile.cohort(cohortNo).testTask(iTask).inputs;
%             Y2 = ones(size(Y1)) * 0.5; % Default 50% probability
%         end
% 
%     case 3 % 5HT cohort
%         if iTask == 1 % TestTaskA (same structure as cohort 2)
%             Y1 = readmatrix(fullfile(optionsFile.paths.inputsDir, ...
%                 optionsFile.cohort(cohortNo).name, ...
%                 [optionsFile.cohort(cohortNo).taskPrefix, ...
%                 optionsFile.cohort(cohortNo).testTask(iTask).name, '.txt']));
%             Y2 = [0.8*ones(1,40),0.3*ones(1,20),0.7*ones(1,20),...
%                 0.2*ones(1,40),0.7*ones(1,20),0.3*ones(1,20),...
%                 0.8*ones(1,40),0.3*ones(1,20),0.7*ones(1,20),...
%                 0.2*ones(1,40)];
%         else
%             Y1 = optionsFile.cohort(cohortNo).testTask(iTask).inputs;
%             Y2 = ones(size(Y1)) * 0.5;
%         end
% 
%     otherwise
%         % Default case
%         Y1 = optionsFile.cohort(cohortNo).testTask(iTask).inputs;
%         Y2 = ones(size(Y1)) * 0.5;
% end