function prepDataFiles(cohortNo)
%% getData - Process and extract experimental task data from MED-PC files
%
% SYNTAX:  getData(cohortNo)
%
%   IN: cohortNo:  integer, cohort number, see optionsFile for what cohort
%                            corresponds to what number in the
%                            optionsFile.cohort(cohortNo).name struct. This
%                            allows to run the pipeline and its functions for different
%                            cohorts whose expcifications have been set in runOptions.m
%
% Coded by: Katharina Wellstein, https://github.com/kwellstein
%           Nicholas Burton
% -------------------------------------------------------------------------
%
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
if exist('optionsFile.mat','file')==2
    load('optionsFile.mat');
else
    optionsFile = runOptions();
end


if isempty(optionsFile.cohort(cohortNo).conditions)
    if optionsFile.cohort(cohortNo).taskRepetitions>1
        getTaskRepetitions(cohortNo,[]);
    end
else
    getTaskRepetitions(cohortNo,'getRepNumber');
end

getExcludeData(optionsFile,cohortNo);

createGroupTable(cohortNo);

end