function inclIdArray = excludeData(optionsFile,cohortNo)

if exist('optionsFile.mat','file')==2
    load("optionsFile.mat");
else
    optionsFile = runOptions();
end

%% INITIALIZE
% Collate mouseIDs
mouseIDs = [optionsFile.cohort(cohortNo).treatment.maleMice, optionsFile.cohort(cohortNo).treatment.femaleMice,...
    optionsFile.cohort(cohortNo).control.maleMice, optionsFile.cohort(cohortNo).control.femaleMice];

inclIdArray = ones(1,numel(mouseIDs));

for iTask = 1:numel(optionsFile.cohort(cohortNo).testTask)
    currTask = optionsFile.cohort(cohortNo).testTask(iTask).name;

    if numel(optionsFile.cohort(cohortNo).conditions)==0
        nConditions = 1;
    else
        nConditions = numel(optionsFile.cohort(cohortNo).conditions);
    end

    for iCondition = 1:nConditions
        if ~isempty(optionsFile.cohort(cohortNo).conditions)
            currCondition = optionsFile.cohort(cohortNo).conditions{iCondition};
        end

        for iMouse = 1:numel(mouseIDs)
            currMouse = mouseIDs{iMouse};

            if isempty(optionsFile.cohort(cohortNo).conditions)

                try % some task names contained the taskPrefix
                    % load trial-by-trial data file
                    load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                        optionsFile.cohort(cohortNo).taskPrefix,currTask,'.mat']);
                    % load mouse info file
                    load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                        optionsFile.cohort(cohortNo).taskPrefix,currTask,'_info.mat']);
                catch
                    try
                        % load trial-by-trial data file
                        load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                            currTask,'.mat']);
                        % load mouse info file
                        load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                            currTask,'_info.mat']);
                    catch
                        inclIdArray(iMouse) = 0;
                    end

                end
            else % if the cohort had different conditions
                try% some task names contained the taskPrefix
                    % load trial-by-trial data file
                    load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                        optionsFile.cohort(cohortNo).taskPrefix,currTask,'_condition_',currCondition,'.mat']);
                    % load mouse info file
                    load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                        optionsFile.cohort(cohortNo).taskPrefix,currTask,'_condition_',currCondition,'_info.mat']);
                catch
                    try
                        % load trial-by-trial data file
                        load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                            currTask,'_condition_',currCondition,'.mat']);
                        % load mouse info file
                        load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                            currTask,'_condition_',currCondition,'_info.mat']);
                    catch
                        inclIdArray(iMouse) = 0;
                    end
                end
            end



            % create vector of indices with NaNs
            NaNrows     = find(isnan(ExperimentTaskTable.Choice));
            % create vector of differences between indices with NaNs (a 1
            % means there are two indices in a row with a NaN)
            NaNDiffs    = [NaNrows;optionsFile.cohort(3).nTrials+1]-[0;NaNrows];
            consecNaNs  = zeros(1,numel(NaNDiffs));
            consecNaNs(NaNDiffs==1) = 1;
            f           = find(diff([0,consecNaNs,0]==1));
            NaNIdx      = f(1:2:end-1);
            nConsecNaNs = f(2:2:end)-NaNIdx;
            numNaNs       = numel(NaNrows);
            numConsecNans = max(nConsecNaNs);

            if numel(NaNrows)>optionsFile.cohort(cohortNo).nTrials*optionsFile.cohort(cohortNo).exclCriteria(1).cutoff
                exclCrit1_met       = true;
                inclIdArray(iMouse) = 0;

                % Exclude datasets with 20 omissions in a row ???
            elseif any(nConsecNaNs>optionsFile.cohort(cohortNo).exclCriteria(2).cutoff)
                exclCrit2_met       = true;
                inclIdArray(iMouse) = 0;
            else
                exclCrit1_met = false;
                exclCrit2_met = false;
            end


            MouseInfoTable = addvars(MouseInfoTable,exclCrit1_met,numNaNs,exclCrit2_met,numConsecNans);

            % create savepath and filename as a .mat file
            if isempty(optionsFile.cohort(cohortNo).conditions)
                savePath = [char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                    optionsFile.cohort(cohortNo).taskPrefix,currTask,'_info.mat'];
            else % Save with conditions included
                savePath = [char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                    currTask,'_condition_',currCondition,'_info.mat'];
            end
        end
        save(savePath,'MouseInfoTable'); %save
    end
end
end
