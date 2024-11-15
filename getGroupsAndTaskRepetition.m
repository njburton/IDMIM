function getGroupsAndTaskRepetition

%% getGroupsAndTaskOrder
%
%  SYNTAX:  fitModels
%
%  OUTPUT:
%
% Original: XX; Nicholas Burton
% -------------------------------------------------------------------------
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
load("optionsFile.mat") % load file paths

% search through MatFiles
dirFiles = dir(fullfile(optionsFile.paths.mouseMatFilesDir,'*.mat'));
allFilenames = {dirFiles.name}';

tableVarTypes = {'string','string','string','string','single','string','string'};
tableVarNames = {'MouseID','TaskDate','TaskPath','Task','TaskRepetition','sex','group'};
groupTable    = table('Size',[length(allFilenames) length(tableVarNames)],...
    'VariableTypes', tableVarTypes,...
    'VariableNames',tableVarNames);

% fill table from fileNames
for filei = 1:length(allFilenames)
    groupTable.MouseID(filei)  = extractBetween(allFilenames(filei),'mouse',['_',optionsFile.task.taskPrefix]);
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
rawDataFileInfo = sortrows(groupTable,"TaskDate","ascend");
mouseIDList = unique(rawDataFileInfo.MouseID);
startPoint = 0;
for taski = 1:length(optionsFile.task.taskList)
    currTask = erase(optionsFile.task.taskList(taski),[optionsFile.task.taskPrefix,'_']);
    for mousei = 1:length(mouseIDList)
        currMouse = mouseIDList(mousei);
        for rowi = 1:length(allFilenames)
            if strcmp(currMouse, rawDataFileInfo.MouseID(rowi)) && ...
                    strcmp(currTask,rawDataFileInfo.Task(rowi)) == 1
                startPoint = startPoint + 1;
                rawDataFileInfo.TaskRepetition(rowi) = startPoint;
            else
                continue
            end
        end
        startPoint = 0;
    end
end

%% Fill in sex and group columns
for rowi = 1:length(rawDataFileInfo.sex)
    if sum(strcmp(rawDataFileInfo.MouseID(rowi),optionsFile.cohort.maleMice)) >= 1
        rawDataFileInfo.sex(rowi) = "Male";
    else
        rawDataFileInfo.sex(rowi) = "Female";
    end
end

%% Fill in group columns
for rowi = 1:length(rawDataFileInfo.sex)
    if sum(strcmp(rawDataFileInfo.MouseID(rowi),optionsFile.cohort.controlGroup)) >= 1
        rawDataFileInfo.group(rowi) = "Control";
    else
        rawDataFileInfo.group(rowi) = "Treatment";
    end
end

%% save file
savePath = [char(optionsFile.paths.databaseDir),filesep,optionsFile.fileName.dataBaseFileName];
save(savePath,"rawDataFileInfo");

end