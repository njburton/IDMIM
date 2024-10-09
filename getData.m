function optionsFile = getData(optionsFile)
%% runOptions
% - set all relevant paths, global variables
% - specify what analysis steps should be executed when running "runAnalysis"
% - make directories and folderstructure for data if needed
%
%  SYNTAX:  getData
%  INPUT:  optionsFile
%  OUTPUT: optionsFile, updated after reading the data
%
% Original: 30/5/2023; Katharina Wellstein
% Amended: 23/2/2024; Nicholas Burton
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

%% DATA EXTRACTION & PREPARATION
% Extract data from MED-PC output file (.xlsx) and save as matlab file.
% Create empty table for individual mouse with variable names as columns
TaskTableVarTypes = {'string','double','double','double','double','double','double','double'};
TaskTableVarNames = {'TrialCode','RewardingLeverSide','Choice','Outcome','TrialStartTime','LeverPressTime','ResponseTime','RecepticalBeamBreak'};
ExperimentTaskTable = table('Size',[180 length(TaskTableVarNames)],'VariableTypes', TaskTableVarTypes,'VariableNames',TaskTableVarNames);

% For loop which creates individual mouse tables from rawTaskData file
% (where each column is a mouse)
files = dir(fullfile(optionsFile.paths.rawMouseDataDir,'*Subject *.txt'));

for i = 1:optionsFile.Task.nSize
    fileName  = string(files(i).name);
    currMouse = extract(fileName ," "+digitsPattern(3)+"."); %find three digits between space and .
    currMouse = erase(currMouse{end}," ");
    currMouse = erase(currMouse,".");
    data      = readcell(fullfile(optionsFile.paths.rawMouseDataDir, fileName));
    [~,cols]  = size(cell2mat(data(50,2)));

    if cols<10 % if yes, based on old version of saving data with the
        % second column saving 4 entries in one cell
        % find array indices
        choiceIdx  = find(contains(data(:,1),optionsFile.DataFile.ChoiceMarker))+2;
        outcomeIdx = find(contains(data(:,1),optionsFile.DataFile.OutcomeMarker))+2;
        lPressTIdx = find(contains(data(:,1),optionsFile.DataFile.LeverPressTimeMarker))+2;
        RBBIdx = find(contains(data(:,1),optionsFile.DataFile.RecepticalBeamBreakMarker))+2;

        % save arrays into table
        ExperimentTaskTable.Choice                = cell2mat(data(choiceIdx:choiceIdx+optionsFile.Task.nTrials-1,2));   %Choice_ABA1
        ExperimentTaskTable.Outcome               = cell2mat(data(outcomeIdx:outcomeIdx+optionsFile.Task.nTrials-1,2)); %Outcome_ABA1
        ExperimentTaskTable.LeverPressTime        = cell2mat(data(lPressTIdx:lPressTIdx+optionsFile.Task.nTrials-1,2)); %LeverPressTime_ABA1
        ExperimentTaskTable.TrialStartTime        = (0:20:3580)'; %TrialStartTime list every 20seconds
        ExperimentTaskTable.ResponseTime          = ExperimentTaskTable.LeverPressTime - ExperimentTaskTable.TrialStartTime; %ResponseTime
        ExperimentTaskTable.RecepticalBeamBreak   = cell2mat(data(RBBIdx:RBBIdx+optionsFile.Task.nTrials-1,2)); %Receptical beambreak
        optionsFile.Task.MouseID(i,:) = string(currMouse);

        %% Load binary sequence for rewardlever side so we can use as input for analysis using hgf.
        % HGF Binary sequence for RewardingLeverSide (1=leftlever, 0=rightlever)
        ExperimentTaskTable.RewardingLeverSide = optionsFile.Task.inputs; % Binary sequence for rewarding lever side (1=left, 0=right)

        %Data correction
        ExperimentTaskTable.Choice(ExperimentTaskTable.Choice==3) = NaN;  % Replace omissions (3 in Choice) with NaN
        ExperimentTaskTable.RecepticalBeamBreak(ExperimentTaskTable.RecepticalBeamBreak<0) = NaN;

        save([char(optionsFile.paths.resultsDir),'/mouse',char(currMouse)],'ExperimentTaskTable');

    else
        disp(['Mouse: ', char(currMouse), 'is not saved in the right format for this analysis. ...' ...
            'This may be because it was only training data or there is something wrong with formatting. Please make sure to check manually.']);
    end

end

%Search MouseIDs for any index's that are 'NaN's and remove them
optionsFile.Task.MouseID(find(isnan(optionsFile.Task.MouseID)))=[];
%Adjust index value of Task.nSize if mouseIDs were removed by above process
optionsFile.Task.nSize = length(optionsFile.Task.MouseID);

end
