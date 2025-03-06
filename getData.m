function  getData(cohortNo)
%% getData - Process and extract experimental task data from MED-PC files
%
% SYNTAX:  getData(cohortNo)
%
%   IN: cohortNo:  integer, cohort number, see optionsFile for what cohort
%                            corresponds to what number in the
%                            optionsFile.cohort(cohortNo).name struct. This
%                            allows to run the pipeline and its functions for different
%                            cohorts whose expcifications have been set in runOptions.m
%
% Authors: Katharina Wellstein (30/5/2023), Nicholas Burton (23/2/2024)
% -------------------------------------------------------------------------
%
% Copyright (C) 2024 - need to fill in details
%
% This file is released under the terms of the GNU General Public Licence
% (GPL), version 3. You can redistribute it and/or modify it under the
% terms of the GPL (either version 3 or, at your option, any later version).
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details:
% <http://www.gnu.org/licenses/>
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
% _________________________________________________________________________
% =========================================================================
if exist('optionsFile.mat','file')==2
    load("optionsFile.mat");
else
    optionsFile = runOptions();
end


%% Initialise Experiment Task Table
taskTableVarTypes = {'double','double','double','double',...
                    'double','double','double'};
taskTableVarNames = {'RewardingLeverSide','Choice','Outcome','TrialStartTime',...
                    'LeverPressTime','ResponseTime','RecepticalBeamBreak'};

ExperimentTaskTable = table('Size',[optionsFile.cohort(cohortNo).nTrials length(taskTableVarNames)],...
    'VariableTypes', taskTableVarTypes,...
    'VariableNames',taskTableVarNames);

%% Initialise Mouse Info Table containing general info about the mouse

infoTableVarTypes = {'string','string','double','string','string'};
infoTableVarNames = {'Task','TaskDate','Chamber','Condition','Sex'};
MouseInfoTable    = table('Size',[1,length(infoTableVarNames)],...
    'VariableTypes',infoTableVarTypes,...
    'VariableNames',infoTableVarNames);

%% Extract task names and inputs for current cohort / dataset
% list containing the medpcTaskNames you want to look for and extract
% ATTENTION: The sequence with which the task types occurr here are
% important, i.e. training Tasks come first, test Tasks second for both
% variables
tasks  = {optionsFile.cohort(cohortNo).trainTask(:).name,optionsFile.cohort(cohortNo).testTask(:).name};
inputs = [optionsFile.cohort(cohortNo).trainTask(:).inputs optionsFile.cohort(cohortNo).testTask(:).inputs];
conditions = optionsFile.cohort(cohortNo).conditions;

if isempty(tasks); error(['Task name is empty. Check optionsFile.cohort',num2str(cohortNo),'if any training or testtask names have been specified.']); end

%% check for large files where multiple mice are saved into a single raw MED-PC file
allFiles = dir(fullfile(optionsFile.paths.cohort(cohortNo).rawData,'*.*'));
allFiles = allFiles(3:end); %removes Unix subfolder pointers "." and ".."

% initialize logical array indicating if the current file is a large file containing multiple mouse files
isLargeFile = zeros(length(allFiles),1);

for iFile = 1:length(allFiles)
    %check if current file is a file containing multiple mouse files
    if allFiles(iFile).bytes >= optionsFile.dataFiles.largeFileThreshold
        isLargeFile(iFile,1) = 1; % if = 1, process as large file
    else
        continue
    end %end of check if file is overly large (>500,000 bytes)
end %end of check for files with .file in dataToAnalyse dir

%check if filesToProcess is empty of if there are identified large files to deconstruct
if ~isempty(isLargeFile(:,1))
    disp('Large (>500,000 bytes) MED-PC file found.');%If isLargeFile is NOT empty, extract individual mouse data
else
    disp('No large files detected.')
end


