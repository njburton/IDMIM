function ExperimentTaskTable = populateTaskTable(ExperimentTaskTable, taskName, taskDate, dataFile, startIdx, optionsFile, trialStartTimes)
% Helper function to populate the experiment task table
load("optionsFile.mat");

ExperimentTaskTable.Task(:) = taskName;
ExperimentTaskTable.TaskDate(:) = taskDate;
ExperimentTaskTable.TrialStartTime = trialStartTimes;

% Load binary input sequence - corrected path structure
try  
    binSeqPath = fullfile(char(optionsFile.paths.binInputSeqDir), '2024_HGFPilot3',...
        ['*',char(erase(taskName,optionsFile.task.taskPrefix)),...
        '*_RightLeverList.txt']);
    % Add error checking for file existence
    if ~exist(binSeqPath, 'file')
        error('Binary input sequence file not found: %s', binSeqPath);
    end
    binInputSeq = rows2vars(readtable(binSeqPath));
    ExperimentTaskTable.RewardingLeverSide = binInputSeq.Var1;
catch ME
    error('Error loading binary input sequence: %s', ME.message);
end

% Extract experimental data
if isa(dataFile, 'table')
    % Large file handling
    dataOffset = startIdx + optionsFile.dataFile.outcomeOffset;
    ExperimentTaskTable.Outcome = str2double(dataFile.Var2(dataOffset+1:dataOffset+optionsFile.task.nTrials));
    ExperimentTaskTable.Choice = str2double(dataFile.Var2(startIdx+optionsFile.dataFile.choiceOffset+1:startIdx+optionsFile.dataFile.choiceOffset+optionsFile.task.nTrials));
    ExperimentTaskTable.LeverPressTime = str2double(dataFile.Var2(startIdx+optionsFile.dataFile.leverPressTimeOffset+1:startIdx+optionsFile.dataFile.leverPressTimeOffset+optionsFile.task.nTrials));
    ExperimentTaskTable.Chamber(:) = str2double(dataFile.Var2(startIdx-3));
else
    % Regular file handling
    ExperimentTaskTable.Outcome = cell2mat(dataFile(optionsFile.dataFile.outcomeOffset+11:optionsFile.dataFile.outcomeOffset+10+optionsFile.task.nTrials,2));
    ExperimentTaskTable.Choice = cell2mat(dataFile(optionsFile.dataFile.choiceOffset+11:optionsFile.dataFile.choiceOffset+10+optionsFile.task.nTrials,2));
    ExperimentTaskTable.LeverPressTime = cell2mat(dataFile(optionsFile.dataFile.leverPressTimeOffset+11:optionsFile.dataFile.leverPressTimeOffset+10+optionsFile.task.nTrials,2));
    ExperimentTaskTable.Chamber(:) = cell2mat(dataFile(7,2));
end

% Calculate response time
ExperimentTaskTable.ResponseTime = ExperimentTaskTable.LeverPressTime - ExperimentTaskTable.TrialStartTime;

% Clean data
invalidChoice = ExperimentTaskTable.Choice == 3;
ExperimentTaskTable.Outcome(invalidChoice) = NaN;
ExperimentTaskTable.LeverPressTime(invalidChoice) = NaN;
ExperimentTaskTable.Choice(invalidChoice) = NaN;
ExperimentTaskTable.ResponseTime(ExperimentTaskTable.ResponseTime <= 0.0) = NaN;
end