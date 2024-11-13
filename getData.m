function optionsFile = getData(optionsFile)
%% getData - Process and extract experimental task data from MED-PC files
%
% SYNTAX:  getData(optionsFile)
% INPUT:   optionsFile - Structure containing analysis options and paths
% OUTPUT:  optionsFile - Updated structure after data processing
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
tic
load("optionsFile.mat"); %load file to access paths
largeFileThreshold = 70000;

% Initialise Experiment Task Table
taskTableVarTypes = {'string','string','double','double','double','double',...
    'double','double','double','single'};
taskTableVarNames = {'Task','TaskDate','RewardingLeverSide','Choice',...
    'Outcome','TrialStartTime','LeverPressTime','ResponseTime',...
    'RecepticalBeamBreak','Chamber'};
ExperimentTaskTable = table('Size',[optionsFile.task.nTrials length(taskTableVarNames)],...
    'VariableTypes', taskTableVarTypes,...
    'VariableNames',taskTableVarNames);

%% check for large files where multiple mice are saved into a single raw MED-PC file
allFiles = dir(fullfile(optionsFile.paths.dataToAnalyse,'*.*'));
allFiles = allFiles(3:end); %removes Unix subfolder pointers "." and ".."
fileCategory = zeros(length(allFiles),1);

for fileSizei = 1:length(allFiles)
    if allFiles(fileSizei).bytes >= largeFileThreshold % 1 = true; individualMouseMECPDCFile is 63,140 bytes
        fileCategory(fileSizei,1) = 1; %1 = to process
    else
        continue
    end %end of check if file is overly large (>100,000 bytes)
end %end of check for files with .file in dataToAnalyse dir

%check if filesToProcess is empty of if there are identified large files to deconstruct
if ~isempty(fileCategory(:,1)); disp('Large (>70,000 bytes) MED-PC file found.');
else disp('No large files detected.'); end %If filesToProcess is NOT empty, meaning there are files to process (extract individual mice)

% list containing the medpcTaskNames you want to look for and extract
taskSearchList = optionsFile.task.taskList;
if isempty(taskSearchList); error('Task search list is empty. Check optionsFiles task list has at least 1 entry.'); end

