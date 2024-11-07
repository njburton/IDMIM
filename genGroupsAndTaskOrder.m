function optionsFile = genGroupsAndTaskOrder(optionsFile)

load("optionsFile.mat") % load file paths

% search through MatFiles
dirFiles = dir(fullfile(optionsFile.paths.mouseMatFilesDir,'*.mat'));
allFilenames = {dirFiles.name}';

tableVarTypes = {'string','string','string','string','single','string','string'};
tableVarNames = {'MouseID','TaskDate','TaskPath','Task','TaskOrder','sex','group'};
groupTable    = table('Size',[length(allFilenames) length(tableVarNames)],...
    'VariableTypes', tableVarTypes,...
    'VariableNames',tableVarNames);

% fill table from fileNames
for filei = 1:length(allFilenames)
    groupTable.MouseID(filei)  = extractBetween(allFilenames(filei),'mouse','_NJB_HGF');
    groupTable.TaskDate(filei) = extractBetween(allFilenames(filei),'date','.mat');
    groupTable.Task(filei)     = extractBetween(allFilenames(filei),'HGF_','_date');
    groupTable.TaskPath(filei) = char(fullfile(optionsFile.paths.mouseMatFilesDir,allFilenames(filei)));
end

% loop to adjust dates so they are in the followng format: DD:MM:YY
for dateCheck = 1:length(allFilenames)
    if contains(groupTable.TaskDate(dateCheck),'2024') == 1
        groupTable.TaskDate(dateCheck) = extractBetween(groupTable.TaskPath(dateCheck),"date",".mat");
    else
        oldDayAndMonth = extractBefore(groupTable.TaskDate(dateCheck),'-24');
        oldMonth       = extractBefore(oldDayAndMonth,'-');
        oldDay         = extractAfter(oldDayAndMonth,'-');
        newDateFormat  = append('2024-',oldMonth,'-',oldDay);
        groupTable.TaskDate(dateCheck) = newDateFormat;
    end % end of check for dates containing 2024
end %end of loop to modify dates

%% loop to fill groupTable.TaskOrder
groupTableSorted = sortrows(groupTable,"TaskDate","ascend");
mouseIDList = unique(groupTableSorted.MouseID);
startPoint = 0;
for taski = 1:length(optionsFile.task.taskList)
    currTask = erase(optionsFile.task.taskList(taski),'NJB_HGF_');
    for mousei = 1:length(mouseIDList)
        currMouse = mouseIDList(mousei);
        for rowi = 1:length(allFilenames)
            if strcmp(currMouse, groupTableSorted.MouseID(rowi)) && ...
                    strcmp(currTask,groupTableSorted.Task(rowi)) == 1
                startPoint = startPoint + 1;
                groupTableSorted.TaskOrder(rowi) = startPoint;
            else
                continue
            end
        end
        startPoint = 0;
    end
end

%% Fill in sex and group columns
for rowi = 1:length(groupTableSorted.sex)
    if sum(strcmp(groupTableSorted.MouseID(rowi),optionsFile.cohort.maleMice)) >= 1
        groupTableSorted.sex(rowi) = "Male";
    else
        groupTableSorted.sex(rowi) = "Female";
    end
end

%% Fill in group columns
for rowi = 1:length(groupTableSorted.sex)
    if sum(strcmp(groupTableSorted.MouseID(rowi),optionsFile.cohort.controlGroup)) >= 1
        groupTableSorted.group(rowi) = "Control";
    else
        groupTableSorted.group(rowi) = "Treatment";
    end
end

%% save file
savePathAndName = [char(optionsFile.paths.databaseDir),filesep,...
    'toProcessWithPipeline_allFilesWithTaskOrder.mat'];
save(savePathAndName,'groupTableSorted'); %save

end