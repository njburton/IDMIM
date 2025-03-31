function saveName = getSaveName(optionsFile,cohortNo,subCohort,currCondition,currRepetition)

if numel(optionsFile.cohort(cohortNo).subCohorts)==0 && numel(optionsFile.cohort(cohortNo).conditions)==0
    saveName = '_';

elseif strcmp(subCohort,'all')
    saveName = '_';

elseif numel(optionsFile.cohort(cohortNo).subCohorts)==0 && numel(optionsFile.cohort(cohortNo).conditions)>0
    saveName = ['_condition_',currCondition,'_'];

elseif numel(optionsFile.cohort(cohortNo).subCohorts)>0 && numel(optionsFile.cohort(cohortNo).conditions)==0
    saveName = ['_',subCohort,'_'];
else
    saveName = ['_',subCohort,'_condition_',currCondition,'_'];
end


end