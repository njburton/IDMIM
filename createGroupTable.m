function createGroupTable(cohortNo)

% function that groups mouseInfotables,

%% INITIALIZE Variables for running this function
% specifications for this analysis
if exist('optionsFile.mat','file')==2
    load('optionsFile.mat');
else
    optionsFile = runOptions();
end

% get sample specifics for loops
if  numel(optionsFile.cohort(cohortNo).conditions)==0
    nConditions = 1;
    currCondition = [];
else
    nConditions = numel(optionsFile.cohort(cohortNo).conditions);

end

[mouseIDs,nSize] = getSampleSpecs(optionsFile,cohortNo,[]);

nTasks   = numel(optionsFile.cohort(cohortNo).testTask);
nReps    = optionsFile.cohort(cohortNo).taskRepetitions;
nLevels  = nTasks*nConditions*nReps;
mouseIDCol = repmat(mouseIDs,1,nLevels);


%% LOAD individual info files and concatenate tables
for iCondition = 1:nConditions
    if nConditions>1
        currCondition = optionsFile.cohort(cohortNo).conditions{iCondition};
    end

    for iTask = 1:nTasks
        currTask = optionsFile.cohort(cohortNo).testTask(iTask).name;

        for iRep = 1:nReps
            for iMouse = 1:nSize
                currMouse = mouseIDs{iMouse};
                % load results from real data model inversion
                loadName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,[],currCondition,iRep,nReps,'info');
                try
                    load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                        loadName,'.mat']);

                    if iCondition==1
                        if iTask ==1
                            if iRep ==1
                                rowIdx = nSize;
                                if iMouse==1
                                    varNames = MouseInfoTable.Properties.VariableNames;
                                    for i=1:numel(varNames)
                                        if size(MouseInfoTable.(i),2)>1
                                            varTypes{i} = 'string';
                                            logIdx(i) = 0;
                                        elseif double(MouseInfoTable.(i))
                                            varTypes{i} = 'double';
                                            logIdx(i) = 0;
                                        elseif islogical(MouseInfoTable.(i))
                                            varTypes{i} = 'logical';
                                            logIdx(i) = i;
                                        end
                                    end
                                    logIdx = logIdx(logIdx~=0);
                                    sz = [nTasks*nConditions*nSize*nReps  size(varNames,2)];
                                    groupTable = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
                                end % END MOUSE Statement
                                groupTable(iMouse,:) = MouseInfoTable(:,:);
                            else % >1 REPETITIONS
                                rowIdx = rowIdx+1;
                                groupTable(rowIdx,:) = MouseInfoTable(:,:);
                            end % END REPETITIONS Statement
                        else % >1 TASKS
                            rowIdx = rowIdx+1;
                            groupTable(rowIdx,:) = MouseInfoTable(:,:);
                        end % END TASKS Statement
                    else % >1 CONDITIONS
                        rowIdx = rowIdx+1;
                        groupTable(rowIdx,:) = MouseInfoTable(:,:);
                    end % END CONDITIONS Statement

                catch
                    disp(['following file ',['mouse',currMouse,'_',loadName],' not loaded.']);
                    if rowIdx>nSize
                        rowIdx = rowIdx+1;
                        for iLogic = logIdx
                            groupTable{rowIdx,iLogic} = true;
                        end
                    else
                        for iLogic = logIdx
                            groupTable{iMouse,iLogic} = true;
                        end
                    end
                end
            end % END MOUSE Loop
        end % END REPETITIONS Loop
    end % END TASKS Loop
end % END CONDITIONS Loop
IDs = string(mouseIDCol');
groupTable = addvars(groupTable,IDs);
save([optionsFile.paths.cohort(cohortNo).groupLevel,optionsFile.cohort(cohortNo).taskPrefix,...
            optionsFile.cohort(cohortNo).name,'_groupInfoTable.mat'],'groupTable');
writetable(groupTable,[optionsFile.paths.cohort(cohortNo).groupLevel,optionsFile.cohort(cohortNo).taskPrefix,...
            optionsFile.cohort(cohortNo).name,'_groupInfoTable.csv']);

end