%for each large file found
for largeFilei = 1:length(fileCategory)
    if fileCategory(largeFilei,1) == 0 %skip if file is not identified as large (0) in filesToProcess
        continue
    else
        fileName              = string(allFiles(largeFilei).name);
        largeMEDPCFile        = readtable(fullfile(optionsFile.paths.dataToAnalyse,filesep,fileName));
        for operantTaski      = 1:length(taskSearchList) %for each task name in the task list
            startIndices      = find(contains(largeMEDPCFile.Var2,taskSearchList(operantTaski)));
            
            %checkpoint to throw error if startIndices extract non-interger
            %value and also before (cell above) and after( cell above)
            
            for startIndicesi = 1:length(startIndices) %row index for all mentions of taskListi
                currMouse     = cell2mat(largeMEDPCFile.Var2(startIndices(startIndicesi)-6));
                currTaskDate  = cell2mat(largeMEDPCFile.Var2(startIndices(startIndicesi)-8));
                currTaskDate  = replace(currTaskDate,'/','-');

                % save data to table
                ExperimentTaskTable.Task(:)                = taskSearchList(operantTaski);  %TrialCode
                ExperimentTaskTable.TaskDate(:)            = currTaskDate;
                ExperimentTaskTable.Outcome                = str2num(cell2mat(largeMEDPCFile.Var2((startIndices(startIndicesi)+optionsFile.dataFile.outcomeOffset+1):(startIndices(startIndicesi)+optionsFile.dataFile.outcomeOffset+optionsFile.task.nTrials))));   %Outcome 0=time,1=reward
                ExperimentTaskTable.Choice                 = str2num(cell2mat(largeMEDPCFile.Var2((startIndices(startIndicesi)+optionsFile.dataFile.choiceOffset+1):(startIndices(startIndicesi)+optionsFile.dataFile.choiceOffset+optionsFile.task.nTrials))));   %Choice 0=left,1=right
                ExperimentTaskTable.TrialStartTime         = transpose(0:optionsFile.task.trialDuration:(optionsFile.task.totalTaskDuration-13)); % TrialStartTime. Total task time is 3640 but the last trial begins at 3627
                %ExperimentTaskTable.RecepticalBeamBreak   = cell2mat(largeMEDPCFile.Var2((startIndices(startIndicesi)+optionsFile.dataFile.recepticalBeamBreakOffset+1):(startIndices(startIndicesi)+optionsFile.dataFile.recepticalBeamBreakOffset+optionsFile.task.nTrials)));   %RecepticalBeamBreak
                ExperimentTaskTable.LeverPressTime         = str2double(largeMEDPCFile.Var2((startIndices(startIndicesi)+optionsFile.dataFile.leverPressTimeOffset+1):(startIndices(startIndicesi)+optionsFile.dataFile.leverPressTimeOffset+optionsFile.task.nTrials)));
                ExperimentTaskTable.ResponseTime           = ExperimentTaskTable.LeverPressTime - ExperimentTaskTable.TrialStartTime; %time between trialStart and leverPress
                ExperimentTaskTable.Chamber(:)             = str2num(cell2mat(largeMEDPCFile.Var2((startIndices(startIndicesi)-3))));

                %input sequence
                binInputSeq  = rows2vars(readtable(fullfile([char(optionsFile.paths.binInputSeqDir),filesep,'2024_HGFPilot3',...
                    filesep,char(taskSearchList(operantTaski)),'.txt']))); %RewardingLeverSide
                ExperimentTaskTable.RewardingLeverSide     = binInputSeq.Var1; % binary input sequence for task aka. RewardingLeverSide

                %verifyExperimentSequence
                checkPoint = verifyExperimentSequence(ExperimentTaskTable);
                if checkPoint == false; error(['InputSeqCheckpoint: Detected error between RewardingSideLever binInputSequence' ...
                        'and task outcome. Troubleshoot by checking input values in ExperimentTaskTable.RewardingLeverSide,'...
                        'and .Outcomes as well as. Choice.'])
                    %save diary and turn off diary; 
                end

                % Data correction
                ExperimentTaskTable.Outcome(ExperimentTaskTable.Choice==3)              = NaN;
                ExperimentTaskTable.LeverPressTime(ExperimentTaskTable.Choice==3)       = NaN;
                ExperimentTaskTable.ResponseTime(ExperimentTaskTable.ResponseTime<=0.0) = NaN;
                ExperimentTaskTable.Choice(ExperimentTaskTable.Choice==3)               = NaN;
                %ExperimentTaskTable.RecepticalBeamBreak(ExperimentTaskTable.RecepticalBeamBreak<0) = NaN;

                % Save with conditions included
                savePathAndName1 = [char(optionsFile.paths.mouseMatFilesDir),filesep,...
                    'mouse',char(currMouse),'_',char(taskSearchList(operantTaski)),'_date',char(currTaskDate),'.mat'];
                save(savePathAndName1,'ExperimentTaskTable');

            end %end of using startIndices to extract and save individual mice data
        end %end of searching for each taskName in list in largeMEDPCFile
    end %end of checking filesToProcess vector
end %end of processing large MEDPC file

