function [mouseIDs,nSize] = getSampleSpecs(optionsFile,cohortNo,subCohort)

% choose what mouseID array to use for this function

% if this cohort does not contain more than one subcohort (i.e. only
% controls or only a treatment group) use all mouseIDs
if isempty(subCohort)
    mouseIDs      = optionsFile.cohort(cohortNo).mouseIDs;
    nSize         = optionsFile.cohort(cohortNo).nSize;
    
    % if this cohort contains more than one subcohort (i.e. a control and
    % a treatment group) use all mouseIDs AND you want to run all mice in
    % this function use all mouseIDs
elseif strcmp(subCohort,'all')
    mouseIDs    = optionsFile.cohort(cohortNo).mouseIDs;
    nSize       = optionsFile.cohort(cohortNo).nSize;

    % if this cohort contains more than one subcohort (i.e. a control and
    % a treatment group) use all mouseIDs AND you want to run ONLY one of the two 
    % subcohorts in this function use only the subcohort's mouseIDs
elseif ~isempty(subCohort)
    mouseIDs    = [optionsFile.cohort(cohortNo).(subCohort).maleMice,...
        optionsFile.cohort(cohortNo).(subCohort).femaleMice];
    nSize       = numel(mouseIDs);
end