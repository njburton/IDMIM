function [mouseIDs,nSize] = getSampleVars(optionsFile,cohortNo,subCohort)

%% getSampleVars
%  gets mouse ID array and sample size (nSize) needed for the current analysis
%
%   SYNTAX:       [mouseIDs,nSize] = getSampleVars(optionsFile,cohortNo,subCohort)
%
%   IN: optionsFile:  struct, containing all dataset specific information.
%       cohortNo:     integer, cohort number, see optionsFile for what cohort
%                            corresponds to what number in the
%                            optionsFile.cohort(cohortNo).name struct. This
%                            allows to run the pipeline and its functions for different
%                            cohorts whose expcifications have been set in runOptions.m
%       subCohort:   string,  {'control','treatment','all'} in case only a
%                           specific subcohort will be used in this
%                           analysis or 'all' if all subCohorts are used
%
% Coded by: 30-04-2025, Katharina V. Wellstein
%                       https://github.com/kwellstein
%
% -------------------------------------------------------------------------
% Copyright (C) 2025
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

% if this cohort does not contain more than one subcohort (i.e. only
% controls or only a treatment group) use all mouseIDs
if isempty(subCohort)
    mouseIDs      = optionsFile.cohort(cohortNo).mouseIDs;
    nSize         = optionsFile.cohort(cohortNo).nSize;
    
    % if this cohort contains more than one subcohort (i.e. a control and
    % a treatment group) use all mouseIDs AND you want to run all mice in
    % this function use all mouseIDs
elseif strcmp(subCohort,'all')
    mouseIDs    = optionsFile.cohort(cohortNo).mouseIDs;
    nSize       = optionsFile.cohort(cohortNo).nSize;

    % if this cohort contains more than one subcohort (i.e. a control and
    % a treatment group) use all mouseIDs AND you want to run ONLY one of the two 
    % subcohorts in this function use only the subcohort's mouseIDs
elseif ~isempty(subCohort)
    mouseIDs    = [optionsFile.cohort(cohortNo).(subCohort).maleMice,...
                   optionsFile.cohort(cohortNo).(subCohort).femaleMice];
    nSize       = numel(mouseIDs);
end