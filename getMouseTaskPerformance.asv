%plot distribution of responsetimes
tic
load("optionsFile.mat"); % specifications for this analysis
load(char(fullfile(optionsFile.paths.databaseDir, 'toProcessWithPipeline_allFilesWithTaskOrder.mat')));

%% initialise empty arrays for logging individual mouse data
omissionArray     = zeros(length(groupTableSorted.MouseID),optionsFile.task.nTrials);
longResponseTimeArray = zeros(length(groupTableSorted.MouseID),optionsFile.task.nTrials); 
maxRewardsArray   = zeros(length(groupTableSorted.MouseID),1); 

groupTable = groupTableSorted;

% save currMouse responseTimes and choices to appropriate arrays
for rowi = 1:length(groupTableSorted.MouseID)
    currData                      = load(groupTableSorted.TaskPath(rowi));
    omissionArray(rowi,:)         = currData.ExperimentTaskTable.Choice;
    longResponseTimeArray(rowi,:) = currData.ExperimentTaskTable.ResponseTime;
end
longResponseTimeArray(longResponseTimeArray<=5.0) = NaN; %any responseTimes <5 secs are changed to NaN

% maxRewards
for rowi = 1:length(groupTableSorted.MouseID)
    currData                = load(groupTableSorted.TaskPath(rowi));
    maxRewardsArray(rowi,1) = nansum(currData.ExperimentTaskTable.Outcome); 
end

%Append arrays onto the end of groupTable
groupTable.("maxRewards")           = maxRewardsArray;
groupTable.("omits")                = sum(isnan(omissionArray),2);
groupTable.("longResponses")        = sum(~isnan(longResponseTimeArray),2);
groupTable.("meanLongResponseTime") = nanmean(longResponseTimeArray,2);

groupTable2 = removevars(groupTable,"TaskPath"); % save table without filePath var

%Save Table data to .csv file
%writetable(groupTable2,[optionsFile.paths.resultsDir, filesep, 'allMiceAlltasks_Rewards-Omits-RT-LongRT.csv'])

%Create sex-specific tables
maleGroupTable = groupTable2;
femaleGroupTable = groupTable2;
maleGroupTable(~ismember(maleGroupTable.sex,"Male"),:)=[]; %remove all female mice
femaleGroupTable(~ismember(femaleGroupTable.sex,"Female"),:)=[]; %remove all male mice

task1GroupTable(~ismember(task1GroupTable.TaskOrder,"1"),:)=[]; %remove all male mice

%% initialise table to save individual mouse maxRew data and group mean into .csv
tableVarTypes = {'double','double','double','double','double','double','double'};
tableVarNames = {'Group','Task','TaskOrder','MaxRewards','Omits','longResponses','meanLongResponseTime'};
tableT  = table('Size',[3 length(tableVarNames)],'VariableTypes', tableVarTypes,'VariableNames',tableVarNames);

groups = {'Control','Male','Female'};
for rowi = 1:length(groupTable.MouseID)
    for groupi = 1:length(groups)
        currGroup = groups(groupi);
        for taski = 1:length(optionsFile.task.taskList)
            currTask = erase(optionsFile.task.taskList(taski),"NJB_HGF_");
            taskTable = maleGroupTable(ismember(maleGroupTable.Task,currTask),:);
            for taskOrderi = 1:max(taskTable.TaskOrder)


                currTaskOrder = taskTable.TaskOrder(taskOrderi);
                tableT.Group(rowi) = currGroup;
                tableT.Task(rowi) = currTask;
                tableT.TaskOrder(rowi) = taskOrderi;
                tableT.MaxRewards(rowi) = currMaxRewards;
                tableT.Omits(rowi) = currOmits; 
                tableT.longResponses(rowi) = currLongResponses;
                tableT.meanLongResponseTime(rowi) = groupTable

        end
    end


end

% initialise table to save individual mouse maxRew data and group mean into .csv
tableVarTypes    = {'string','double','double','double','double'};
tableVarNames    = {'MouseID','MaxRewards','Omits','longResponses','meanLongResponseTime'};
mouseTable  = table('Size',[length(groupTableSortByDates.MouseID)...
        length(tableVarNames)],'VariableTypes', tableVarTypes,'VariableNames',tableVarNames);

% save omission plot for individual mouse
for filei = 1:length(groupTableSortByDates.MouseID) % for each group (1 = control, 2 = treatment group)
    currMouse                 = groupTableSortByDates.MouseID(rowi);
    currData                  = load(groupTableSortByDates.TaskPath(rowi));
   
end



% save omission plot for each sex

% save omission plot for each group

%Create empty array to count per mouse how many LongResponses they had
%Long response time classified as greater than 5 seconds
longResponseCountArray = zeros(1,10);

%Count how many longResponse's (>5sec) there are for each mouse (column)
for i = 1:width(longResponseCountArray)
    longResponseCountArray(1,i) = nnz(~isnan(responseTimeArray(:,i)));
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