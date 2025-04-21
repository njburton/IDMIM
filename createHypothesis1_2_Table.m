function createHypothesis1_2_Table

% load or run options for running this function
if exist('optionsFile.mat','file')==2
    load('optionsFile.mat');
else
    optionsFile = runOptions();
end


% prespecify variables needed for running this function
iModel  = 1; %% @ NICK: !!! SPECIFY WHAT MODEL SHOULD GO IN HERE, i.e. index in optionsFile.model.space
iTask   = 1; 
iRep    = 1; 
nReps   = 1;
currTask = optionsFile.cohort(cohortNo).testTask(1).name;
[mouseIDs,nSize] = getSampleVars(optionsFile,cohortNo,subCohort);

%% EXCLUDE MICE from this analysis
% check available mouse data and exclusion criteria
noDataArray = zeros(1,nSize);
exclArray   = zeros(1,nSize);

for iMouse = 1:nSize
    currMouse = mouseIDs{iMouse};
    loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,...
        [],currCondition,iRep,nReps,'info');
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
    loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,...
        [],currCondition,iRep,nReps,'info');
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

RQ1_2_dataTable = array2table(zeros(nSize,4), 'VariableNames',{'ID','sex','condition',...
    'learning parameter'}); % may change depending on model, could be more than one learning parameter
RQ1_2_dataTable.varTypes = {'string','string','string','double'};


%% LOAD data
% load modeling data
for iSubCohort = 1:nSubCohorts
    optionsFile.cohort(1).subCohorts{iSubCohort};

    loadName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,...
        [],currCondition,iRep,nReps,[]);
    loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,...
        [],currCondition,iRep,nReps,'info');
    for iMouse =1:nSize
        currHouse = mouseIDs{iMouse};
        load([char(optionsFile.paths.cohort(cohortNo).results),...
            'mouse',char(currMouse),'_',loadName,'_',optionsFile.dataFiles.rawFitFile{iModel},'.mat']);

        for iPrc = 1:length(optionsFile.modelSpace(iModel).prc_idx) % this can only really be done once we know what model and parameters we will be using
            param(iPrc).subCohort(iSubCohort).value = est(iMouse,iModel).task(iTask,iRep).data.est.p_prc.ptrans(optionsFile.modelSpace(iModel).prc_idx);
        end

       load([char(optionsFile.paths.cohort(cohortNo).results),...
            'mouse',char(currMouse),'_',loadInfoName,'_',optionsFile.dataFiles.rawFitFile{iModel},'.mat']);
       RQ1_2_dataTable.ID(iMouse,:)         = currMouse;
       RQ1_2_dataTable.sex(iMouse,:)        = mouseInfoTable.sex(iMouse);
       RQ1_2_dataTable.condition(iMouse,:)  = mouseInfoTable.condition(iMouse);
    end
end

%% SAVE table
save([optionsFile.paths.cohort(cohortNo).groupLevel,optionsFile.cohort(cohortNo).taskPrefix,...
            optionsFile.cohort(cohortNo).name,'_RQ1_2_dataTable.mat'],'RQ1_2_dataTable');
writetable(groupTable,[optionsFile.paths.cohort(cohortNo).groupLevel,optionsFile.cohort(cohortNo).taskPrefix,...
            optionsFile.cohort(cohortNo).name,'_RQ1_2_dataTable.csv']);

end