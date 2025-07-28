function computeModelIdentifiability(cohortNo)

%% sim_data_modelinversion
%  Invert simulated agents with models in the modelspace. This step will be
%  executed if optionsFile.doSimulations = 1;
%
%   SYNTAX:       sim_data_modinversion
%
%   IN: cohortNo:  integer, cohort number, see optionsFile for what cohort
%                            corresponds to what number in the
%                            optionsFile.cohort(cohortNo).name struct. This
%                            allows to run the pipeline and its functions for different
%                            cohorts whose expcifications have been set in runOptions.m
%
% Original: 29-10-2021; Alex Hess
% Amended:  30-05-2025; Katharina V. Wellstein

% -------------------------------------------------------------------------
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
% _________________________________________________________________________
% =========================================================================

%% INITIALIZE options and variables needed to run this function

disp('************************************** INVERT SIMULATED RESPONSES **************************************');
disp('*');
disp('*');

% load or run options for running this function
if exist('optionsFile.mat','file')==2
    load('optionsFile.mat');
else
    optionsFile = runOptions();
end

% prespecify variables needed for running this function
nTasks   = numel(optionsFile.cohort(cohortNo).testTask);
nModels  = numel(optionsFile.model.space);
nSamples = optionsFile.simulations.nSamples;


%% LOAD simulated responses and inverted simulated responses
% and save simulated response data into rec.param.{}.simAgent struct and paramete values for recovery into
% rec.param.{}.estAgent. The data were simulated with all models in the
% model space and inverted with all the models in the model space. For
% model identifiability we are saving into the following structure: agent(m_in,iAgent,m_est)

for iTask = 1:1%nTasks
    for iAgent = 1:nSamples
        for m_in = 1:nModels
            modelIn = optionsFile.dataFiles.rawFitFile{m_in};
            for m_est = 1:nModels
                modelEst = optionsFile.dataFiles.rawFitFile{m_est};
                % load results from simulated agents' model inversion
                rec.sim.task(iTask).agent(m_in,iAgent,m_est).data = load(fullfile(optionsFile.paths.cohort(cohortNo).simulations, ...
                    ['simAgent_', num2str(iAgent),'_',optionsFile.cohort(cohortNo).testTask(iTask).name,'_model_in_', modelIn,...
                    '_model_est_',modelEst,'.mat']));

                % LME
                rec.task(iTask).model(m_in).LME(iAgent,m_est) = rec.sim.task(iTask).agent(m_in,iAgent,m_est).data.optim.LME;

            end % END ESTIMATING MODEL loop
        end % END GENERATING MODEL loop
    end % END AGENT loop
end % END TASK loop

%% LME Winner classification)

