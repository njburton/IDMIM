function createHypothesis3_2_Table

% Load options file
if exist('optionsFile.mat','file')==2
    load('optionsFile.mat');
else
    optionsFile = runOptions();
end

% Prespecify variables needed
iModel = 2;
iTask = 1;
iRep = 1;
nReps = 1;
cohortNo = 3;
subCohort = [];
currTask = optionsFile.cohort(cohortNo).testTask(1).name;
[mouseIDs, nSize] = getSampleVars(optionsFile, cohortNo, subCohort);

%% EXCLUDE MICE from this analysis
% Check available mouse data and exclusion criteria
noDataArray = zeros(1, nSize);
exclArray = zeros(1, nSize);

for iMouse = 1:nSize
    currMouse = mouseIDs{iMouse};
    % Check if data exists for any condition
    hasData = false;
    for iCond = 1:length(optionsFile.cohort(cohortNo).conditions)
        loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], optionsFile.cohort(cohortNo).conditions{iCond}, iRep, nReps, 'info');
        if isfile([char(optionsFile.paths.cohort(cohortNo).data), 'mouse', char(currMouse), '_', loadInfoName, '.mat'])
            hasData = true;
            break;
        end
    end
    if ~hasData
        disp(['Data for mouse ', currMouse, ' not available in any condition']);
        noDataArray(iMouse) = iMouse;
    end
end

noDataArray = sort(noDataArray, 'descend');
noDataArray(noDataArray == 0) = [];

for i = noDataArray
    mouseIDs(i) = [];
end
nSize = numel(mouseIDs);

for iMouse = 1:nSize
    currMouse = mouseIDs{iMouse};
    for iCond = 1:length(optionsFile.cohort(cohortNo).conditions)
        loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], optionsFile.cohort(cohortNo).conditions{iCond}, iRep, nReps, 'info');
        if isfile([char(optionsFile.paths.cohort(cohortNo).data), 'mouse', char(currMouse), '_', loadInfoName, '.mat'])
            load([char(optionsFile.paths.cohort(cohortNo).data), 'mouse', char(currMouse), '_', loadInfoName]);
            if any([MouseInfoTable.exclCrit2_met, MouseInfoTable.exclCrit1_met], 'all')
                disp(['Mouse ', currMouse, ' excluded based on exclusion criteria']);
                exclArray(iMouse) = iMouse;
                break;
            end
        end
    end
end

exclArray = sort(exclArray, 'descend');
exclArray(exclArray == 0) = [];

for i = exclArray
    mouseIDs(i) = [];
end
nSize = numel(mouseIDs);

% Create table with one row per mouse and columns for each condition
RQ3_2_dataTable = table('Size', [nSize, 5], ...
    'VariableTypes', {'string', 'string', 'double', 'double', 'double'}, ...
    'VariableNames', {'ID', 'sex', 'omega2_saline', 'omega2_5mg', 'omega2_10mg'});

% Populate the table
for iMouse = 1:nSize
    currMouse = mouseIDs{iMouse};
    
    % Set ID
    RQ3_2_dataTable.ID(iMouse) = currMouse;
    
    % Get basic info (sex) from the first available condition file
    for iCond = 1:length(optionsFile.cohort(cohortNo).conditions)
        loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], optionsFile.cohort(cohortNo).conditions{iCond}, iRep, nReps, 'info');
        infoPath = [char(optionsFile.paths.cohort(cohortNo).data), 'mouse', char(currMouse), '_', loadInfoName, '.mat'];
        
        if isfile(infoPath)
            load(infoPath, 'MouseInfoTable');
            RQ3_2_dataTable.sex(iMouse) = MouseInfoTable.Sex;
            break;
        end
    end
    
    % Get omega2 for each condition
    % Saline condition
    loadName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], 'saline', iRep, nReps, []);
    fitPath = [char(optionsFile.paths.cohort(cohortNo).results), 'mouse', char(currMouse), '_', ...
              loadName, '_', optionsFile.dataFiles.rawFitFile{iModel}, '.mat'];
    
    if isfile(fitPath)
        load(fitPath, 'est');
        RQ3_2_dataTable.omega2_saline(iMouse) = est.p_prc.om(2);
    else
        RQ3_2_dataTable.omega2_saline(iMouse) = NaN;
    end
    
    % 5mg condition
    loadName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], '5mg', iRep, nReps, []);
    fitPath = [char(optionsFile.paths.cohort(cohortNo).results), 'mouse', char(currMouse), '_', ...
              loadName, '_', optionsFile.dataFiles.rawFitFile{iModel}, '.mat'];
    
    if isfile(fitPath)
        load(fitPath, 'est');
        RQ3_2_dataTable.omega2_5mg(iMouse) = est.p_prc.om(2);
    else
        RQ3_2_dataTable.omega2_5mg(iMouse) = NaN;
    end
    
    % 10mg condition
    loadName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], '10mg', iRep, nReps, []);
    fitPath = [char(optionsFile.paths.cohort(cohortNo).results), 'mouse', char(currMouse), '_', ...
              loadName, '_', optionsFile.dataFiles.rawFitFile{iModel}, '.mat'];
    
    if isfile(fitPath)
        load(fitPath, 'est');
        RQ3_2_dataTable.omega2_10mg(iMouse) = est.p_prc.om(2);
    else
        RQ3_2_dataTable.omega2_10mg(iMouse) = NaN;
    end
end

% Remove any rows with ALL NaN values across omega2 columns
allNanRows = isnan(RQ3_2_dataTable.omega2_saline) & ...
             isnan(RQ3_2_dataTable.omega2_5mg) & ...
             isnan(RQ3_2_dataTable.omega2_10mg);

if any(allNanRows)
    RQ3_2_dataTable(allNanRows, :) = [];
    fprintf('Removed %d rows with no omega2 values across all conditions.\n', sum(allNanRows));
end

% Save table as both .mat and .csv
savePath = [optionsFile.paths.cohort(cohortNo).groupLevel, optionsFile.cohort(cohortNo).taskPrefix, ...
    optionsFile.cohort(cohortNo).name, '_RQ3_2_dataTable'];

save([savePath, '.mat'], 'RQ3_2_dataTable');
writetable(RQ3_2_dataTable, [savePath, '.csv']);

disp(['Table saved to: ', savePath, '.csv']);
end