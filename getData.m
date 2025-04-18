function getData(cohortNo)
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
% Coded by: Katharina Wellstein, https://github.com/kwellstein
%           Nicholas Burton
% -------------------------------------------------------------------------
%
% Copyright (C) 2025
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
    load('optionsFile.mat');
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
if isempty(optionsFile.cohort(cohortNo).trainTask(1).name)
    tasks  = {optionsFile.cohort(cohortNo).testTask(:).name};
    inputs = [optionsFile.cohort(cohortNo).testTask(:).inputs];
else
    tasks  = {optionsFile.cohort(cohortNo).trainTask(:).name, optionsFile.cohort(cohortNo).testTask(:).name};
    inputs = [optionsFile.cohort(cohortNo).trainTask(:).inputs optionsFile.cohort(cohortNo).testTask(:).inputs];
end


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
        isLargeFile(iFile,1) = 0; %
    end %end of check if file is overly large (>500,000 bytes)
end %end of check for files with .file in dataToAnalyse dir

%check if there are any ones in the isLargeFile vector indicating that a large file has been detected in the directory
if sum(isLargeFile)>=1
    disp('================ Large (>500,000 bytes) MED-PC file found. ========================');%If isLargeFile is NOT empty, extract individual mouse data
    disp('doublecheck the following datasets for possible errors:');
else
    disp('No large files detected.')
end


