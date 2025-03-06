function excludeData(cohortNo)

for iTask = 1:numel(optionsFile.cohort(cohortNo).testTask)
    currTask = optionsFile.cohort(cohortNo).testTask(iTask).name;

    exclDataTable = table('VariableTypes',{'string','string','string','string','string','double'},...
        'VariableNames',{'mouseID','task','group','sex','reason_for_exclusion','data'});
    deleteRows = zeros(size(optionsFile.cohort(cohortNo).treatment.nSize,2));

    %% ------------ read data files male mice treatment group ------------%
    if ~isempty(optionsFile.cohort(cohortNo).treatment.maleMice)
        % vector for collecting indices of mouseIDs that need to be removed
        % from optionsfile

        for iMouse = 1:size(optionsFile.cohort(cohortNo).treatment.maleMice,2)
            currMouse = optionsFile.cohort(cohortNo).treatment.maleMice{iMouse};
            load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                currTask,'*.mat']);

            % check if dataset has >30% omissions
            NaNrows = find(isnan(ExperimentTaskTable.omissions));
            if numel(NaNrows)>optionsFile.cohort(cohortNo).nTrials*0.3
                exclDataTable.mouseID(iMouse) = currMouse;
                exclDataTable.group(iMouse) = 'treatment';
                exclDataTable.sex(iMouse) = 'male';
                exclDataTable.reason_for_exclusion(iMouse) = 'no. omissions';
                exclDataTable.data(iMouse) = 'no. omissions';
                exclDataTable.task(iMouse) = currTask;

                % Exclude datasets with 20 omissions in a row ???
            elseif ~isempty(strfind(isnan(ExperimentTaskTable.omissions),true(1,20)))
                startNaNTrial = strfind(isnan(ExperimentTaskTable.omissions), true(1,20));
                exclDataTable.mouseID(iMouse) = currMouse;
                exclDataTable.group(iMouse) = 'treatment';
                exclDataTable.sex(iMouse)   = 'male';
                exclDataTable.reason_for_exclusion(iMouse) = 'consecutive omissions';
                exclDataTable.data = startNaNTrial;
                exclDataTable.task(iMouse) = currTask;
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
            load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                currTask,'*.mat']);

            % check if dataset has >30% omissions
            NaNrows = find(isnan(ExperimentTaskTable.omissions));
            tblRow = nMaleTreat + iMouse;
            if numel(NaNrows)>optionsFile.cohort(cohortNo).nTrials*0.3
                exclDataTable.mouseID(tblRow) = currMouse;
                exclDataTable.group(tblRow)   = 'treatment';
                exclDataTable.sex(tblRow)     = 'female';
                exclDataTable.reason_for_exclusion(tblRow) = 'no. omissions';
                exclDataTable.task(tblRow)    = currTask;
                exclDataTable.data = numel(NaNrows);
                % Exclude datasets with 20 omissions in a row ???

            elseif ~isempty(strfind(isnan(ExperimentTaskTable.omissions),true(1,20)))
                startNaNTrial = strfind(isnan(ExperimentTaskTable.omissions), true(1,20));
                exclDataTable.mouseID(tblRow) = currMouse;
                exclDataTable.group(tblRow)   = 'treatment';
                exclDataTable.sex(tblRow)     = 'female';
                exclDataTable.reason_for_exclusion(tblRow) = 'consecutive omissions';
                exclDataTable.task(tblRow)    = currTask;
                exclDataTable.data = startNaNTrial;
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
            load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                currTask,'*.mat']);

            % check if dataset has >30% omissions
            NaNrows = find(isnan(ExperimentTaskTable.omissions));

            if numel(NaNrows)>optionsFile.cohort(cohortNo).nTrials*0.3
                exclDataTable.mouseID(tblRow) = currMouse;
                exclDataTable.group(tblRow)   = 'control';
                exclDataTable.sex(tblRow)     = 'male';
                exclDataTable.reason_for_exclusion(tblRow) = 'no. omissions';
                exclDataTable.task(tblRow)    = currTask;
                exclDataTable.data = numel(NaNrows);

                % Exclude datasets with 20 omissions in a row ???
            elseif ~isempty(strfind(isnan(ExperimentTaskTable.omissions),true(1,20)))
                startNaNTrial = strfind(isnan(ExperimentTaskTable.omissions), true(1,20));
                exclDataTable.mouseID(tblRow) = currMouse;
                exclDataTable.group(tblRow)   = 'control';
                exclDataTable.sex(tblRow)     = 'male';
                exclDataTable.reason_for_exclusion(tblRow) = 'consecutive omissions';
                exclDataTable.task(tblRow)    = currTask;
                exclDataTable.data = startNaNTrial;
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
            load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                currTask,'*.mat']);

            % check if dataset has >30% omissions
            NaNrows = find(isnan(ExperimentTaskTable.omissions));
            tblRow = nMaleTreat + femaleTreat + maleControl + iMouse;
            if numel(NaNrows)>optionsFile.cohort(cohortNo).nTrials*0.3
                optionsFile.cohort(cohortNo).treatment.femaleMice(find(isnan(optionsFile.cohort(cohortNo).treatment.femaleMice)))=[];
                exclDataTable.mouseID(tblRow) = currMouse;
                exclDataTable.group(tblRow) = 'control';
                exclDataTable.sex(tblRow) = 'female';
                exclDataTable.reason_for_exclusion(tblRow) = 'no. omissions';
                exclDataTable.task(tblRow)    = currTask;
                exclDataTable.data = numel(NaNrows);

                % Exclude datasets with 20 omissions in a row ???
            elseif ~isempty(strfind(isnan(ExperimentTaskTable.omissions),true(1,20)))
                optionsFile.cohort(cohortNo).treatment.femaleMice(find(isnan(optionsFile.cohort(cohortNo).control.femaleMice)))=[];
                startNaNTrial = strfind(isnan(ExperimentTaskTable.omissions), true(1,20));
                exclDataTable.mouseID(tblRow) = currMouse;
                exclDataTable.group(tblRow) = 'control';
                exclDataTable.sex(tblRow)   = 'female';
                exclDataTable.reason_for_exclusion(tblRow) = 'consecutive omissions';
                exclDataTable.task(tblRow)    = currTask;
                exclDataTable.data = startNaNTrial;
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
        savePath = [char(optionsFile.paths.cohort(cohortNo).results),...
            'ExclusionInfo_',char(currTask),'.mat'];
        save(savePath,'exclDataTable'); %save
    end
end

end