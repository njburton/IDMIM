
load('optionsFile.mat');
cohortNo = 2;
% prespecify variables needed for running this function
nTasks   = numel(optionsFile.cohort(cohortNo).testTask);
nModels  = numel(optionsFile.model.space);
nSamples = optionsFile.simulations.nSamples;


for iTask = 1:nTasks
    for iAgent = 1:nSamples
        for m_in = 1:nModels
            for m_est = 1:nModels
                oldName = [char(optionsFile.paths.cohort(cohortNo).simulations),...
                    'simAgent_', num2str(iAgent),'_model_in_',optionsFile.dataFiles.rawFitFile{m_in},...
                    '_model_est_',optionsFile.dataFiles.rawFitFile{m_est},'_',optionsFile.cohort(cohortNo).testTask(iTask).name,'.mat'];
                newName = [char(optionsFile.paths.cohort(cohortNo).simulations),...
                    'simAgent_', num2str(iAgent),'_',optionsFile.cohort(cohortNo).testTask(iTask).name,'_model_in_',optionsFile.dataFiles.rawFitFile{m_in},...
                    '_model_est_',optionsFile.dataFiles.rawFitFile{m_est},'.mat'];
                movefile(oldName,newName);
            end % END ESTIMATING MODEL loop
        end % END GENERATING MODEL loop
    end % END AGENT loop
end % END TASK loop