%% Processing each large file
for iLargeFile = 1:sum(isLargeFile)
    largeFileIdx = find(isLargeFile);
    fileName       = string(allFiles(largeFileIdx(iLargeFile)).name);
    if startsWith(fileName,'._')
        fileName  = erase(fileName ,'._');
    end
    largeMEDPCFile = readtable(fullfile(optionsFile.paths.cohort(cohortNo).rawData,fileName));
    for iTask  = 1:length(tasks) %for each task name in the task list
        startIDs = find(contains(largeMEDPCFile.Var2,tasks{iTask}));

        %checkpoint to throw error if startIndices (startIDs) extract non-interger
        %value and also before (cell above) and after( cell above)
        for iStartIDs = 1:length(startIDs) %row index for all mentions of tasks
            currMouse    = cell2mat(largeMEDPCFile.Var2(startIDs(iStartIDs)-6));
            currTaskDate = extractBefore(fileName,'_');
            currTaskDate = replace(currTaskDate,'/','-');
            currTaskDate = char(currTaskDate);

            currTask = tasks{iTask};
            disp(['reading ', char(currMouse),' and ', char(tasks{iTask}) ' data from large File...'])

            % save data to table
            MouseInfoTable.Task      = currTask;  %TrialCode
            MouseInfoTable.TaskDate  = currTaskDate;
            MouseInfoTable.Chamber   = str2num(cell2mat(largeMEDPCFile.Var2((startIDs(iStartIDs)-3))));

            % get mouse sex and add to mouse info table
            if sum(strcmp(optionsFile.cohort(cohortNo).treatment.maleMice,currMouse))
                MouseInfoTable.Sex = 'male';
                if isempty(optionsFile.cohort(cohortNo).conditions)
                    currCondition = 'treatment';
                else
                    currCondition = largeMEDPCFile.Var2{startIDs(iStartIDs)-4};
                end
            elseif sum(strcmp(optionsFile.cohort(cohortNo).control.maleMice,currMouse))
                MouseInfoTable.Sex = 'male';
                if isempty(optionsFile.cohort(cohortNo).conditions)
                    currCondition = 'control';
                else
                    currCondition = largeMEDPCFile.Var2{startIDs(iStartIDs)-4};
                end
            elseif sum(strcmp(optionsFile.cohort(cohortNo).treatment.femaleMice,currMouse))
                MouseInfoTable.Sex = 'female';
                if isempty(optionsFile.cohort(cohortNo).conditions)
                    currCondition = 'treatment';
                else
                    currCondition = largeMEDPCFile.Var2{startIDs(iStartIDs)-4};
                end
            elseif sum(strcmp(optionsFile.cohort(cohortNo).control.femaleMice,currMouse))
                MouseInfoTable.Sex = 'female';
                if isempty(optionsFile.cohort(cohortNo).conditions)
                    currCondition = 'control';
                else
                    currCondition = largeMEDPCFile.Var2{startIDs(iStartIDs)-4};
                end
            else
                disp('Current mouseID not found!')
            end


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
            ExperimentTaskTable.LeverPressTime = str2double(largeMEDPCFile.Var2((startIDs(iStartIDs)+...
                optionsFile.cohort(cohortNo).dataFile.leverPressTimeOffset+1):...
                (startIDs(iStartIDs)+optionsFile.cohort(cohortNo).dataFile.leverPressTimeOffset+...
                optionsFile.cohort(cohortNo).nTrials)));
            ExperimentTaskTable.ResponseTime   = ExperimentTaskTable.LeverPressTime - ExperimentTaskTable.TrialStartTime; %time between trialStart and leverPress

            %input sequence
            ExperimentTaskTable.RewardingLeverSide = inputs(:,iTask); % binary input sequence for task aka. RewardingLeverSide

            % Data correction,replace MEDPC omission code with NaN
            ExperimentTaskTable.Outcome(ExperimentTaskTable.Choice==optionsFile.cohort(cohortNo).dataFile.missedTrialCode)        = NaN;
            ExperimentTaskTable.LeverPressTime(ExperimentTaskTable.Choice==optionsFile.cohort(cohortNo).dataFile.missedTrialCode) = NaN;
            ExperimentTaskTable.ResponseTime(ExperimentTaskTable.ResponseTime<=0.0)                                               = NaN;
            ExperimentTaskTable.Choice(ExperimentTaskTable.Choice==optionsFile.cohort(cohortNo).dataFile.missedTrialCode)         = NaN;
            %ExperimentTaskTable.RecepticalBeamBreak(ExperimentTaskTable.RecepticalBeamBreak<0) = NaN;

            if isempty(optionsFile.cohort(cohortNo).conditions) % if there arent any different conditions
                currCondition = [];
            end

            % create savepath and filename as a .mat file
            if ~contains(currTask,optionsFile.cohort(cohortNo).taskPrefix)
                currTask = [optionsFile.cohort(cohortNo).taskPrefix,currTask];
            end

            saveExpName  = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,[],currCondition,1,1,[]);
            saveInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,[],currCondition,1,1,'info');
            if optionsFile.cohort(cohortNo).taskRepetitions==1
                saveExpPath = [char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                    saveExpName,'.mat'];
                saveInfoPath = [char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                    saveInfoName,'.mat'];
            else
                saveExpPath = [char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                    saveExpName,'_',currTaskDate,'.mat'];
                saveInfoPath = [char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                    saveInfoName,'_',currTaskDate,'.mat'];
            end
            disp(['saving: ',saveExpPath]);
            disp(['saving: ',saveInfoPath]);
            save(saveExpPath,'ExperimentTaskTable');
            save(saveInfoPath,'MouseInfoTable');

        end %end of using startIndices to extract and save INDIVIDUAL MICE data
    end %end of searching for each TASK NAME in list in largeMEDPCFile
end %end of processing LARGE MEDPC file

