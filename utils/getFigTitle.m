function figTitle = getFigTitle(optionsFile,cohortNo,subCohort,currCondition)

if numel(optionsFile.cohort(cohortNo).subCohorts)==0 && numel(optionsFile.cohort(cohortNo).conditions)==0
    figTitle = '';
elseif numel(optionsFile.cohort(cohortNo).subCohorts)==0 && numel(optionsFile.cohort(cohortNo).conditions)>0
    figTitle = ['_condition_',currCondition,'_'];

elseif numel(optionsFile.cohort(cohortNo).subCohorts)>0 && numel(optionsFile.cohort(cohortNo).conditions)==0
    figTitle = ['_',subCohort,'_'];
else
    figTitle = ['_',subCohort,'_condition_',currCondition,'_'];
end


end