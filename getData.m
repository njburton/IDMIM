function optionsFile = getData(optionsFile)
%% runOptions
% - set all relevant paths, global variables
% - specify what analysis steps should be executed when running "runAnalysis"
% - make directories and folderstructure for data if needed
%
%  SYNTAX:  getData
%
%  INPUT:  optionsFile
%
%  OUTPUT: optionsFile, updated after reading the data
%
% Original: 30/5/2023; Katharina Wellstein
% Amended: 23/2/2024; Nicholas Burton
% -------------------------------------------------------------------------
%
% Copyright (C) 2024 - need to fill in details
%
% _________________________________________________________________________
% =========================================================================

%% DATA EXTRACTION & PREPARATION
% Extract data from MED-PC output file (.xlsx) and save as matlab file.
% Create empty table for individual mouse with variable names as columns
TaskTableVarTypes = {'string','double','double','double','double','double','double','double'};
TaskTableVarNames = {'TrialCode','RewardingLeverSide','Choice','Outcome','TrialStartTime','LeverPressTime','ResponseTime','RecepticalBeamBreak'};
ExperimentTaskTable = table('Size',[optionsFile.Task.nTrials 8],'VariableTypes', TaskTableVarTypes,'VariableNames',TaskTableVarNames);

% For loop which creates individual mouse tables from rawTaskData file
% (where each column is a mouse)
files = dir(fullfile(optionsFile.paths.rawDataDir,'*Subject *.txt'));

for i = 1:optionsFile.Task.nSize
    fileName  = string(files(i).name);
    currMouse = extract(fileName ," "+digitsPattern(3)+"."); %find three digits between space and .
    currMouse = erase(currMouse{end}," ");
    currMouse = erase(currMouse,".");
    data      = readcell(fullfile(optionsFile.paths.rawDataDir, fileName));
    [~,cols]  = size(cell2mat(data(50,2)));

    if cols<10 % if yes, based on old version of saving data with the
        % second column saving 4 entries in one cell

        % find array indices
        choiceIdx  = find(contains(data(:,1),optionsFile.DataFile.ChoiceMarker))+2;
        outcomeIdx = find(contains(data(:,1),optionsFile.DataFile.OutcomeMarker))+2;
        lPressTIdx = find(contains(data(:,1),optionsFile.DataFile.LeverPressTimeMarker))+2;

        % save arrays into table
        ExperimentTaskTable.TrialCode      = nan(optionsFile.Task.nTrials,1); % ?? why are they NaNs
        ExperimentTaskTable.Choice         = cell2mat(data(choiceIdx:choiceIdx+optionsFile.Task.nTrials-1,2));   %Choice_ABA1
        ExperimentTaskTable.Outcome        = cell2mat(data(outcomeIdx:outcomeIdx+optionsFile.Task.nTrials-1,2)); %Outcome_ABA1
        ExperimentTaskTable.LeverPressTime = cell2mat(data(lPressTIdx:lPressTIdx+optionsFile.Task.nTrials-1,2)); %LeverPressTime_ABA1
        ExperimentTaskTable.TrialStartTime = (0:20:3580)'; %TrialStartTime list every 20seconds
        ExperimentTaskTable.ResponseTime   = ExperimentTaskTable.LeverPressTime - ExperimentTaskTable.TrialStartTime; %ResponseTime
        optionsFile.Task.MouseID(i,:) = string(currMouse);

        %% Load binary sequence for rewardlever side so we can use as input
        % for analysis using hgf.
        % Binary sequence for RewardingLeverSide (1=leftlever, 0=rightlever)
        seqBinary = readcell([optionsFile.paths.projDir,'\', optionsFile.Task.BinarySeq],'Range','A1:A180');
        ExperimentTaskTable.RewardingLeverSide = cell2mat(seqBinary); % Binary sequence for rewarding lever side (1=left, 0=right)

        %Data correction
        ExperimentTaskTable.Choice(ExperimentTaskTable.Choice==3) = NaN;  % Replace omissions (3 in Choice) with NaN
        ExperimentTaskTable.LeverPressTime(ExperimentTaskTable.LeverPressTime==0) = NaN; %Replace trials where no lever press with NaN
        ExperimentTaskTable.RecepticalBeamBreak(ExperimentTaskTable.RecepticalBeamBreak<0) = NaN;

        mkdir([char(optionsFile.paths.resultsDir),'\mouse',char(currMouse)]);
        save([char(optionsFile.paths.resultsDir),'\mouse',char(currMouse)],'ExperimentTaskTable');
    else
        disp(['Mouse: ', char(currMouse), 'is not saved in the right format for this analysis. ...' ...
            'This may be because it was only training data or there is something wrong with formatting. Please make sure to check manually.']);
    end
end
    optionsFile.Task.MouseID(find(isnan(optionsFile.Task.MouseID)))=[];
   optionsFile.Task.nSize = length(optionsFile.Task.MouseID);

end