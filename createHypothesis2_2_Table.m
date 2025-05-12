function createHypothesis2_2_Table

% Load options file
if exist('optionsFile.mat','file')==2
    load('optionsFile.mat');
else
    optionsFile = runOptions();
end

% Prespecify variables needed
iModel = 2;
iTask = 1;
nReps = 3;
cohortNo = 2;
subCohort = [];
currTask = optionsFile.cohort(cohortNo).testTask(1).name;
[mouseIDs, nSize] = getSampleVars(optionsFile, cohortNo, subCohort);

%% EXCLUDE MICE from this analysis
% Check available mouse data and exclusion criteria
noDataArray = zeros(1, nSize);
exclArray = zeros(1, nSize);

for iMouse = 1:nSize
    currMouse = mouseIDs{iMouse};
    loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], [], 1, nReps, 'info');
    if ~isfile([char(optionsFile.paths.cohort(cohortNo).data), 'mouse', char(currMouse), '_', loadInfoName, '.mat'])
        disp(['Data for mouse ', currMouse, ' not available']);
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
    loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], [], 1, nReps, 'info');
    load([char(optionsFile.paths.cohort(cohortNo).data), 'mouse', char(currMouse), '_', loadInfoName]);
    if any([MouseInfoTable.exclCrit2_met, MouseInfoTable.exclCrit1_met], 'all')
        disp(['Mouse ', currMouse, ' excluded based on exclusion criteria']);
        exclArray(iMouse) = iMouse;
    end
end

exclArray = sort(exclArray, 'descend');
exclArray(exclArray == 0) = [];

for i = exclArray
    mouseIDs(i) = [];
end
nSize = numel(mouseIDs);

% Create table with one row per mouse and columns for each repetition
RQ2_2_dataTable = table('Size', [nSize, 5], ...
    'VariableTypes', {'string', 'string', 'double', 'double', 'double'}, ...
    'VariableNames', {'ID', 'sex', 'omega2_rep1', 'omega2_rep2', 'omega2_rep3'});

% Populate the table with one row per mouse
for iMouse = 1:nSize
    currMouse = mouseIDs{iMouse};
    
    % Load basic info from rep 1 (for ID and sex)
    loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], [], 1, nReps, 'info');
    infoPath = [char(optionsFile.paths.cohort(cohortNo).data), 'mouse', char(currMouse), '_', loadInfoName, '.mat'];
    
    if isfile(infoPath)
        load(infoPath, 'MouseInfoTable');
        RQ2_2_dataTable.ID(iMouse) = currMouse;
        RQ2_2_dataTable.sex(iMouse) = MouseInfoTable.Sex;
    else
        RQ2_2_dataTable.ID(iMouse) = currMouse;
        RQ2_2_dataTable.sex(iMouse) = "";
    end
    
    % Get omega2 values for each repetition
    for iRep = 1:nReps
        loadName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], [], iRep, nReps, []);
        fitPath = [char(optionsFile.paths.cohort(cohortNo).results), 'mouse', char(currMouse), '_', ...
                  loadName, '_', optionsFile.dataFiles.rawFitFile{iModel}, '.mat'];
        
        % Column name for this repetition
        omega2_col = ['omega2_rep', num2str(iRep)];
        
        if isfile(fitPath)
            load(fitPath, 'est');
            % Extract omega2 parameter from the HGF 2-level model
            RQ2_2_dataTable.(omega2_col)(iMouse) = est.p_prc.om(2);
        else
            % If fit file doesn't exist, set omega2 to NaN
            RQ2_2_dataTable.(omega2_col)(iMouse) = NaN;
        end
    end
end

% Remove any rows with ALL NaN values across omega2 columns
allNanRows = isnan(RQ2_2_dataTable.omega2_rep1) & ...
             isnan(RQ2_2_dataTable.omega2_rep2) & ...
             isnan(RQ2_2_dataTable.omega2_rep3);

if any(allNanRows)
    RQ2_2_dataTable(allNanRows, :) = [];
    fprintf('Removed %d rows with no omega2 values across all repetitions.\n', sum(allNanRows));
end

% Save table as both .mat and .csv
savePath = [optionsFile.paths.cohort(cohortNo).groupLevel, optionsFile.cohort(cohortNo).taskPrefix, ...
    optionsFile.cohort(cohortNo).name, '_RQ2_2_dataTable'];

save([savePath, '.mat'], 'RQ2_2_dataTable');
writetable(RQ2_2_dataTable, [savePath, '.csv']);

disp(['Table saved to: ', savePath, '.csv']);
end