for iTask = 1:1%numel(optionsFile.cohort(cohortNo).testTask)
    class.LMEwinner = NaN(size(optionsFile.model.space, 2), size(optionsFile.model.space, 2));
    class.percLMEwinner = NaN(size(class.LMEwinner));

    for m = 1:size(optionsFile.model.space, 2)
        [class.max(m).val, class.max(m).idx] = max(rec.task(iTask).model(m).LME, [], 2);
        for i = 1:size(optionsFile.model.space, 2)
            class.LMEwinner(m,i) = sum(class.max(m).idx==i);
        end
        class.percLMEwinner(m,:) = class.LMEwinner(m,:)./optionsFile.simulations.nSamples;
        class.acc(m)             = class.percLMEwinner(m,m);     % accuracy
    end

    class.balacc = mean(class.acc); % balanced accuraccy

    % chance threshold (inv binomial distr)
    class.chancethr = binoinv(0.9, optionsFile.simulations.nSamples, 1/size(optionsFile.model.space, 2)) / optionsFile.simulations.nSamples;
    rec.class = class;

    % save to struct
    saveDir = fullfile([optionsFile.paths.cohort(cohortNo).groupSim,optionsFile.cohort(cohortNo).taskPrefix,...
        optionsFile.cohort(cohortNo).name,'_Model_Identifiability_',optionsFile.cohort(cohortNo).testTask(iTask).name]);
    save(saveDir,'-struct','rec');

    if optionsFile.doCreatePlots
        %% PLOT MODEL IDENTIFIABILITY with consistent styling
        % Create a mapping for model name modifications
        % Add more mappings as needed in the future:
        % nameMapping('Your New Model Name') = 'Desired Display Name';
        nameMapping = containers.Map();
        nameMapping('eHGF 3-level') = '3-level eHGF';
        nameMapping('eHGF 2-level') = '2-level eHGF';

        % Apply the mapping
        label_x = cell(1, length(optionsFile.model.names));
        for i = 1:length(optionsFile.model.names)
            originalName = optionsFile.model.names{i};
            if isKey(nameMapping, originalName)
                label_x{i} = nameMapping(originalName);
            else
                label_x{i} = originalName; % Keep original if no mapping exists
            end
        end
        % Create figure with consistent positioning
        pos0 = get(0,'screenSize');
        pos = [1,pos0(4)/2,pos0(3)/1.2,pos0(4)/1.2];
        figure('WindowState','maximized','Name','Model Identifiability','Color',[1 1 1],'Position',pos);

        numlabels = size(rec.class.percLMEwinner, 1); % number of labels

        % Create the heatmap
        imagesc(rec.class.percLMEwinner);

        % Set color limits to ensure full 0-1 range
        caxis([0 1]);

        % Set title and labels with Arial font
        title(sprintf('Balanced Accuracy: %.2f%%', 100*trace(rec.class.LMEwinner)/sum(rec.class.LMEwinner(:))), ...
            'FontSize', 18, 'FontName', 'Arial');
        ylabel('Output Class', 'FontSize', 14, 'FontName', 'Arial');
        xlabel('Target Class', 'FontSize', 14, 'FontName', 'Arial');

        % Set colormap using ColorBrewer's Red-Blue diverging map
        colormap(flipud(gray))

        % Set colorbar with proper tick marks
        cb = colorbar('FontSize', 20, 'FontName', 'Arial');

        % Set colorbar ticks to include 0 and 1
        cb.Ticks = [0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0];
        cb.TickLabels = {'0', '0.1', '0.2', '0.3', '0.4', '0.5', '0.6', '0.7', '0.8', '0.9', '1.0'};

        % Create strings from the matrix values and remove spaces
        textStrings = num2str([100*rec.class.percLMEwinner(:), rec.class.LMEwinner(:)], '%.1f%%\n%d\n');
        textStrings = strtrim(cellstr(textStrings));

        % Create x and y coordinates for the strings and plot them
        [x,y] = meshgrid(1:numlabels);
        hStrings = text(x(:),y(:),textStrings(:), 'HorizontalAlignment','center', ...
            'FontSize', 20, 'FontName', 'Arial');

        % Get the color limits and create better contrast for text
        cLimits = get(gca,'CLim');
        cRange = cLimits(2) - cLimits(1);

        % Define thresholds for better text contrast with grayscale colormap
        textColors = zeros(numel(rec.class.percLMEwinner(:)), 3);

        for i = 1:numel(rec.class.percLMEwinner(:))
            value = rec.class.percLMEwinner(i);

            % Use white text only for the darkest areas
            if value > 0.7  % Only the darkest 30% get white text
                textColors(i,:) = [1 1 1]; % White text
            else  % Everything else gets black text
                textColors(i,:) = [0 0 0]; % Black text
            end
        end

        set(hStrings,{'Color'},num2cell(textColors,2));

        % Setting the axis labels and formatting
        set(gca,'XTick',1:numlabels,...
            'XTickLabel',label_x,...
            'YTick',1:numlabels,...
            'YTickLabel',label_x,...
            'TickLength',[0 0],...
            'FontSize', 22, ...
            'FontName', 'Arial', ...
            'box', 'off');

        % Set grid properties to match BMS style
        set(gca, 'GridLineStyle', ':', ...
            'GridAlpha', 0.2, ...
            'color', 'none');

        % Make figure background transparent
        set(gcf, 'color', 'white');

        % Save figure
        figDir = fullfile([optionsFile.paths.cohort(cohortNo).groupSim,optionsFile.cohort(cohortNo).taskPrefix,...
            optionsFile.cohort(cohortNo).name,'_Model_Identifiability_',optionsFile.cohort(cohortNo).testTask(iTask).name]);

        % Save as .fig and .png
        savefig([figDir,'.fig']);
        print(figDir, '-dpng');

        % Close the current figure
        close(gcf);
    end % END TASK Loop
end
% Close any remaining figures
%close all;
disp(['*** Bayesian Model Identifiability of ',char(optionsFile.cohort(cohortNo).name), ' complete and plot successfully saved to ', figDir]);


end