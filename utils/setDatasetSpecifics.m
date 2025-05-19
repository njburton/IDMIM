function optionsFile = setDatasetSpecifics(optionsFile)


%% SPECIFY COHORT DATASET info
% Each group represents an individual experiment/cohort

%% 'UCMS' COHORT
optionsFile.cohort(1).name = '2023_UCMS';
% Identify which mouseIDs are male, female and their experimental group
optionsFile.cohort(1).treatment.maleMice   = {'372','382','392','402','412','422'};
optionsFile.cohort(1).treatment.femaleMice = {'432','442','452','462','472','482'};
optionsFile.cohort(1).control.maleMice     = {'369','370','374','375','215','217'};
optionsFile.cohort(1).control.femaleMice   = {'411','426','433','434','501','506'};
optionsFile.cohort(1).conditions           = [];
optionsFile.cohort(1).subCohorts           = {'treatment','control'};
optionsFile.cohort(1).taskRepetitions      = 1;
optionsFile.cohort(1).priorsFromCohort     = [];
optionsFile.cohort(1).priorsFromTask       = [];
optionsFile.cohort(1).priorsFromCondition  = [];
optionsFile.cohort(1).priorsFromRepetition = [];
optionsFile.cohort(1).priorsFromSubCohort  = [];
optionsFile.cohort(1).taskPrefix          = 'NJB_HGF_';
optionsFile.cohort(1).trainTask(1).name   = []; % 
optionsFile.cohort(1).testTask(1).name    = 'ABA2_R';
% optionsFile.cohort(1).testTask(2).name  = 'ABA1_L';
optionsFile.cohort(1).nTrials             = 180;  % trials
optionsFile.cohort(1).trialDuration       = 20;   % in seconds
optionsFile.cohort(1).totalTaskDuration   = optionsFile.cohort(1).nTrials*optionsFile.cohort(1).trialDuration; % in seconds
optionsFile.cohort(1).exclCriteria(1).name   = 'nOmissions';
optionsFile.cohort(1).exclCriteria(1).cutoff = 0.3;
optionsFile.cohort(1).exclCriteria(2).name   = 'nConsecutiveOmissions';
optionsFile.cohort(1).exclCriteria(2).cutoff = 30;

%% '2024_HGF' COHORT
optionsFile.cohort(2).name = '2024_HGFPilot';
optionsFile.cohort(2).treatment.maleMice   = [];
optionsFile.cohort(2).treatment.femaleMice = [];
optionsFile.cohort(2).control.maleMice     = {'1.1','1.2','2.1','3.1','3.2','3.3'};
optionsFile.cohort(2).control.femaleMice   = {'4.2','5.1','5.2','5.3','5.4','5.5'};
optionsFile.cohort(2).conditions           = [];
optionsFile.cohort(2).subCohorts           = [];
optionsFile.cohort(2).taskRepetitions  = 3;
optionsFile.cohort(2).priorsFromCohort = [];
optionsFile.cohort(2).priorsFromTask   = [];
optionsFile.cohort(2).priorsFromCondition = [];
optionsFile.cohort(1).priorsFromRepetition = [];
optionsFile.cohort(1).priorsFromSubCohort  = [];
optionsFile.cohort(2).taskPrefix        = 'NJB_HGF_';
optionsFile.cohort(2).trainTask(1).name = 'TrainingTask_RL';
optionsFile.cohort(2).trainTask(2).name = 'TrainingTask_LL - Copy';
optionsFile.cohort(2).testTask(1).name  = 'TestTaskA';
% optionsFile.cohort(2).testTask(2).name  = 'TestTaskB';
optionsFile.cohort(2).nTrials           = 280;  % total task trials
optionsFile.cohort(2).trialDuration     = 13;   % in seconds
optionsFile.cohort(2).totalTaskDuration = optionsFile.cohort(2).nTrials*optionsFile.cohort(2).trialDuration; % in seconds
optionsFile.cohort(2).exclCriteria(1).name   = 'nOmissions';
optionsFile.cohort(2).exclCriteria(1).cutoff = 0.3;
optionsFile.cohort(2).exclCriteria(2).name   = 'nConsecutiveOmissions';
optionsFile.cohort(2).exclCriteria(2).cutoff = 30;

%% '5HT' COHORT
optionsFile.cohort(3).name = '5HT';
optionsFile.cohort(3).treatment.maleMice   = {'1.1','1.2','1.3','1.4','2.1','2.2','2.3','2.4','3.1','3.2','3.3','3.4'};
optionsFile.cohort(3).treatment.femaleMice = {'4.1','4.2','4.3','4.4','5.1','5.2','5.3','5.4','6.1','6.2','6.3','6.4'};
optionsFile.cohort(3).control.maleMice     = [];
optionsFile.cohort(3).control.femaleMice   = [];
optionsFile.cohort(3).conditions           = {'5mg','10mg','saline'};
optionsFile.cohort(3).subCohorts           = [];
optionsFile.cohort(3).taskRepetitions      = 1; % because only 1 task per condition
optionsFile.cohort(3).priorsFromCohort     = 2;
optionsFile.cohort(3).priorsFromTask       = 1;
optionsFile.cohort(3).priorsFromCondition  = [];
optionsFile.cohort(3).priorsFromRepetition = 1;
optionsFile.cohort(3).priorsFromSubCohort  = [];
optionsFile.cohort(3).taskPrefix        = 'NJB_HGF_';
optionsFile.cohort(3).trainTask(1).name = 'TrainingTask_RL';
optionsFile.cohort(3).trainTask(2).name = 'TrainingTask_LL';
optionsFile.cohort(3).testTask(1).name  = 'TestTaskA';
optionsFile.cohort(3).nTrials           = 280;   % total task trials
optionsFile.cohort(3).trialDuration     = 13;   % in seconds
optionsFile.cohort(3).totalTaskDuration = optionsFile.cohort(3).nTrials*optionsFile.cohort(3).trialDuration; % in seconds
optionsFile.cohort(3).exclCriteria(1).name = 'nOmissions';
optionsFile.cohort(3).exclCriteria(1).cutoff = 0.3;
optionsFile.cohort(3).exclCriteria(2).name = 'nConsecutiveOmissions';
optionsFile.cohort(3).exclCriteria(2).cutoff = 30;

for cohortNo = 1:numel(optionsFile.cohort)
    % collate mouseIDs
    optionsFile.cohort(cohortNo).mouseIDs = [optionsFile.cohort(cohortNo).treatment.maleMice, optionsFile.cohort(cohortNo).treatment.femaleMice,...
        optionsFile.cohort(cohortNo).control.maleMice, optionsFile.cohort(cohortNo).control.femaleMice];
    % sample sizes
    optionsFile.cohort(cohortNo).nSize = numel(optionsFile.cohort(cohortNo).mouseIDs);
end

end