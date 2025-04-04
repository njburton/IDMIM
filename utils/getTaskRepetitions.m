function getTaskRepetitions(cohortNo)

if exist('optionsFile.mat','file')==2
    load('optionsFile.mat');
else
    optionsFile = runOptions();
end
if isempty(optionsFile.cohort(cohortNo).conditions) % if the cohort had different conditions
    nConditions   = 1;
else
    nConditions = numel(optionsFile.cohort(cohortNo).conditions);
end
nSize  = optionsFile.cohort(cohortNo).nSize;
nTasks = numel(optionsFile.cohort(cohortNo).testTask);

for iMouse  = 1:nSize
    currMouse = optionsFile.cohort(cohortNo).mouseIDs{iMouse};
    for iCondition = 1:nConditions
        if isempty(optionsFile.cohort(cohortNo).conditions) % if the cohort had different conditions
            currCondition = [];
        else
            currCondition = optionsFile.cohort(cohortNo).conditions{iCondition};
        end
        for iTask = 1:nTasks
            currTask = optionsFile.cohort(cohortNo).testTask(iTask).name;
            loadExpName  = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,[],currCondition,1,1,[]);
            loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,[],currCondition,1,1,'info');
            currInfoFiles = dir(fullfile(optionsFile.paths.cohort(cohortNo).data,['mouse',currMouse,'_',loadInfoName,'_*']));
            currFiles     = dir(fullfile(optionsFile.paths.cohort(cohortNo).data,['mouse',currMouse,'_',loadExpName,'_*']));

            for iRep = 1:numel(currInfoFiles)
                load(fullfile(optionsFile.paths.cohort(cohortNo).data,currInfoFiles(iRep).name))
                dates{iRep} = MouseInfoTable.TaskDate;
            end

            sort(dates);
            clear iRep
            for iRep = 1:numel(currInfoFiles)
                load(fullfile(optionsFile.paths.cohort(cohortNo).data,currInfoFiles(iRep).name))
                idx = find(strcmp(MouseInfoTable.TaskDate,dates));
                taskRepetion = idx;
                MouseInfoTable = addvars(MouseInfoTable,taskRepetion);
                newName = extractBefore(currInfoFiles(iRep).name,[MouseInfoTable.TaskDate,'.mat']);
                newName = [newName,'rep',num2str(idx),'.mat'];
                if strcmp(newName,'rep1.mat')
                    disp('stop')
                end
                save(fullfile(optionsFile.paths.cohort(cohortNo).data,currInfoFiles(iRep).name),'MouseInfoTable');
                movefile(fullfile(optionsFile.paths.cohort(cohortNo).data,currInfoFiles(iRep).name),fullfile(optionsFile.paths.cohort(cohortNo).data,newName));
            end
            clear iRep; % rename task data files using movefile function:
            clear newName;

            for iRep = 1:numel(currFiles)
                if~contains(currFiles(iRep).name,'info')
                    for iDate = 1:numel(dates)
                        if contains(currFiles(iRep).name,dates{iDate})
                            newName = extractBefore(currFiles(iDate).name,[dates{iDate},'.mat']);
                            newName = [newName,'rep',num2str(iDate),'.mat'];
                            movefile(fullfile(optionsFile.paths.cohort(cohortNo).data,currFiles(iDate).name),fullfile(optionsFile.paths.cohort(cohortNo).data,newName));
                        end
                    end
                end
            end
        end % END TASKS Loop
    end % END CONDITIONS Loop
end % END MOUSE Loop
end
