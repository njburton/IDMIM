function [inclIdArray,optionsFile] = excludeData(optionsFile,cohortNo,subCohort,mode)

%% excludeData
%  excludeData analysis analyses the datasets for exclusion criteria being
%  met (defined in runOptions) and codes the respespective
%  participant/mouse indices in the inclIdArray as zeros
%
%   SYNTAX:  inclIdArray = excludeData(optionsFile,cohortNo,mode)
%
%   IN:      optionsFile: struct, contains all settings for this analysis,
%                                 incl exclusion criteria for each cohort
%            cohortNo:    integer, cohort number, see optionsFile for what cohort
%                                  corresponds to what number in the
%                                  optionsFile.cohort(cohortNo).name struct. This
%                                  allows to run the pipeline and its functions for different
%                                  cohorts whose expcifications have been set in runOptions.m
%            mode: string, {'excludeData','updateDataInfo','updateOptions'},mode in which
%                           this function should run.
%                           'excludeData', only determes what data should be excluded
%                           'updateDataInfo' updates the dataInfo Tables
%                           with the info on exclusion criteria in addition
%                           to determining what data should be excluded
%                           'updateOptions' updates the dataInfo Tables
%                           with the info on exclusion criteria and updates the IDs in the optionsFile
%                           in addition to determining what data should be excluded
%
%   OUT:    inclIdArray: array, contains ones for IDs that will be included
%                               and zeros for IDs that will not be. The sequence of
%                               IDs are the same as optionsFile.cohort(cohortNo).mouseIDs
%            optionsFile: struct, contains all settings for this analysis,
%                                 incl exclusion criteria for each cohort
%
% Original: 19-03-2025; Katharina V. Wellstein,
%           katharina.wellstein@newcastle.edu.au
%
% -------------------------------------------------------------------------
% This file is released under the terms of the GNU General Public Licence
% (GPL), version 3. You can redistribute it and/or modify it under the
% terms of the GPL (either version 3 or, at your option, any later version).
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details:
% <http://www.gnu.org/licenses/>
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
% _________________________________________________________________________
% =========================================================================

if exist('optionsFile.mat','file')==2
    load("optionsFile.mat");
else
    optionsFile = runOptions();
end

if numel(optionsFile.cohort(cohortNo).conditions)==0
    nConditions = 1;
    mouseIDs    = [optionsFile.cohort(cohortNo).(subCohort).maleMice,...
        optionsFile.cohort(cohortNo).(subCohort).femaleMice];
    nSize       = numel(mouseIDs);
else
    nConditions = numel(optionsFile.cohort(cohortNo).conditions);
    mouseIDs    = optionsFile.cohort(cohortNo).mouseIDs;
    nSize       = optionsFile.cohort(cohortNo).nSize;
end

%% INITIALIZE
disp([' ====== excludeData function running in ',mode,' mode ====== ']);

inclIdArray = ones(1,nSize);

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

        for iMouse = 1:nSize
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
                        disp(['mouse dataset',currMouse,' not loaded']);
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


                        % create vector of indices with NaNs
                        NaNrows     = find(isnan(ExperimentTaskTable.Choice));
                        % create vector of differences between indices with NaNs (a 1
                        % means there are two indices in a row with a NaN)
                        NaNDiffs    = [NaNrows;optionsFile.cohort(cohortNo).nTrials+1]-[0;NaNrows];
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

                        if strcmp(mode,'updateDataInfo')
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
                    catch
                        disp(['mouse dataset',currMouse,' not loaded']);
                        inclIdArray(iMouse) = 0;
                    end
                end
            end
        end
    end

    deleteIds = find(inclIdArray==0);

    if numel(optionsFile.cohort(cohortNo).conditions)==0
        nMaleMice   = numel(optionsFile.cohort(cohortNo).(subCohort).maleMice);
        if~isempty(deleteIds(deleteIds<=nMaleMice))
            optionsFile.cohort(cohortNo).(subCohort).maleMice(deleteIds(deleteIds<=nMaleMice)) = [];
        end
        if~isempty(deleteIds(deleteIds>nMaleMice))
            delIdx = deleteIds(deleteIds>nMaleMice)-nMaleMice;
            optionsFile.cohort(cohortNo).(subCohort).femaleMice(delIdx) = [];
        end
        optionsFile.cohort(cohortNo).nSize = nSize - numel(deleteIds);
    else
        optionsFile.cohort(cohortNo).mouseIDs(deleteIds) = [];
        optionsFile.cohort(cohortNo).nSize = numel(optionsFile.cohort(cohortNo).mouseIDs);
    end


    if strcmp(mode,'updateOptions')
        save([optionsFile.paths.projDir,'optionsFile.mat'],'optionsFile');
    end

end