%% Processing each large files
for iLargeFile = 1:length(isLargeFile)
    if isLargeFile(iLargeFile,1) == 0 %skip if file is not identified as large (0) in filesToProcess
        continue
    else
        fileName       = string(allFiles(iLargeFile).name);
        largeMEDPCFile = readtable(fullfile(optionsFile.paths.cohort(cohortNo).rawData,fileName));
        for iTask  = 1:length(tasks) %for each task name in the task list
            startIDs = find(contains(largeMEDPCFile.Var2,tasks{iTask}));

            %checkpoint to throw error if startIndices (startIDs) extract non-interger
            %value and also before (cell above) and after( cell above)
            for iStartIDs = 1:length(startIDs) %row index for all mentions of tasks
                currMouse    = cell2mat(largeMEDPCFile.Var2(startIDs(iStartIDs)-6));
                currTaskDate = cell2mat(largeMEDPCFile.Var2(startIDs(iStartIDs)-8));
                currTaskDate = replace(currTaskDate,'/','-');
                currCondition = cell2mat(largeMEDPCFile.Var2(startIDs(iStartIDs)-10)); %?>>>> CHECK IF THAT WORKS

                % save data to table
                MouseInfoTable.Task      = tasks{iTask};  %TrialCode
                MouseInfoTable.TaskDate  = currTaskDate;
                MouseInfoTable.Chamber   = str2num(cell2mat(largeMEDPCFile.Var2((startIDs(iStartIDs)-3))));
                MouseInfoTable.Condition = currCondition; %?>>>> CHECK IF THAT WORKS

                ExperimentTaskTable.Outcome     = str2num(cell2mat(largeMEDPCFile.Var2((startIDs(iStartIDs)+...
                    optionsFile.cohort(cohortNo).dataFile.outcomeOffset+1):...
                    (startIDs(iStartIDs)+optionsFile.cohort(cohortNo).dataFile.outcomeOffset+...
                    optionsFile.cohort(cohortNo).nTrials)))); % Outcome 0=time,1=reward
                ExperimentTaskTable.Choice      = str2num(cell2mat(largeMEDPCFile.Var2((startIDs(iStartIDs)+...
                    optionsFile.cohort(cohortNo).dataFile.choiceOffset+1):...
                    (startIDs(iStartIDs)+optionsFile.cohort(cohortNo).dataFile.choiceOffset+...
                    optionsFile.cohort(cohortNo).nTrials)))); % Choice 0=left,1=right
                ExperimentTaskTable.TrialStartTime = transpose(0:optionsFile.cohort(cohortNo).trialDuration:...
                    (optionsFile.cohort(cohortNo).totalTaskDuration-13)); % TrialStartTime. Last trial begins at 27 after total taskDur
                %ExperimentTaskTable.RecepticalBeamBreak = cell2mat(largeMEDPCFile.Var2((startIndices(startIndicesi)+optionsFile.dataFile.recepticalBeamBreakOffset+1):(startIndices(startIndicesi)+optionsFile.dataFile.recepticalBeamBreakOffset+optionsFile.task.nTrials)));   %RecepticalBeamBreak
                ExperimentTaskTable.LeverPressTime = str2num(largeMEDPCFile.Var2((startIDs(iStartIDs)+...
                    optionsFile.cohort(cohortNo).dataFile.leverPressTimeOffset+1):...
                    (startIDs(iStartIDs)+optionsFile.cohort(cohortNo).dataFile.leverPressTimeOffset+...
                    optionsFile.cohort(cohortNo).nTrials)));
                ExperimentTaskTable.ResponseTime   = ExperimentTaskTable.LeverPressTime - ExperimentTaskTable.TrialStartTime; %time between trialStart and leverPress

                % >>>>>>>>> NICK: CHECK IF that works with rows2vars
                %input sequence
                binInputSeq  = rows2vars(inputs(:,iTask)); % RewardingLeverSide
                ExperimentTaskTable.RewardingLeverSide = binInputSeq.Var1; % binary input sequence for task aka. RewardingLeverSide

                %verifyExperimentSequence
                checkPoint = verifyExperimentSequence(ExperimentTaskTable);
                if checkPoint == false; error(['InputSeqCheckpoint: Detected error between RewardingSideLever binInputSequence' ...
                        'and task outcome. Troubleshoot by checking input values in ExperimentTaskTable.RewardingLeverSide,'...
                        'and .Outcomes as well as. Choice.'])
                    %>>> TO DO???? save diary and turn off diary;
                end

                % Data correction, omissions were coded as 3 in the raw data, replace with NaN
                ExperimentTaskTable.Outcome(ExperimentTaskTable.Choice==3)              = NaN;
                ExperimentTaskTable.LeverPressTime(ExperimentTaskTable.Choice==3)       = NaN;
                ExperimentTaskTable.ResponseTime(ExperimentTaskTable.ResponseTime<=0.0) = NaN;
                ExperimentTaskTable.Choice(ExperimentTaskTable.Choice==3)               = NaN;
                %ExperimentTaskTable.RecepticalBeamBreak(ExperimentTaskTable.RecepticalBeamBreak<0) = NaN;

                if isempty(optionsFile.cohort(cohortNo).conditions)
                    % Save with conditions included
                    saveExpPath = [char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                        tasks{iTask},'.mat']; % >>>> NICK: deleted date because it makes reading data easier, is that ok?
                    saveInfoPath = [char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                        tasks{iTask},'_info.mat'];
                else
                    saveExpPath = [char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                        tasks{iTask},'_condition_',currCondition,'.mat'];
                    saveInfoPath = [char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                        tasks{iTask},'_condition_',currCondition,'_info.mat'];
                end
                save(saveExpPath,'ExperimentTaskTable');
                save(saveInfoPath,'MouseInfoTable');

            end %end of using startIndices to extract and save individual mice data
        end %end of searching for each taskName in list in largeMEDPCFile
    end %end of checking filesToProcess vector
end %end of processing large MEDPC file

