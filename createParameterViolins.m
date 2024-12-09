function createParameterViolins(data, saveDir)
tic

% Define parameter groups
HGF3_params = {'HGF3_zeta', 'HGF3_wt', 'HGF3_omega2', 'HGF3_omega3', ...
    'HGF3_sahat1', 'HGF3_sahat2', 'HGF3_sahat3', ...
    'HGF3_epsi2', 'HGF3_epsi3'};

HGF2_params = {'HGF2_zeta', 'HGF2_wt', 'HGF2_omega2', ...
    'HGF2_sahat1', 'HGF2_sahat2', 'HGF2_sahat3', ...
    'HGF2_epsi2', 'HGF2_epsi3'};

RW_params = {'RW_zeta', 'RW_alpha'};

all_model_params = {HGF3_params, HGF2_params, RW_params};
model_names = {'HGF3', 'HGF2', 'RW'};

% Create save directory if it doesn't exist
if ~exist(saveDir, 'dir')
    mkdir(saveDir);
    fprintf('Created directory: %s\n', saveDir);
end

% Filter out mice with high omissions
validMice = data.omissions <= 56;
data = data(validMice, :);

% Get unique values for each condition
tasks = unique(data.Task);
repetitions = unique(data.TaskRepetition);

% Process each model
for m = 1:length(all_model_params)
    current_model_params = all_model_params{m};
    model_name = model_names{m};

    % Process each parameter
    for p = 1:length(current_model_params)
        param_name = current_model_params{p};

        % Process each task and repetition
        for t = 1:length(tasks)
            currentTask = tasks(t);

            for r = 1:length(repetitions)
                currentRep = repetitions(r);

                % Get data for current task and repetition
                taskData = data(strcmp(data.Task, currentTask) & ...
                    abs(data.TaskRepetition - currentRep) < 1e-10, :);

                % Only proceed if there's any data
                if ~isempty(taskData)
                    % Print diagnostic information
                    fprintf('\nAnalyzing %s - %s - Repetition %.1f:\n', ...
                        model_name, param_name, currentRep);
                    fprintf('Total mice: %d\n', height(taskData));
                    fprintf('Sex distribution:\n');
                    disp(tabulate(taskData.Sex));

                    % Create figure
                    fig = figure('Name', sprintf('%s_%s - %s - Repetition %.1f', ...
                        model_name, param_name, currentTask, currentRep), ...
                        'Position', [100 100 1200 800]);

                    % First subplot - All mice
                    subplot(1,2,1)
                    boxplot(taskData.(param_name));
                    title(sprintf('All Mice (n=%d)', height(taskData)));
                    ylabel(strrep(param_name, '_', ' '));
                    hold on;
                    scatter(ones(size(taskData.(param_name))) + rand(size(taskData.(param_name)))*0.1 - 0.05, ...
                        taskData.(param_name), 50, 'k', 'filled', 'MarkerFaceAlpha', 0.6);
                    hold off;

                    % Second subplot - By sex
                    subplot(1,2,2)
                    % Get male and female data
                    maleData = taskData.(param_name)(strcmp(taskData.Sex, 'Male'));
                    femaleData = taskData.(param_name)(strcmp(taskData.Sex, 'Female'));

                    % Initialize the plot
                    hold on;

                    % Set up the axis
                    if ~isempty(maleData) || ~isempty(femaleData)
                        allValues = [maleData; femaleData];
                        ymin = min(allValues) - 0.1 * (max(allValues) - min(allValues));
                        ymax = max(allValues) + 0.1 * (max(allValues) - min(allValues));
                        ylim([ymin ymax]);
                        xlim([0.5 2.5]);
                    end

                    % Plot male data if available
                    if ~isempty(maleData)
                        boxplot(maleData, 'Positions', 1, 'Labels', {'Male'}, 'Colors', 'b');
                        scatter(ones(size(maleData)) + rand(size(maleData))*0.1 - 0.05, ...
                            maleData, 50, 'b', 'filled', 'MarkerFaceAlpha', 0.6);
                    end

                    % Plot female data if available
                    if ~isempty(femaleData)
                        boxplot(femaleData, 'Positions', 2, 'Labels', {'Female'}, 'Colors', 'r');
                        scatter(2*ones(size(femaleData)) + rand(size(femaleData))*0.1 - 0.05, ...
                            femaleData, 50, 'r', 'filled', 'MarkerFaceAlpha', 0.6);
                    end

                    % Add labels and title
                    title(sprintf('By Sex (M:%d, F:%d)', length(maleData), length(femaleData)));
                    ylabel(strrep(param_name, '_', ' '));
                    xlabel('Sex');

                    % Set x-axis ticks
                    set(gca, 'XTick', [1 2], 'XTickLabel', {'Male', 'Female'});

                    hold off;

                    % Add overall title
                    sgtitle(sprintf('%s - %s\n%s - Repetition %.1f (n=%d)', ...
                        model_name, param_name, currentTask, currentRep, height(taskData)));

                    % Adjust figure properties
                    set(gcf, 'Color', 'w');

                    % Create filename and save the figure
                    filename = sprintf('%s_%s_%s_Rep%.1f.png', ...
                        model_name, strrep(param_name, ' ', '_'), ...
                        strrep(currentTask, ' ', '_'), currentRep);
                    saveas(fig, fullfile(saveDir, filename), 'png');
                    fprintf('Saved figure: %s\n', filename);

                    % Close the figure to free up memory
                    close(fig);
                end
            end
        end
    end
end
toc
end