function fileName = getFileName(taskPrefix,currTask,subCohort,currCondition,iRep,nReps,otherFileType)

%% INITIALIZE runOptions
% Main function for running the analysis of the IDMIM study
%
%    SYNTAX:        runAnalysis
%
%    IN: cohortNo:  integer, cohort number, see optionsFile for what cohort
%                            corresponds to what number in the
%                            optionsFile.cohort(cohortNo).name struct. This
%                            allows to run the pipeline and its functions for different
%                            cohorts whose expcifications have been set in runOptions.m
%
% Original: 30-5-2023; Katharina V. Wellstein
% -------------------------------------------------------------------------
% Copyright (C) 2024 - need to fill in details
%
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
if isempty(otherFileType)
    if nReps==1
        if strcmp(subCohort,'all')
            fileName = [taskPrefix,currTask];

        elseif ~isempty(subCohort)
            if isempty(currCondition)
                fileName = [taskPrefix,currTask,'_',subCohort];
            else
                fileName = [taskPrefix,currTask,'_',subCohort,'_condition_',currCondition];
            end

        else
            fileName = [taskPrefix,currTask,'_condition_',currCondition];
        end
    else % dataset includes more than one repetition of the same task and/or condition
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
else % if getting name for another file than datafile
    if nReps==1
        if strcmp(subCohort,'all')
            fileName = [taskPrefix,currTask,'_',otherFileType];

        elseif ~isempty(subCohort)
            if isempty(currCondition)
                fileName = [taskPrefix,currTask,'_',subCohort,'_',otherFileType];
            else
                fileName = [taskPrefix,currTask,'_',subCohort,'_condition_',currCondition,'_',otherFileType];
            end
        else
            fileName = [taskPrefix,currTask,'_condition_',currCondition,'_',otherFileType];

        end
    else % dataset includes more than one repetition of the same task and/or condition
        if strcmp(subCohort,'all')
            fileName = [taskPrefix,currTask,'_',otherFileType,'_rep',num2str(iRep)];

        elseif ~isempty(subCohort)
            if isempty(currCondition)
                fileName = [taskPrefix,currTask,'_',subCohort,'_',otherFileType,'_rep',num2str(iRep)];
            else
                fileName = [taskPrefix,currTask,'_',subCohort,'_condition_',currCondition,'_',otherFileType,'_rep',num2str(iRep)];
            end
        else
            fileName = [taskPrefix,currTask,'_condition_',currCondition,'_',otherFileType,'_rep',num2str(iRep)];

        end
    end
end

end