%% STEP 2: For loop which creates individual mouse tables from regular sized (<70,000 bytes) MEDPC files
disp('Now extracting from normal MEDPC output files');
for regFilei = 1:length(fileCategory) %for each file in the dataToAnalyse dir
    fileName     = string(allFiles(regFilei).name);
    regMEDPCFile = readcell(fullfile(optionsFile.paths.dataToAnalyse, fileName));
    if fileCategory(regFilei,1) || ~contains(regMEDPCFile(10,2),optionsFile.task.taskList) == 1 %skip if file is not identified as regMEDPCFile (0) in fileCategory
        continue
    else
        currMouse    = num2str(cell2mat(regMEDPCFile(4,2)));
        currTaskDate = extractBetween(fileName,1,10);
        % save to table
        ExperimentTaskTable.Task(:)                = cell2mat(regMEDPCFile(10,2));  %TrialCode
        ExperimentTaskTable.TaskDate(:)            = currTaskDate;
        ExperimentTaskTable.Outcome                = cell2mat(regMEDPCFile((optionsFile.dataFile.outcomeOffset+11):(optionsFile.dataFile.outcomeOffset+10+optionsFile.task.nTrials),2));   %Outcome 0=time,1=reward
        ExperimentTaskTable.Choice                 = cell2mat(regMEDPCFile((optionsFile.dataFile.choiceOffset+11):(optionsFile.dataFile.choiceOffset+10+optionsFile.task.nTrials),2));   %Choice 0=left,1=right
        ExperimentTaskTable.TrialStartTime         = transpose(0:optionsFile.task.trialDuration:(optionsFile.task.totalTaskDuration-13)); % TrialStartTime. Total task time is 3640 but the last trial begins at 3627
        %ExperimentTaskTable.RecepticalBeamBreak   = cell2mat(regMEDPCFile((startIndices(startIndicesi)+optionsFile.dataFile.recepticalBeamBreakOffset+1):(startIndices(startIndicesi)+optionsFile.dataFile.recepticalBeamBreakOffset+optionsFile.task.nTrials)));   %RecepticalBeamBreak
        ExperimentTaskTable.LeverPressTime         = cell2mat(regMEDPCFile((optionsFile.dataFile.leverPressTimeOffset+11):(optionsFile.dataFile.leverPressTimeOffset+10+optionsFile.task.nTrials),2));
        ExperimentTaskTable.ResponseTime           = ExperimentTaskTable.LeverPressTime - ExperimentTaskTable.TrialStartTime; %time between trialStart and leverPress
        ExperimentTaskTable.Chamber(:)             = cell2mat(regMEDPCFile(7,2));
        currTask = regMEDPCFile(10,2);

        %input sequence
        binInputSeq  = rows2vars(readtable(fullfile([char(optionsFile.paths.binInputSeqDir),'2024_HGFPilot3',filesep,char(currTask),'.txt']))); %RewardingLeverSide
        ExperimentTaskTable.RewardingLeverSide     = binInputSeq.Var1; % binary input sequence for task aka. RewardingLeverSide

        %verifyExperimentSequence
        checkPoint = verifyExperimentSequence(ExperimentTaskTable);
        if checkPoint == false; error(['InputSeqCheckpoint: Detected error between RewardingSideLever binInputSequence' ...
                'and task outcome. Troubleshoot by checking input values in ExperimentTaskTable.RewardingLeverSide,'...
                'and .Outcomes as well as. Choice.']); 
        end

        % Data correction
        ExperimentTaskTable.Outcome(ExperimentTaskTable.Choice==3)              = NaN;
        ExperimentTaskTable.LeverPressTime(ExperimentTaskTable.Choice==3)       = NaN;
        ExperimentTaskTable.ResponseTime(ExperimentTaskTable.ResponseTime<=0.0) = NaN;
        ExperimentTaskTable.Choice(ExperimentTaskTable.Choice==3)               = NaN;
        %ExperimentTaskTable.RecepticalBeamBreak(ExperimentTaskTable.RecepticalBeamBreak<0) = NaN;

        % create savepath and filename as a .mat file
        savePathAndName2 = [char(optionsFile.paths.mouseMatFilesDir),filesep,...
            'mouse',char(currMouse),'_',char(currTask),'_date',char(currTaskDate),'.mat'];
        save(savePathAndName2,'ExperimentTaskTable'); %save

    end
end

optionsFile.task.MouseID(find(isnan(optionsFile.task.MouseID)))=[]; % Search MouseIDs for any index's that are 'NaN's and remove them
optionsFile.cohort.nSize = length(optionsFile.task.MouseID); % Adjust index value of cohort.nSize if mouseIDs were removed by above process

toc
end
