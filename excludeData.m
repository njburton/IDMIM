function excludeData(cohortNo)

for iTask = 1:numel(optionsFile.cohort(cohortNo).testTask)
    currTask = optionsFile.cohort(cohortNo).testTask(iTask).name;

    exclDataTable = table('VariableTypes',{'string','string','string','string','string','double'},...
        'VariableNames',{'mouseID','task','group','sex','reason_for_exclusion','data'});
    deleteRows = zeros(size(optionsFile.cohort(cohortNo).treatment.nSize,2));

    if numel(optionsFile.cohort(cohortNo).conditions)==0
        nConditions = 1;
    else
        nConditions = numel(optionsFile.cohort(cohortNo).conditions);
    end

    for iCondition = 1:nConditions
        if ~isempty(optionsFile.cohort(cohortNo).conditions)
            currCondition = optionsFile.cohort(cohortNo).conditions{iCondition};
        end
        %% ------------ read data files male mice treatment group ------------%
        if ~isempty(optionsFile.cohort(cohortNo).treatment.maleMice)
            % vector for collecting indices of mouseIDs that need to be removed
            % from optionsfile

            for iMouse = 1:size(optionsFile.cohort(cohortNo).treatment.maleMice,2)
                currMouse = optionsFile.cohort(cohortNo).treatment.maleMice{iMouse};

                if isempty(optionsFile.cohort(cohortNo).conditions)
                    load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                        tasks{iTask},'.mat']);
                else
                    load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                        tasks{iTask},'_condition_',currCondition,'.mat']);
                end

                % check if dataset has >30% omissions
                NaNrows = find(isnan(ExperimentTaskTable.Choice));
                if numel(NaNrows)>optionsFile.cohort(cohortNo).nTrials*0.3
                    exclDataTable.mouseID(iMouse) = currMouse;
                    exclDataTable.group(iMouse)   = 'treatment';
                    exclDataTable.sex(iMouse)     = 'male';
                    exclDataTable.reason_for_exclusion(iMouse) = 'no. omissions';
                    exclDataTable.data(iMouse)    = 'no. omissions';
                    exclDataTable.task(iMouse)    = currTask;

                    % Exclude datasets with 20 omissions in a row ???
                elseif ~isempty(strfind(isnan(ExperimentTaskTable.Choice),true(1,20)))
                    startNaNTrial = strfind(isnan(ExperimentTaskTable.Choice), true(1,20));
                    exclDataTable.mouseID(iMouse) = currMouse;
                    exclDataTable.group(iMouse)   = 'treatment';
                    exclDataTable.sex(iMouse)     = 'male';
                    exclDataTable.reason_for_exclusion(iMouse) = 'consecutive omissions';
                    exclDataTable.data(iMouse)    = startNaNTrial;
                    exclDataTable.task(iMouse)    = currTask;
                else
                    deleteRows(iMouse) = 1;
                end
            end
        end

        %% ---------- read data files female mice treatment group ---------------
        if ~isempty(optionsFile.cohort(cohortNo).treatment.femaleMice)
            % vector for collecting indices of mouseIDs that need to be removed
            % from optionsfile
            for iMouse = 1:size(optionsFile.cohort(cohortNo).treatment.femaleMice,2)
                currMouse = optionsFile.cohort(cohortNo).treatment.femaleMice{iMouse};

                if isempty(optionsFile.cohort(cohortNo).conditions)
                    load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                        tasks{iTask},'.mat']);
                else
                    load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                        tasks{iTask},'_condition_',currCondition,'.mat']);
                end

                % check if dataset has >30% omissions
                NaNrows = find(isnan(ExperimentTaskTable.Choice));
                tblRow = nMaleTreat + iMouse;
                if numel(NaNrows)>optionsFile.cohort(cohortNo).nTrials*0.3
                    exclDataTable.mouseID(tblRow) = currMouse;
                    exclDataTable.group(tblRow)   = 'treatment';
                    exclDataTable.sex(tblRow)     = 'female';
                    exclDataTable.reason_for_exclusion(tblRow) = 'no. omissions';
                    exclDataTable.task(tblRow)    = currTask;
                    exclDataTable.data(tblRow) = numel(NaNrows);
                    % Exclude datasets with 20 omissions in a row ???

                elseif ~isempty(strfind(isnan(ExperimentTaskTable.Choice),true(1,20)))
                    startNaNTrial = strfind(isnan(ExperimentTaskTable.Choice), true(1,20));
                    exclDataTable.mouseID(tblRow) = currMouse;
                    exclDataTable.group(tblRow)   = 'treatment';
                    exclDataTable.sex(tblRow)     = 'female';
                    exclDataTable.reason_for_exclusion(tblRow) = 'consecutive omissions';
                    exclDataTable.task(tblRow)    = currTask;
                    exclDataTable.data(tblRow)    = startNaNTrial;
                else
                    deleteRows(tblRow) = 1;
                end
            end
        end

        %% ---------------- read data files male mice control group ------- %
        if ~isempty(optionsFile.cohort(cohortNo).control.maleMice)

            % vector for collecting indices of mouseIDs that need to be removed
            % from optionsfile
            for iMouse = 1:size(optionsFile.cohort(cohortNo).control.maleMice,2)
                currMouse = optionsFile.cohort(cohortNo).control.maleMice{iMouse};
                tblRow    = nMaleTreat + nFemaleTreat + iMouse;

                if isempty(optionsFile.cohort(cohortNo).conditions)
                    load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                        tasks{iTask},'.mat']);
                else
                    load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                        tasks{iTask},'_condition_',currCondition,'.mat']);
                end

                % check if dataset has >30% omissions
                NaNrows = find(isnan(ExperimentTaskTable.Choice));

                if numel(NaNrows)>optionsFile.cohort(cohortNo).nTrials*0.3
                    exclDataTable.mouseID(tblRow) = currMouse;
                    exclDataTable.group(tblRow)   = 'control';
                    exclDataTable.sex(tblRow)     = 'male';
                    exclDataTable.reason_for_exclusion(tblRow) = 'no. omissions';
                    exclDataTable.task(tblRow)    = currTask;
                    exclDataTable.data = numel(NaNrows);

                    % Exclude datasets with 20 omissions in a row ???
                elseif ~isempty(strfind(isnan(ExperimentTaskTable.Choice),true(1,20)))
                    startNaNTrial = strfind(isnan(ExperimentTaskTable.Choice), true(1,20));
                    exclDataTable.mouseID(tblRow) = currMouse;
                    exclDataTable.group(tblRow)   = 'control';
                    exclDataTable.sex(tblRow)     = 'male';
                    exclDataTable.reason_for_exclusion(tblRow) = 'consecutive omissions';
                    exclDataTable.task(tblRow)    = currTask;
                    exclDataTable.data(tblRow)    = startNaNTrial;
                else
                    deleteRows(tblRow) = 1;
                end
            end
        end

        % read data files male mice treatment group
        if ~isempty(optionsFile.cohort(cohortNo).control.femaleMice)
            % vector for collecting indices of mouseIDs that need to be removed
            % from optionsfile
            for iMouse = 1:size(optionsFile.cohort(cohortNo).control.femaleMice,2)
                currMouse = optionsFile.cohort(cohortNo).control.femaleMice{iMouse};

                if isempty(optionsFile.cohort(cohortNo).conditions)
                    load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                        tasks{iTask},'.mat']);
                else
                    load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                        tasks{iTask},'_condition_',currCondition,'.mat']);
                end

                % check if dataset has >30% omissions
                NaNrows = find(isnan(ExperimentTaskTable.Choice));
                tblRow = nMaleTreat + femaleTreat + maleControl + iMouse;
                if numel(NaNrows)>optionsFile.cohort(cohortNo).nTrials*0.3
                    optionsFile.cohort(cohortNo).treatment.femaleMice(find(isnan(optionsFile.cohort(cohortNo).treatment.femaleMice)))=[];
                    exclDataTable.mouseID(tblRow) = currMouse;
                    exclDataTable.group(tblRow)   = 'control';
                    exclDataTable.sex(tblRow)     = 'female';
                    exclDataTable.reason_for_exclusion(tblRow) = 'no. omissions';
                    exclDataTable.task(tblRow)    = currTask;
                    exclDataTable.data(tblRow)    = numel(NaNrows);

                    % Exclude datasets with 20 omissions in a row ???
                elseif ~isempty(strfind(isnan(ExperimentTaskTable.Choice),true(1,20)))
                    optionsFile.cohort(cohortNo).treatment.femaleMice(find(isnan(optionsFile.cohort(cohortNo).control.femaleMice)))=[];
                    startNaNTrial = strfind(isnan(ExperimentTaskTable.omissions), true(1,20));
                    exclDataTable.mouseID(tblRow) = currMouse;
                    exclDataTable.group(tblRow)   = 'control';
                    exclDataTable.sex(tblRow)     = 'female';
                    exclDataTable.reason_for_exclusion(tblRow) = 'consecutive omissions';
                    exclDataTable.task(tblRow)    = currTask;
                    exclDataTable.data(tblRow)    = startNaNTrial;
                else
                    deleteRows(tblRow) = 1;
                end
            end
        end
        deleteIdx = find(deleteRows);
        if sum(deleteRows)==optionsFile.cohort(cohortNo).nSize
            continue
        else
            exclDataTable(deleteIdx ,:);

            % create savepath and filename as a .mat file
            if isempty(optionsFile.cohort(cohortNo).conditions)
                savePath = [char(optionsFile.paths.cohort(cohortNo).results),...
                    'ExclusionInfo_',tasks{iTask},'.mat'];
            else % Save with conditions included
                savePath = [char(optionsFile.paths.cohort(cohortNo).results),...
                    'ExclusionInfo_',tasks{iTask},'_condition_',currCondition,'.mat'];
            end
            save(savePath,'exclDataTable'); %save
        end
    end
end
end