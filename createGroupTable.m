function createGroupTable(cohortNo)

% function that groups mouseInfotables,
%% INITIALIZE Variables for running this function
% specifications for this analysis
if exist('optionsFile.mat','file')==2
    load('optionsFile.mat');
else
    optionsFile = runOptions();
end


if  numel(optionsFile.cohort(cohortNo).conditions)==0
    nConditions = 1;
else
    nConditions = numel(optionsFile.cohort(cohortNo).conditions);

end

mouseIDs    = optionsFile.cohort(cohortNo).mouseIDs;
nSize       = optionsFile.cohort(cohortNo).nSize;
nTasks      = numel(optionsFile.cohort(cohortNo).testTask);
    
for iCondition = 1:nConditions
    if nConditions ==1
        currCondition = [];
    else
        currCondition = optionsFile.cohort(cohortNo).conditions{iCondition};
    end

    for iTask = 1:nTasks 
        currTask = optionsFile.cohort(cohortNo).testTask(iTask).name;
        for iMouse = 1:nSize
            currMouse = mouseIDs{iMouse};
            if isempty(optionsFile.cohort(cohortNo).conditions)
                % load results from real data model inversion
                try % some task names contained the taskPrefix
       
                    load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                        optionsFile.cohort(cohortNo).taskPrefix,currTask,'_info.mat']);

                catch
                    load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                        currTask,'_info.mat']);
                end
            else % if the cohort had different conditions
                try% some task names contained the taskPrefix
                    % load mouse info file
                    load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                        optionsFile.cohort(cohortNo).taskPrefix,currTask,'_condition_',currCondition,'_info.mat']);
                catch
                    try
                        % load mouse info file
                        load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                            currTask,'_condition_',currCondition,'_info.mat']);

                    end
                end
            end
            if iCondition==1
                if iTask ==1
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
                        groupTable = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames,'RowNames',repmat(mouseIDs,1,nTasks*nConditions));
                    end
                    groupTable(iMouse,:) = MouseInfoTable(:,:);
                else
                   rowIdx = nSize+iMouse; 
                   groupTable(rowIdx,:) = MouseInfoTable(:,:);
                end
            else
                rowIdx = rowIdx+iMouse;
                groupTable(rowIdx,:) = MouseInfoTable(:,:);
            end
        end
    end
end


save([optionsFile.paths.cohort(cohortNo).groupLevel,'groupInfoTable.mat'],'groupTable');
writetable(groupTable,[optionsFile.paths.cohort(cohortNo).groupLevel,'groupInfoTable.csv'])
end