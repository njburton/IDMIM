%plot distribution of responsetimes
tic
load("optionsFile.mat"); % specifications for this analysis
if isfile(char(fullfile(optionsFile.paths.databaseDir, optionsFile.fileName.dataBaseFileName))) == 1
    load(char(fullfile(optionsFile.paths.databaseDir, optionsFile.fileName.dataBaseFileName)));
else; error('No file found: Check directory for data base file containing dataset info')
end

groupTable = groupTableSorted;

%% initialise empty arrays for logging individual mouse data
omissionArray         = zeros(length(groupTable.MouseID),optionsFile.task.nTrials);
longResponseTimeArray = zeros(length(groupTable.MouseID),optionsFile.task.nTrials);
maxRewardsArray       = zeros(length(groupTable.MouseID),1);

% save currMouse responseTimes and choices to appropriate arrays
for rowi = 1:length(groupTable.MouseID)
    currData                      = load(groupTable.TaskPath(rowi));
    omissionArray(rowi,:)         = currData.ExperimentTaskTable.Choice;
    longResponseTimeArray(rowi,:) = currData.ExperimentTaskTable.ResponseTime;
end
longResponseTimeArray(longResponseTimeArray<=5.0) = NaN; %any responseTimes <5 secs are changed to NaN

% maxRewards
for rowi = 1:length(groupTableSorted.MouseID)
    currData                = load(groupTable.TaskPath(rowi));
    maxRewardsArray(rowi,1) = nansum(currData.ExperimentTaskTable.Outcome);
end

%Append arrays onto the end of groupTable
groupTable.("maxRewards")           = maxRewardsArray;
groupTable.("omits")                = sum(isnan(omissionArray),2);
groupTable.("longResponses")        = sum(~isnan(longResponseTimeArray),2);
groupTable.("meanLongResponseTime") = nanmean(longResponseTimeArray,2);

groupTableNoPathVar = removevars(groupTable,"TaskPath"); % save table without filePath var

%Save Table data to .csv file
%if file exists, save over
filePathAndName = [optionsFile.paths.resultsDir, filesep, 'allMiceAlltasks_Rewards-Omits-RT-LongRT.csv'];
writetable(groupTableNoPathVar,filePathAndName)

% Create sex-specific tables
femaleGroupTable = groupTable(~ismember(groupTable.sex,"Male"),:); %remove all female mice
maleGroupTable = groupTable(~ismember(groupTable.sex,"Female"),:); %remove all male mice


for taski = 1:length(optionsFile.task.taskList)
    currTask = erase(optionsFile.task.taskList(taski),optionsFile.task.taskPrefix,'_');
    taskData = groupTable(ismember(groupTable.Task,char(currTask)),:);
    for taskRepetitioni = 1:max(groupTable.TaskRepetition)
        taskData     = taskData(ismember(taskData.TaskRepetition,taskRepetitioni),:);
        tableVarTypes = {'string','string','double','double','double','double'};
        tableVarNames = {'MouseID','sex','maxRewards','omits','longResponses','meanLongResponseTime'};
        taskRepTable = table('Size',[length(unique(groupTable.MouseID)) length(tableVarNames)],...
            'VariableTypes',tableVarTypes,'VariableNames',tableVarNames);
        mouseList = unique(groupTable.MouseID);

        for mousei = 1:length(unique(groupTable.MouseID))
            taskRepTable.MouseID(mousei)              = mouseList(mousei);
            taskRepTable.maxRewards(mousei)           = taskData.maxRewards(mousei);
            taskRepTable.omits(mousei)                = taskData.omits(mousei);
            taskRepTable.longResponses(mousei)        = taskData.longResponses(mousei);
            taskRepTable.meanLongResponseTime(mousei) = taskData.meanLongResponseTime(mousei);
        end

        taskTable = [taskTable;taskRepTable];
    end

end

%%Find average >5 sec responseTime trial #
AvgLongResponseTrialNumber = zeros(1,10);
for i = 1:width(AvgLongResponseTrialNumber)
    currLongResponseTrials = responseTimeArray(:,i);
    currLongResponseTrialNumbers = find(~isnan(currLongResponseTrials));
    currLongResponseTrialNumbersSum = sum(currLongResponseTrialNumbers);
    avgLongResponseTrialNumber(1,i) = currLongResponseTrialNumbersSum / length(currLongResponseTrialNumbers);
end

%Mean LongResponseTime
AvgLongResponseTimeArray = zeros(1,10);
for i = 1:width(ResponseTimeArray)
    avgLongResponseTimeArray(1,i) = mean(responseTimeArray(:,i),'omitnan');
end

%% Omission
% Find average omissionCount for each control mouse
%Create empty array to count per mouse how many omissions they had
omissionCountArray = zeros(1,10);
omissionCountArray(1,:) = sum(OmissionArray == 3); %Count omissions (indicated by Choice as a 3)

%%Find average omission trial #
avgOmissionTrialNumber = zeros(1,10);
for i = 1:width(avgOmissionTrialNumber)
    currOmissionTrials                = omissionArray(:,i);
    currOmissionTrialNumbers          = find(currOmissionTrials==3);
    currMouseSumOmissionTrialNumbers  = sum(currOmissionTrialNumbers);
    avgOmissionTrialNumber(1,i)       = currMouseSumOmissionTrialNumbers / length(currOmissionTrialNumbers);
end

mouseTable.OmissionCount              = OmissionCountArray';
mouseTable.AvgOmissionTrialNumber     = AvgOmissionTrialNumber';
mouseTable.LongResponseCount          = LongResponseCountArray';
mouseTable.AvgLongResponseTrialNumber = AvgLongResponseTrialNumber';
mouseTable.AvgLongResponseTime        = AvgLongResponseTimeArray';

%Save Table data to .csv file
writetable(mouseTable,[optionsFile.paths.resultsDir, filesep, 'Omissions&&LongResponseTime_SummaryTable.csv'])
toc