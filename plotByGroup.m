function plotByGroup
%% plotByGroup - Process and extract experimental task data from MED-PC files
%
% SYNTAX:  getData(optionsFile)
% INPUT:   optionsFile - Structure containing analysis options and paths
% OUTPUT:  optionsFile - Updated structure after data processing
%
% Authors: Katharina Wellstein (30/5/2023), Nicholas Burton (23/2/2024)
% -------------------------------------------------------------------------

load('optionsFile.mat');

%Perform omission criteria check. If passed, fill arrays with each column being a mouse and each row is a trial in the
%task
if isfile(char(fullfile(optionsFile.paths.databaseDir, optionsFile.fileName.dataBaseFileName))) == 1
    load(char(fullfile(optionsFile.paths.databaseDir, optionsFile.fileName.dataBaseFileName)));
else; error('No file found: Check directory for data base file containing dataset info')
end

%% @@NB: Should change the check to compare the file string name to an ongoing list of "already processed an saved this file"
if isfile(char(fullfile(optionsFile.paths.databaseDir, optionsFile.fileName.dataBaseFileName))) == 1
    allFiles = dir(optionsFile.paths.mouseModelFitFilesDir);
    allFiles(~[allFiles.isdir])
else; error('No file found: Check directory for data base file containing dataset info')
end

% Initialise Experiment Task Table
taskTableVarTypes = {'string','string','string','string'};
taskTableVarNames = {'MouseID','Control','Male', 'Female'};
ExperimentTaskTable = table('Size',[length(rawDataFileInfo.MouseId) length(taskTableVarNames)],...
    'VariableTypes', taskTableVarTypes,...
    'VariableNames',taskTableVarNames);



