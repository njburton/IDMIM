function processLargeFile(fileInfo, taskSearchList, optionsFile, ExperimentTaskTable, trialStartTimes)
% Helper function to process large MED-PC files
% fileInfo is a struct array containing information about multiple files
load("optionsFile.mat");

% Process each large file
for iLargeFile = 1:length(fileInfo)
    % Get current filename as string
    currentFileName = string(fileInfo(iLargeFile).name);
    
    % Read the current large file
    try
        largeMEDPCFile = readtable(fullfile(optionsFile.paths.dataToAnalyse, currentFileName));
    catch ME
        warning('Failed to read file %s: %s', char(currentFileName), ME.message);
        continue;
    end
    
    % Process each task in the search list
    for iTask = 1:length(taskSearchList)
        % Convert cell array element to string for contains() function
        currentTask = taskSearchList{iTask};
        startIndices = find(contains(largeMEDPCFile.Var2, currentTask));
        
        % Skip if no instances of this task found in file
        if isempty(startIndices)
            continue;
        end
        
        % Process each instance of the task found in the file
        for iStart = 1:length(startIndices)
            try
                % Extract metadata
                startIdx = startIndices(iStart);
                currMouse = cell2mat(largeMEDPCFile.Var2(startIdx-6));
                currTaskDate = replace(cell2mat(largeMEDPCFile.Var2(startIdx-8)), '/', '-');
                
                % Populate table
                ExperimentTaskTable = populateTaskTable(ExperimentTaskTable, currentTask, ...
                    currTaskDate, largeMEDPCFile, startIdx, optionsFile, trialStartTimes);
                
                % Verify and save
                saveProcessedData(ExperimentTaskTable, optionsFile, currMouse, currentTask, currTaskDate);
            catch ME
                warning('Error processing task %s in file %s at index %d: %s', ...
                    char(currentTask), char(currentFileName), iStart, ME.message);
                continue;
            end
        end
    end
end
end