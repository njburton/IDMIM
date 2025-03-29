function computeModelIdentifiability(cohortNo)

%% INITIALIZE Variables for running this function
% specifications for this analysis
if exist('optionsFile.mat','file')==2
    load('optionsFile.mat');
else
    optionsFile = runOptions();
end

%% LOAD simulated responses and inverted simulated responses
% and save simulated response data into rec.param.{}.simAgent struct and paramete values for recovery into
% rec.param.{}.estAgent. The data were simulated with all models in the
% model space and inverted with all the models in the model space. For
% model identifiability we are saving into the following structure: agent(m_in,iAgent,m_est)

for iTask = 1:1%numel(optionsFile.cohort(cohortNo).testTask)
    for iAgent = 1:optionsFile.simulations.nSamples
        for m_in = 1:numel(optionsFile.model.space)
            modelIn = optionsFile.dataFiles.rawFitFile{m_in};
            simResp = load([optionsFile.paths.cohort(cohortNo).simulations,optionsFile.model.space{m_in},...
                '_',optionsFile.cohort(cohortNo).testTask(iTask).name,'_sim.mat']);

            for m_est = 1:numel(optionsFile.model.space)
                modelEst = optionsFile.dataFiles.rawFitFile{m_est};
                % load results from simulated agents' model inversion
                rec.sim.task(iTask).agent(m_in,iAgent,m_est).data = load(fullfile(optionsFile.paths.cohort(cohortNo).simulations, ...
                    ['simAgent_', num2str(iAgent),'_model_in_',modelIn,'_model_est_',modelEst,...
                    '_',optionsFile.cohort(cohortNo).testTask(iTask).name,'.mat']));

                % LME
                rec.task(iTask).model(m_in).LME(iAgent,m_est) = rec.sim.task(iTask).agent(m_in,iAgent,m_est).data.optim.LME;
            end
        end
    end
end

%% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %%
%% MODEL IDENTIFIABILITY (LME Winner classification)

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

    % save to struct
    rec.class = class;

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
end

close all;

end