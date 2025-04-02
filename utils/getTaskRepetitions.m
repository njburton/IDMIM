function getTaskRepetitions(cohortNo)

if exist('optionsFile.mat','file')==2
    load('optionsFile.mat');
else
    optionsFile = runOptions();
end

for iMouse  = 1:optionsFile.cohort(cohortNo).nSize
    currMouse = optionsFile.cohort(cohortNo).mouseIDs{iMouse};
    for iTask = 1:numel(optionsFile.cohort(cohortNo).testTask)
        currTask = optionsFile.cohort(cohortNo).testTask(iTask).name;
        currInfoFiles = dir(fullfile(optionsFile.paths.cohort(cohortNo).data,['mouse',currMouse,'_',optionsFile.cohort(cohortNo).taskPrefix,currTask,'_info_*']));
        currFiles = dir(fullfile(optionsFile.paths.cohort(cohortNo).data,['mouse',currMouse,'_',optionsFile.cohort(cohortNo).taskPrefix,currTask,'_*']));
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
                    newName = extractBefore(currFiles(iRep).name,[dates{iDate},'.mat']);
                    repNo = iDate;
                    end
                end
                newName = [newName,'rep',num2str(repNo),'.mat'];
                if strcmp(newName,'rep1.mat')
                    disp('stop')
                end
                movefile(fullfile(optionsFile.paths.cohort(cohortNo).data,currFiles(iRep).name),fullfile(optionsFile.paths.cohort(cohortNo).data,newName));
            end
        end
    end
end


end