%% create individual mouse tables from regular sized (<70,000 bytes) MEDPC files
disp(' ============== extracting from single mouse MEDPC output files ==================');
for iFile = 1:length(isLargeFile) %for each file in the data dir
    fileName     = string(allFiles(iFile).name);
    if startsWith(fileName,'._')
        fileName  = erase(fileName ,'._');
    end

    regMEDPCFile = readcell(fullfile(optionsFile.paths.cohort(cohortNo).rawData, fileName));
    currTask     = cell2mat(regMEDPCFile(10,2));  %TrialCode

    if contains(currTask,tasks(:))
        if size(regMEDPCFile,1)>optionsFile.cohort(cohortNo).nTrials
            % skip if file is not identified as regMEDPCFile or if the tasknames are
            % not found in the specified place
            if isLargeFile(iFile,1)==1
                continue
            else

                currMouse     = num2str(cell2mat(regMEDPCFile(4,2)));
                currTaskDate  = char(extractBetween(fileName,1,10));

                dataFileDescrCol = string(regMEDPCFile(:,1));
                disp(['proccessig iteration no ', num2str(iFile), ': ', currMouse, '...']);
                % find array indices
                %         TrialCodeIdx = find(contains(regMEDPCFile(:,2),optionsFile.cohort(cohortNo).dataFile.TrialCodeMarker{1}))+2;
                conditionIdx = find(strcmp(dataFileDescrCol,string(optionsFile.cohort(cohortNo).dataFile.ConditionMarker{1})));
                %         RLSIdx = find(contains(dataFileDescrCol,optionsFile.cohort(cohortNo).dataFile.RLSMarker{1}))+2;
                choiceIdx  = find(contains(dataFileDescrCol,string(optionsFile.cohort(cohortNo).dataFile.ChoiceMarker{1})),1,'last')+2;
                outcomeIdx = find(contains(dataFileDescrCol,string(optionsFile.cohort(cohortNo).dataFile.OutcomeMarker{1})),1,'last')+2;
                lPressTIdx = find(contains(dataFileDescrCol,string(optionsFile.cohort(cohortNo).dataFile.LeverPressTimeMarker{1})),1,'last')+2;
                % RBBIdx     = find(contains(dataFileDescrCol,string(optionsFile.cohort(cohortNo).dataFile.RecepticalBeamBreakMarker{1})),1,'last')+2;
                if isempty(choiceIdx)
                    %         TrialCodeIdx = find(contains(regMEDPCFile(:,2),optionsFile.cohort(cohortNo).dataFile.TrialCodeMarker{2}))+2;
                    %         RLSIdx = find(contains(dataFileDescrCol,optionsFile.cohort(cohortNo).dataFile.RLSMarker{2}))+2;
                    conditionIdx = find(strcmp(dataFileDescrCol,string(optionsFile.cohort(cohortNo).dataFile.ConditionMarker{2})));
                    choiceIdx  = find(contains(dataFileDescrCol,string(optionsFile.cohort(cohortNo).dataFile.ChoiceMarker{2})),1,'last')+2;
                    outcomeIdx = find(contains(dataFileDescrCol,string(optionsFile.cohort(cohortNo).dataFile.OutcomeMarker{2})),1,'last')+2;
                    lPressTIdx = find(contains(dataFileDescrCol,string(optionsFile.cohort(cohortNo).dataFile.LeverPressTimeMarker{2})),1,'last')+2;
                    % RBBIdx     = find(contains(dataFileDescrCol,string(optionsFile.cohort(cohortNo).dataFile.RecepticalBeamBreakMarker{2})),1,'last')+2;
                end


                % save data to table
                MouseInfoTable.Task      = currTask;
                MouseInfoTable.TaskDate  = currTaskDate;
                MouseInfoTable.Chamber   = cell2mat(regMEDPCFile(7,2));

                % save arrays into table
                ExperimentTaskTable.Choice(:)         = cell2mat(regMEDPCFile(choiceIdx:choiceIdx+optionsFile.cohort(cohortNo).nTrials-1,2));   %Choice_ABA1
                ExperimentTaskTable.Outcome(:)        = cell2mat(regMEDPCFile(outcomeIdx:outcomeIdx+optionsFile.cohort(cohortNo).nTrials-1,2)); %Outcome_ABA1
                ExperimentTaskTable.LeverPressTime(:) = cell2mat(regMEDPCFile(lPressTIdx:lPressTIdx+optionsFile.cohort(cohortNo).nTrials-1,2)); %LeverPressTime_ABA1
                ExperimentTaskTable.TrialStartTime(:) = transpose(0:optionsFile.cohort(cohortNo).trialDuration:(optionsFile.cohort(cohortNo).totalTaskDuration-optionsFile.cohort(cohortNo).trialDuration));
                ExperimentTaskTable.ResponseTime(:)   = ExperimentTaskTable.LeverPressTime - ExperimentTaskTable.TrialStartTime; %ResponseTime
                % ExperimentTaskTable.RecepticalBeamBreak(:)   = cell2mat(regMEDPCFile(RBBIdx:RBBIdx+optionsFile.cohort(cohortNo).nTrials-1,2)); %Receptical beambreak

                % get mouse sex and add to mouse info table
                if sum(strcmp(optionsFile.cohort(cohortNo).treatment.maleMice,currMouse))
                    MouseInfoTable.Sex = 'male';
                    if isempty(optionsFile.cohort(cohortNo).conditions)
                        currCondition = 'treatment';
                    else
                        currCondition = regMEDPCFile{conditionIdx,2};
                        if ismissing(string(regMEDPCFile(conditionIdx,2)))
                            currCondition = 'none';
                        end
                    end
                elseif sum(strcmp(optionsFile.cohort(cohortNo).control.maleMice,currMouse))
                    MouseInfoTable.Sex = 'male';
                    if isempty(optionsFile.cohort(cohortNo).conditions)
                        currCondition = 'control';
                    else
                        currCondition = regMEDPCFile{conditionIdx,2};
                        if ismissing(string(regMEDPCFile(conditionIdx,2)))
                            currCondition = 'none';
                        end
                    end
                elseif sum(strcmp(optionsFile.cohort(cohortNo).treatment.femaleMice,currMouse))
                    MouseInfoTable.Sex = 'female';
                    if isempty(optionsFile.cohort(cohortNo).conditions)
                        currCondition = 'treatment';
                    else
                        currCondition = regMEDPCFile{conditionIdx,2};
                        if ismissing(string(regMEDPCFile(conditionIdx,2)))
                            currCondition = 'none';
                        end
                    end
                elseif sum(strcmp(optionsFile.cohort(cohortNo).control.femaleMice,currMouse))
                    MouseInfoTable.Sex = 'female';
                    if isempty(optionsFile.cohort(cohortNo).conditions)
                        currCondition = 'control';
                    else
                        currCondition = regMEDPCFile{conditionIdx,2};
                        if ismissing(string(regMEDPCFile(conditionIdx,2)))
                            currCondition = 'none';
                        end
                    end
                else
                    disp('Current mouseID not found!')
                end


                MouseInfoTable.Condition= currCondition;
                % find where in tasks vector the current task is placed and
                % extracting index to be used to extract corresponding inputs
                idx = zeros(1,numel(tasks));
                for t = 1:numel(tasks)
                    idx(t) = strcmp([optionsFile.cohort(cohortNo).taskPrefix tasks{t}],currTask);
                end

                %input sequence
                ExperimentTaskTable.RewardingLeverSide = inputs(:,idx==1); % binary input sequence for task aka. RewardingLeverSide

                % Data correction,replace MEDPC omission code with NaN
                ExperimentTaskTable.Outcome(ExperimentTaskTable.Choice==optionsFile.cohort(cohortNo).dataFile.missedTrialCode)        = NaN;
                ExperimentTaskTable.LeverPressTime(ExperimentTaskTable.Choice==optionsFile.cohort(cohortNo).dataFile.missedTrialCode) = NaN;
                ExperimentTaskTable.ResponseTime(ExperimentTaskTable.ResponseTime<=0.0)                                               = NaN;
                ExperimentTaskTable.Choice(ExperimentTaskTable.Choice==optionsFile.cohort(cohortNo).dataFile.missedTrialCode)         = NaN;
                %ExperimentTaskTable.RecepticalBeamBreak(ExperimentTaskTable.RecepticalBeamBreak<0) = NaN;

                % create savepath and filename as a .mat file
                if ~contains(currTask,optionsFile.cohort(cohortNo).taskPrefix)
                    currTask = [optionsFile.cohort(cohortNo).taskPrefix,currTask];
                end

                if isempty(optionsFile.cohort(cohortNo).conditions) % if there arent any different conditions
                    currCondition = [];
                end

                saveExpName  = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,[],currCondition,1,1,[]);
                saveInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,[],currCondition,1,1,'info');
                if optionsFile.cohort(cohortNo).taskRepetitions==1
                    saveExpPath = [char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                        saveExpName,'.mat'];
                    saveInfoPath = [char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                        saveInfoName,'.mat'];
                else
                    saveExpPath = [char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                        saveExpName,'_',currTaskDate,'.mat'];
                    saveInfoPath = [char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                        saveInfoName,'_',currTaskDate,'.mat'];
                end
                save(saveExpPath,'ExperimentTaskTable');
                save(saveInfoPath,'MouseInfoTable');
            end
        end
    end
end
disp('all txt files read and saved as .mat files');
end
