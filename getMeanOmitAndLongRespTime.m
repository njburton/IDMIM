
optionsFile = runOptions; % specifications for this analysis

%% Create empty arrays for logging individual mouse data
OmissionArray = zeros(180,10);
ResponseTimeArray = zeros(180,10);

%% Save currMouse responseTimes and choices to appropriate arrays
for n = 1:optionsFile.cohort.nSize

    currMouse = optionsFile.task.MouseID(n);
    load(fullfile([char(optionsFile.paths.resultsDir),'\mouse',num2str(currMouse),'.mat'])); %Load currMouse experimentaskTable

    OmissionArray(:,n) =  ExperimentTaskTable.Choice;
    ResponseTimeArray(:,n) = ExperimentTaskTable.ResponseTime;
end

%% Use data from arrays to fill below Table for saving/printing
% %Create table of Control mouse data
TableVarTypes = {'string','double','double','double','double','double'};
TableVarNames = {'MouseID','OmissionCount','AvgOmissionTrialNumber','LongResponseCount','AvgLongResponseTrialNumber','AvgLongResponseTime'};
ControlMouseTable = table('Size',[10 length(TableVarNames)],'VariableTypes', TableVarTypes,'VariableNames',TableVarNames);

%MouseIDS in first column
ControlMouseTable.MouseID = optionsFile.task.MouseID;
%% ResponseTime
% %array values so that ResponseTimes less than 5 secs are zero'd
ResponseTimeArray(ResponseTimeArray<=5.0) = NaN;

%Create empty array to count per mouse how many LongResponses they had
%Long response time classified as greater than 5 seconds
LongResponseCountArray = zeros(1,10);

%Count how many longResponse's (>5sec) there are for each mouse (column)
for i = 1:width(LongResponseCountArray)
    LongResponseCountArray(1,i) = nnz(~isnan(ResponseTimeArray(:,i)));
end

%%Find average >5 sec responseTime trial #
AvgLongResponseTrialNumber = zeros(1,10);
for i = 1:width(AvgLongResponseTrialNumber)
    currLongResponseTrials = ResponseTimeArray(:,i)
    currLongResponseTrialNumbers = find(~isnan(currLongResponseTrials));
    currLongResponseTrialNumbersSum = sum(currLongResponseTrialNumbers);
    AvgLongResponseTrialNumber(1,i) = currLongResponseTrialNumbersSum / length(currLongResponseTrialNumbers)
end

%Mean LongResponseTime
AvgLongResponseTimeArray = zeros(1,10);
for i = 1:width(ResponseTimeArray)
    AvgLongResponseTimeArray(1,i) = mean(ResponseTimeArray(:,i),'omitnan')
end

%% Omission
% Find average omissionCount for each control mouse
%Create empty array to count per mouse how many omissions they had
OmissionCountArray = zeros(1,10);
%Count omissions (indicated by Choice as a 3)
OmissionCountArray(1,:) = sum(OmissionArray == 3)

%%Find average omission trial #
AvgOmissionTrialNumber = zeros(1,10);
for i = 1:width(AvgOmissionTrialNumber)
    currOmissionTrials = OmissionArray(:,i);
    currOmissionTrialNumbers= find(currOmissionTrials==3);
    currMouseSumOmissionTrialNumbers = sum(currOmissionTrialNumbers);
    AvgOmissionTrialNumber(1,i) = currMouseSumOmissionTrialNumbers / length(currOmissionTrialNumbers)
end

ControlMouseTable.OmissionCount = OmissionCountArray';
ControlMouseTable.AvgOmissionTrialNumber = AvgOmissionTrialNumber';
ControlMouseTable.LongResponseCount = LongResponseCountArray';
ControlMouseTable.AvgLongResponseTrialNumber = AvgLongResponseTrialNumber';
ControlMouseTable.AvgLongResponseTime = AvgLongResponseTimeArray'

%Save Table data to .csv file
writetable(ControlMouseTable,[optionsFile.paths.resultsDir, filesep, 'Controls_Omissions&&LongResponseTime_SummaryTable.csv'])
