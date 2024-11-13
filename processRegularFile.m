function processRegularFile(fileInfo, optionsFile, ExperimentTaskTable, trialStartTimes)
% Helper function to process regular-sized MED-PC files
load("optionsFile.mat");

fileName = string(fileInfo.name);
regMEDPCFile = readcell(fullfile(optionsFile.paths.dataToAnalyse, fileName));

if ~contains(regMEDPCFile(10,2), optionsFile.task.taskList)
    return;
end

% Extract metadata
currMouse = num2str(cell2mat(regMEDPCFile(4,2)));
currTaskDate = extractBetween(fileName, 1, 10);
currTask = regMEDPCFile(10,2);

% Populate table
ExperimentTaskTable = populateTaskTable(ExperimentTaskTable, currTask, ...
    currTaskDate, regMEDPCFile, 10, optionsFile, trialStartTimes);

% Verify and save
saveProcessedData(ExperimentTaskTable, optionsFile, currMouse, currTask, currTaskDate);
end