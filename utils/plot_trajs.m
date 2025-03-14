function plot_trajs(cohortNo)

if exist('optionsFile.mat','file')==2
    load("optionsFile.mat");
else
    optionsFile = runOptions();
end

 for iTask = 1:numel(optionsFile.cohort(cohortNo).testTask)
    for iSample = 2:optionsFile.simulations.nSamples
        for m_in = 1:numel(optionsFile.model.space)
            sim = load(fullfile([optionsFile.paths.cohort(cohortNo).simulations,optionsFile.model.space{m_in},optionsFile.cohort(cohortNo).testTask(iTask).name,'_sim']));
            
            for m_est = 1:numel(optionsFile.model.space)
try
              est =  load(fullfile(char(optionsFile.paths.cohort(cohortNo).simulations),...
                    [char(optionsFile.model.space{m_in}),'_simAgent_', num2str(iSample),'_model_in_',optionsFile.dataFiles.rawFitFile{m_in},...
                    '_model_est_',optionsFile.dataFiles.rawFitFile{m_est},'_task_',optionsFile.cohort(cohortNo).testTask(iTask).name,'.mat']));
catch
    try
            est =  load(fullfile(char(optionsFile.paths.cohort(cohortNo).simulations),...
                    ['simAgent_', num2str(iSample),'_model_in_',optionsFile.dataFiles.rawFitFile{m_in},...
                    '_model_est_',optionsFile.dataFiles.rawFitFile{m_est},'_',optionsFile.cohort(cohortNo).testTask(iTask).name,'.mat']));
    catch
        disp([char(optionsFile.model.space{m_in}),'_simAgent_', num2str(iSample),'_model_in_',optionsFile.dataFiles.rawFitFile{m_in},...
                    '_model_est_',optionsFile.dataFiles.rawFitFile{m_est},'_task_',optionsFile.cohort(cohortNo).testTask(iTask).name,'.mat not found'])
 continue
    end
    end
            %Plot standard trajectory plot
            optionsFile.plot(m_est).plot_fits(est);
            figdir = fullfile([char(optionsFile.paths.cohort(cohortNo).simPlots),...
                'simAgent_', num2str(iSample),'_model_in_',optionsFile.dataFiles.rawFitFile{m_in},...
                '_model_est_',optionsFile.dataFiles.rawFitFile{m_est},'_',optionsFile.cohort(cohortNo).testTask(iTask).name]);
            save([figdir,'.fig']);
            print([figdir,'.png'], '-dpng');
            close all;

                %% SAVE model fit as struct
                save_path = fullfile(char(optionsFile.paths.cohort(cohortNo).simulations),...
                    ['simAgent_', num2str(iSample),'_model_in_',optionsFile.dataFiles.rawFitFile{m_in},...
                    '_model_est_',optionsFile.dataFiles.rawFitFile{m_est},'_',optionsFile.cohort(cohortNo).testTask(iTask).name,'.mat']);
                save(save_path, '-struct', 'est');

            end
        end
    end
end
