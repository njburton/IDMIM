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

for iTask = 1:nTasks
    for iAgent = 1:nSamples
        for m_in = 1:nModels
            modelIn = optionsFile.dataFiles.rawFitFile{m_in};
            simResp = load([optionsFile.paths.cohort(cohortNo).simulations,optionsFile.model.space{m_in},...
                '_',optionsFile.cohort(cohortNo).testTask(iTask).name,'_sim.mat']);
            for m_est = 1:nModels
                modelEst = optionsFile.dataFiles.rawFitFile{m_est};
                % load results from simulated agents' model inversion
                rec.sim.task(iTask).agent(m_in,iAgent,m_est).data = load(fullfile(optionsFile.paths.cohort(cohortNo).simulations, ...
                    ['simAgent_', num2str(iSample),'_',optionsFile.cohort(cohortNo).testTask(iTask).name,'_model_in_',optionsFile.dataFiles.rawFitFile{m_in},...
                    '_model_est_',optionsFile.dataFiles.rawFitFile{m_est},'.mat']));

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
    saveDir = fullfile([optionsFile.paths.cohort(cohortNo).groupSim,'Model_Identifiability _',...
            optionsFile.cohort(cohortNo).name,'_',optionsFile.cohort(cohortNo).testTask(iTask).name]);
    save(saveDir,'-struct','rec');

    if optionsFile.doCreatePlots
        %% PLOT MODEL IDENTIFIABILITY
        label_x = {optionsFile.model.names{1} optionsFile.model.names{2} optionsFile.model.names{3}};
        figure('color',[1 1 1],'name','model identifiability');

        numlabels = size(rec.class.percLMEwinner, 1); % number of labels

        % plot colors
        imagesc(rec.class.percLMEwinner);
        title(sprintf('Balanced Accuracy: %.2f%%', 100*trace(rec.class.LMEwinner)/sum(rec.class.LMEwinner(:))));
        ylabel('Output Class'); xlabel('Target Class');

        % set colormap
        colormap(flipud(gray));

        % Create strings from the matrix values and remove spaces
        textStrings = num2str([100*rec.class.percLMEwinner(:), rec.class.LMEwinner(:)], '%.1f%%\n%d\n');
        textStrings = strtrim(cellstr(textStrings));

        % Create x and y coordinates for the strings and plot them
        [x,y]       = meshgrid(1:numlabels);
        hStrings    = text(x(:),y(:),textStrings(:), 'HorizontalAlignment','center');

        % Get the middle value of the color range
        midValue    = mean(get(gca,'CLim'));

        % Choose white or black for the text color of the strings so they can be seen over the background color
        textColors  = repmat(rec.class.percLMEwinner(:) > midValue,1,3);
        set(hStrings,{'Color'},num2cell(textColors,2));

        % Setting the axis labels
        set(gca,'XTick',1:numlabels,...
            'XTickLabel',label_x,...
            'YTick',1:numlabels,...
            'YTickLabel',label_x,...
            'TickLength',[0 0]);

        figDir = fullfile([optionsFile.paths.cohort(cohortNo).groupSim,'Model_Identifiability _',...
            optionsFile.cohort(cohortNo).name,'_',optionsFile.cohort(cohortNo).testTask(iTask).name]);
        save([figDir,'.fig'])
        print(figDir, '-dpng');
    end % END TASK Loop
end
close all;

end