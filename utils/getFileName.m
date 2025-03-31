function fileName = getFileName(taskPrefix,currTask,subCohort,currCondition,currRepetition)

if currRepetition<2
    if strcmp(subCohort,'all')
        fileName = [taskPrefix,currTask,'_'];

    elseif ~isempty(subCohort)

        if isempty(currCondition)
            fileName = [taskPrefix,currTask,'_',subCohort,'_'];
        else
            fileName = [taskPrefix,currTask,'_',subCohort,'_condition_',currCondition,'_'];
        end

    else
        fileName = [taskPrefix,currTask,'_condition_',currCondition,'_'];

    end
else
    if strcmp(subCohort,'all')
        fileName = [taskPrefix,currTask,'_rep',num2str(iRep)];

    elseif ~isempty(subCohort)

        if isempty(currCondition)
            fileName = [taskPrefix,currTask,'_',subCohort,'_rep',num2str(iRep)];
        else
            fileName = [taskPrefix,currTask,'_',subCohort,'_condition_',currCondition,'_rep',num2str(iRep)];
        end

    else
        fileName = [taskPrefix,currTask,'_condition_',currCondition,'_rep',num2str(iRep)];

    end
end


end