%% create individual mouse tables from regular sized (<70,000 bytes) MEDPC files
disp('Now extracting from normal MEDPC output files');
for iFile = 1:length(isLargeFile) %for each file in the data dir
    fileName     = string(allFiles(iFile).name);
    regMEDPCFile = readcell(fullfile(optionsFile.paths.cohort(cohortNo).rawData, fileName));
    %>>>>>>>>>> MICK: CHeck if the line below still works or if we have to
    %loop through tasks or if we even need tasks
    if isLargeFile(iFile,1) || ~contains(regMEDPCFile(10,2),tasks) == 1 %skip if file is not identified as regMEDPCFile (0) in fileCategory
        continue
    else
        currMouse     = num2str(cell2mat(regMEDPCFile(4,2)));
        currTaskDate  = extractBetween(fileName,1,10);
        currTask      = cell2mat(regMEDPCFile(10,2));  %TrialCode
        currCondition = cell2mat(largeMEDPCFile.Var2(startIDs(iStartIDs)-10)); %?>>>> CHECK IF THAT WORKS

        % find where in tasks vector the current task is placed and
        % extracting index to be used to extract corresponding inputs
        for t = 1:numel(tasks)
            idx(t) = strcmp(tasks{t},currTask);
        end
        taskIdx = find(idx);
        % save data to table
        MouseInfoTable.Task      = tasks{iTask};  %TrialCode
        MouseInfoTable.TaskDate  = currTaskDate;
        MouseInfoTable.Chamber   = cell2mat(regMEDPCFile(7,2));
        MouseInfoTable.Condition = currCondition;

        ExperimentTaskTable.Outcome      = cell2mat(regMEDPCFile((optionsFile.cohort(cohortNo).dataFile.outcomeOffset+11):...
            (optionsFile.cohort(cohortNo).dataFile.outcomeOffset+10+...
            optionsFile.cohort(cohortNo).nTrials),2)); % Outcome 0=time,1=reward
        ExperimentTaskTable.Choice         = cell2mat(regMEDPCFile((optionsFile.dataFile.choiceOffset+11):...
            (optionsFile.dataFile.choiceOffset+10+...
            optionsFile.task.nTrials),2)); % Choice 0=left,1=right
        ExperimentTaskTable.TrialStartTime = transpose(0:optionsFile.task.trialDuration:(optionsFile.task.totalTaskDuration-13)); % TrialStartTime. Total task time is 3640 but the last trial begins at 3627
        %ExperimentTaskTable.RecepticalBeamBreak = cell2mat(regMEDPCFile((startIndices(startIndicesi)+optionsFile.cohort(cohortNo).dataFile.recepticalBeamBreakOffset+1):(startIndices(startIndicesi)+optionsFile.cohort(cohortNo).dataFile.recepticalBeamBreakOffset+optionsFile.cohort(cohortNo).nTrials)));   %RecepticalBeamBreak
        ExperimentTaskTable.LeverPressTime = cell2mat(regMEDPCFile((optionsFile.cohort(cohortNo).dataFile.leverPressTimeOffset+11):...
            (optionsFile.dataFile.leverPressTimeOffset+10+...
            optionsFile.task.nTrials),2));
        ExperimentTaskTable.ResponseTime   = ExperimentTaskTable.LeverPressTime - ExperimentTaskTable.TrialStartTime; %time between trialStart and leverPress

        %input sequence
        binInputSeq  = rows2vars(inputs(:,idx)); % RewardingLeverSide
        ExperimentTaskTable.RewardingLeverSide = binInputSeq.Var1; % binary input sequence for task aka. RewardingLeverSide

        %verifyExperimentSequence
        checkPoint = verifyExperimentSequence(ExperimentTaskTable);
        if checkPoint == false; error(['InputSeqCheckpoint: Detected error between RewardingSideLever binInputSequence' ...
                'and task outcome. Troubleshoot by checking input values in ExperimentTaskTable.RewardingLeverSide,'...
                'and .Outcomes as well as. Choice.']);
        end

        % Data correction, omissions were coded as 3 in the raw data, replace with NaN
        ExperimentTaskTable.Outcome(ExperimentTaskTable.Choice==3)              = NaN;
        ExperimentTaskTable.LeverPressTime(ExperimentTaskTable.Choice==3)       = NaN;
        ExperimentTaskTable.ResponseTime(ExperimentTaskTable.ResponseTime<=0.0) = NaN;
        ExperimentTaskTable.Choice(ExperimentTaskTable.Choice==3)               = NaN;
        %ExperimentTaskTable.RecepticalBeamBreak(ExperimentTaskTable.RecepticalBeamBreak<0) = NaN;

        % create savepath and filename as a .mat file
        if isempty(optionsFile.cohort(cohortNo).conditions)
            saveExpPath = [char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                tasks{iTask},'.mat']; % >>>> NICK: deleted date because it makes reading data easier, is that ok?
            saveInfoPath = [char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                tasks{iTask},'_info.mat'];
        else % Save with conditions included
            saveExpPath = [char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                tasks{iTask},'_condition_',currCondition,'.mat'];
            saveInfoPath = [char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                tasks{iTask},'_condition_',currCondition,'_info.mat'];
        end
        save(saveExpPath,'ExperimentTaskTable');
        save(saveInfoPath,'MouseInfoTable');
    end
end

end
