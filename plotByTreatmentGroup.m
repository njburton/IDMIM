function plotByTreatmentGroup

% read data in - task tables
try
    load('optionsFile.mat');
catch
    optionsFile = runOptions; % specifications for this analysis
end

%Should I create a table to save rather than create arrays temporarily to
%plot data each time I run the script

% TableVarTypes = {'string','string','double','double','double','double','double'};
% TableVarNames = {'MouseID','TreatmentGroup','Choice','Outcome','Omission','ResponseTime','RW_PE'};
% TreatmentGroupTable = table('Size',[TotalTrial length(TableVarNames)],'VariableTypes', TableVarTypes,'VariableNames',TableVarNames);

TotalTrials = 180;
TreatmentGroupChoiceArray = zeros(TotalTrials,20);
TreatmentGroupOutcomeArray = zeros(TotalTrials,20);
TreatmentGroupRecepticalBeamBreakArray = zeros(TotalTrials,20);
TreatmentGroupResponseTimeArray = zeros(TotalTrials,20);
TreatmentGroupOmissionArray = zeros(TotalTrials,20);

%Perform omission criteria check. If passed, fill arrays with each column being a mouse and each row is a trial in the
%task
for j = 1:length(optionsFile.task.MouseID)
    currMouse = optionsFile.task.MouseID(j); % read out current mouse ID
    currMouseData = load(fullfile([char(optionsFile.paths.resultsDir),'\mouse',num2str(currMouse),'eHGFFit.mat'])); %Load currMouse eHGFFit.mat file in resultsDirectory

    if length(currMouseData.eHGFFit.irr) > 36 %Check to see if currMouse had more than 20% (36) omissions. If less than 20%, load data into arrays
        disp("Detected mouse with too many omissions. Not plotting. ")
    else
        TreatmentGroupChoiceArray(:,j) = currMouseData.eHGFFit.y %Choices/responses  
        TreatmentGroupOutcomeArray(:,j) = ExperimentTaskTable
        TreatmentGroupRecepticalBeamBreakArray(:,j) =
        TreatmentGroupResponseTimeArray(:,j) =
        TreatmentGroupOmissionArray(:,j) =
    end
end
