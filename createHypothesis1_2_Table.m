function createHypothesis1_2_Table

% load or run options for running this function
if exist('optionsFile.mat','file')==2
    load('optionsFile.mat');
else
    optionsFile = runOptions();
end


% prespecify variables needed for running this function
iModel  = 2; 
iTask   = 1; 
iRep    = 1; 
nReps   = 1;
cohortNo = 1;
subCohort = [];
currTask = optionsFile.cohort(cohortNo).testTask(1).name;
[mouseIDs,nSize] = getSampleVars(optionsFile,cohortNo,subCohort);

%% EXCLUDE MICE from this analysis
% check available mouse data and exclusion criteria
noDataArray = zeros(1,nSize);
exclArray   = zeros(1,nSize);

for iMouse = 1:nSize
    currMouse = mouseIDs{iMouse};
    loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,...
        [],[],iRep,nReps,'info');
    if isfile([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',loadInfoName,'.mat'])
    else
        disp(['data for mouse ', currMouse,' not available']);
        noDataArray(iMouse) = iMouse;
    end
end

noDataArray = sort(noDataArray,'descend');
noDataArray(noDataArray==0)=[];

for i=noDataArray
    mouseIDs(i) =[];
end
nSize = numel(mouseIDs);

for iMouse = 1:nSize
    currMouse = mouseIDs{iMouse};
    %%%
    loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,...
        [],[],iRep,nReps,'info');
    load([char(optionsFile.paths.cohort(cohortNo).data),...
        'mouse',char(currMouse),'_',loadInfoName]);
    if any([MouseInfoTable.exclCrit2_met,MouseInfoTable.exclCrit1_met],'all')
        disp(['mouse ', currMouse,' excluded based on exclusion criteria']);
        exclArray(iMouse) = iMouse;
    end
end

exclArray = sort(exclArray,'descend');
exclArray(exclArray==0)=[];

for i=exclArray
    mouseIDs(i) =[];
end
nSize = numel(mouseIDs);

% Create the table with proper variable types from the beginning
RQ1_2_dataTable = table('Size', [nSize, 4], ...
                        'VariableTypes', {'string', 'string', 'string', 'double'}, ...
                        'VariableNames', {'ID', 'sex', 'condition', 'omega2'});  % may change depending on model, could be more than one learning parameter

%% LOAD data
% Load data and populate table
    for iMouse = 1:nSize
        currMouse = mouseIDs{iMouse};
        
        % Load info file to get sex and condition
        loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], [], iRep, nReps, 'info');
        infoPath = [char(optionsFile.paths.cohort(cohortNo).data), 'mouse', char(currMouse), '_', loadInfoName, '.mat'];

        if isfile(infoPath)
            load(infoPath, 'MouseInfoTable');
            RQ1_2_dataTable.ID(iMouse) = currMouse;
            RQ1_2_dataTable.sex(iMouse) = MouseInfoTable.Sex;
            RQ1_2_dataTable.condition(iMouse) = MouseInfoTable.Condition;

        end

        % Load model fit results to get omega2 
        loadName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], [], iRep, nReps, []);
        fitPath = [char(optionsFile.paths.cohort(cohortNo).results), 'mouse', char(currMouse), '_', ...
                  loadName, '_', optionsFile.dataFiles.rawFitFile{iModel}, '.mat'];
        
        if isfile(fitPath)
            load(fitPath, 'est');
            % Extract omega2 parameter from the HGF 2-level model
            RQ1_2_dataTable.omega2(iMouse) = est.p_prc.om(2);  % Access omega2 (level 2 parameter)
        end
    end

    % Save table as both .mat and .csv
    savePath = [optionsFile.paths.cohort(cohortNo).groupLevel, optionsFile.cohort(cohortNo).taskPrefix, ...
               optionsFile.cohort(cohortNo).name, '_RQ1_2_dataTable'];
    
    save([savePath, '.mat'], 'RQ1_2_dataTable');
    writetable(RQ1_2_dataTable, [savePath, '.csv']);
    
    disp(['Table saved to: ', savePath, '.csv']);
end