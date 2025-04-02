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

mouseIDs = optionsFile.cohort(cohortNo).mouseIDs;
nSize    = optionsFile.cohort(cohortNo).nSize;
nTasks   = numel(optionsFile.cohort(cohortNo).testTask);
nReps    = optionsFile.cohort(cohortNo).taskRepetitions;
nLevels  = nTasks*nConditions*nReps;

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
                loadName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,subCohort,currCondition,iRep,nReps,[]);
                load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                    loadName,'.mat']);

                if iCondition==1
                    if iTask ==1
                        if iRep ==1
                            if iMouse==1
                                varNames = MouseInfoTable.Properties.VariableNames;
                                for i=1:numel(varNames)
                                    if size(MouseInfoTable.(i),2)>1
                                        varTypes{i} = 'string';
                                    elseif double(MouseInfoTable.(i))
                                        varTypes{i} = 'double';
                                    elseif islogical(MouseInfoTable.(i))
                                        varTypes{i} = 'logical';
                                    end
                                end
                                sz = [nTasks*nConditions*nSize  size(varNames,2)];
                                groupTable = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames,'RowNames',repmat(mouseIDs,1,nLevels));
                            end % END MOUSE Statement
                            groupTable(iMouse,:) = MouseInfoTable(:,:);
                        else % >1 REPETITIONS
                            rowIdx = nSize+iMouse;
                            groupTable(rowIdx,:) = MouseInfoTable(:,:);
                        end % END REPETITIONS Statement
                    else % >1 TASKS
                        rowIdx = rowIdx+iMouse;
                        groupTable(rowIdx,:) = MouseInfoTable(:,:);
                    end % END TASKS Statement
                else % >1 CONDITIONS
                        rowIdx = rowIdx+iMouse;
                        groupTable(rowIdx,:) = MouseInfoTable(:,:);
                end % END CONDITIONS Statement
            end % END MOUSE Loop
        end % END REPETITIONS Loop
    end % END TASKS Loop
end % END CONDITIONS Loop

save([optionsFile.paths.cohort(cohortNo).groupLevel,'groupInfoTable.mat'],'groupTable');
writetable(groupTable,[optionsFile.paths.cohort(cohortNo).groupLevel,'groupInfoTable.csv'])

end