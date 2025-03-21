function plot_trajs(cohortNo)

if exist('optionsFile.mat','file')==2
    load("optionsFile.mat");
else
    optionsFile = runOptions();
end

 for iTask = 1:numel(optionsFile.cohort(cohortNo).testTask)
    for iSample = 1:optionsFile.simulations.nSamples
        for m_in = 1:numel(optionsFile.model.space)
            sim = load(fullfile([optionsFile.paths.cohort(cohortNo).simulations,optionsFile.model.space{m_in},'_',optionsFile.cohort(cohortNo).testTask(iTask).name,'_sim.mat']));
            
            for m_est = 1:numel(optionsFile.model.space)
try
              est =  load(fullfile(char(optionsFile.paths.cohort(cohortNo).simulations),...
                    ['simAgent_', num2str(iSample),'_model_in_',optionsFile.dataFiles.rawFitFile{m_in},...
                    '_model_est_',optionsFile.dataFiles.rawFitFile{m_est},'_binInputSeq_ABA_rightLever.mat']));
catch
    try
            est =  load(fullfile(char(optionsFile.paths.cohort(cohortNo).simulations),...
                    ['simAgent_', num2str(iSample),'_model_in_',optionsFile.dataFiles.rawFitFile{m_in},...
                    '_model_est_',optionsFile.dataFiles.rawFitFile{m_est},'_binInputSeq_ABA_rightLever.mat']));
    catch
        disp(['simAgent_', num2str(iSample),'_model_in_',optionsFile.dataFiles.rawFitFile{m_in},...
                    '_model_est_',optionsFile.dataFiles.rawFitFile{m_est},'_binInputSeq_ABA_rightLever.mat not found']);
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
