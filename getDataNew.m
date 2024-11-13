function optionsFile = getDataNew(optionsFile)
%% getData - Process and extract experimental task data from MED-PC files
%
% SYNTAX:  getData(optionsFile)
% INPUT:   optionsFile - Structure containing analysis options and paths
% OUTPUT:  optionsFile - Updated structure after data processing
%
% Authors: Katharina Wellstein (30/5/2023), Nicholas Burton (23/2/2024)
% -------------------------------------------------------------------------

tic

% Constants
LARGE_FILE_THRESHOLD = 500000;
TASK_TABLE_SPEC = {...
    'Task',                'string';
    'TaskDate',            'string';
    'RewardingLeverSide',  'double';
    'Choice',              'double';
    'Outcome',             'double';
    'TrialStartTime',      'double';
    'LeverPressTime',      'double';
    'ResponseTime',        'double';
    'RecepticalBeamBreak', 'single';
    'Chamber',             'double'};

% Load options
load("optionsFile.mat");

% Initialise task table using table spec
ExperimentTaskTable = table('Size', [optionsFile.task.nTrials, size(TASK_TABLE_SPEC, 1)], ...
    'VariableTypes', TASK_TABLE_SPEC(:,2)', ...
    'VariableNames', TASK_TABLE_SPEC(:,1)');

% Get list of files to process
allFiles = dir(fullfile(optionsFile.paths.dataToAnalyse, '*.*'));
allFiles = allFiles(~[allFiles.isdir]); % Remove non-directories )i.e., ".")

% Identify large files
isLargeFile = [allFiles.bytes] >= LARGE_FILE_THRESHOLD;
if any(isLargeFile)
    disp('Large (>500,000 bytes) MED-PC file(s) found.');
else
    disp('No large files detected.');
end

% Validate task list
taskSearchList = optionsFile.task.taskList;
assert(~isempty(taskSearchList), 'Task search list is empty. Check optionsFiles task list has at least 1 entry.');

% Pre-calculate trial start times once
trialStartTimes = transpose(0:optionsFile.task.trialDuration:(optionsFile.task.totalTaskDuration-13));

%% Process large files
for iFile = find(isLargeFile)'
    processLargeFile(allFiles(iFile), taskSearchList, optionsFile, ExperimentTaskTable, trialStartTimes);
end

%% Process regular files
for iFile = find(~isLargeFile)'
    processRegularFile(allFiles(iFile), optionsFile, ExperimentTaskTable, trialStartTimes);
end

% Clean up MouseID array
optionsFile.task.MouseID = optionsFile.task.MouseID(~isnan(optionsFile.task.MouseID));
optionsFile.cohort.nSize = length(optionsFile.task.MouseID);

toc
end