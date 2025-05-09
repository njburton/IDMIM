function createHypothesis2_2_Table

% load or run options for running this function
if exist('optionsFile.mat','file')==2
    load('optionsFile.mat');
else
    optionsFile = runOptions();
end


% prespecify variables needed for running this function
nModels = 3;
iTask   = 1;
iRep    = 1;
nReps   = 3;
cohortNo = 2;
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

RQ1_2_dataTable = array2table(zeros(nSize,4), 'VariableNames',{'ID','sex',...
    'learning param rep1',...}); % add other columns
    RQ1_2_dataTable.varTypes = {'string','string','string','double','double','double'};


    %% LOAD data
    % load modeling data
    for iMouse = 1:nSize

    loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,...
        [],[],1,1,'info');
    currMouse = mouseIDs{iMouse};
        load([char(optionsFile.paths.cohort(cohortNo).data),...
        'mouse',char(currMouse),'_',loadInfoName]);
        
    ID(iMouse,:)         = currMouse;
    sex(iMouse,:)        = mouseInfoTable.sex(iMouse);
    condition(iMouse,:)  = mouseInfoTable.condition(iMouse);

    for iModel = 1:nModels
        for iCondition = 1:nConditions
            for iRep=1:nReps
                loadName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,...
                    [],[],iRep,nReps,[]);
                load([char(optionsFile.paths.cohort(cohortNo).results),...
                    'mouse',char(currMouse),'_',loadName,'_',optionsFile.dataFiles.rawFitFile{iModel},'.mat']);

                for iPrc = 1:length(optionsFile.modelSpace(iModel).prc_idx) % get indices for free model params of current model
                    % struct for all params
                    if iModel == 1
                        param(iPrc).rep(iRep).value(iMouse) = est(iMouse,iModel).task(iTask,iRep).data.est.p_prc.ptrans(optionsFile.modelSpace(iModel).prc_idx);
                        RQ2_2_dataTable_M1.learningParam_rep1(:,:) = ; % add all values here
                    elseif iModel ==2
                        RQ2_2_dataTable_M2.learningParam_rep1(:,:) = ; % add all values here
                    else
                        RQ2_2_dataTable_M3.learningParam_rep1(:,:) = ; % add all values here
                    end

                end
            end
        end


% append mouse info table to all individual model tables

addvars(RQ2_2_dataTable_M1,sex,condition,ID,LOCATION) % add variables to each table sex, condition, ID variable




        %% SAVE table
        save([optionsFile.paths.cohort(cohortNo).groupLevel,optionsFile.cohort(cohortNo).taskPrefix,...
            optionsFile.cohort(cohortNo).name,'_RQ1_2_dataTable.mat'],'RQ1_2_dataTable');
        writetable(groupTable,[optionsFile.paths.cohort(cohortNo).groupLevel,optionsFile.cohort(cohortNo).taskPrefix,...
            optionsFile.cohort(cohortNo).name,'_RQ1_2_dataTable.csv']);

    end