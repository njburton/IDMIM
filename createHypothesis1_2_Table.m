function createHypothesis1_2_Table

% createHypothesis1_2_Table - Extract learning parameters between experimental groups
%
% This function extracts computational model parameters from fitted models comparing
% treatment and control groups for each mouse. It collects reward predictability parameters from the
% hierarchical Gaussian filter model (2-level (omega2)) to examine group differences
% in reward predictability estimates. The resulting data table contains one row per mouse with
% model parameters and group information, allowing for statistical analysis of how
% experimental manipulations affect computational parameters of learning.
% Per-condition exclusion criteria are applied rather than per-mouse exclusion.
% The output is saved as both .mat and .csv files.
%
% No input arguments required; configuration is loaded from optionsFile.mat.
% Output: Data table saved to the group-level results directory.
%
% -------------------------------------------------------------------------
%
% Coded by: 2025; Nicholas J. Burton,
%           nicholasjburton91@gmail.com.au
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
% -------------------------------------------------------------------------

% load or run options for running this function
if exist('optionsFile.mat','file')==2
    load('optionsFile.mat');
else
    optionsFile = runOptions();
end

% Prespecify variables needed
iModel  = 2; % 2-level HGF as it was the winning model for the control group
iTask   = 1;
iRep    = 1;
nReps   = 1;
cohortNo = 1;
subCohort = [];
currTask = optionsFile.cohort(cohortNo).testTask(1).name;
[mouseIDs,nSize] = getSampleVars(optionsFile,cohortNo,subCohort);

%% EXCLUDE MICE that have NO data files at all
% Only exclude mice that have no data files for any condition
noDataArray = zeros(1,nSize);

for iMouse = 1:nSize
    currMouse = mouseIDs{iMouse};
    loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,...
        [],[],iRep,nReps,'info');
    if ~isfile([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',loadInfoName,'.mat'])
        disp(['data for mouse ', currMouse,' not available']);
        noDataArray(iMouse) = iMouse;
    end
end

noDataArray = sort(noDataArray,'descend');
noDataArray(noDataArray==0)=[];

for i=noDataArray
    mouseIDs(i) =[];
end
nSize = numel(mouseIDs);

fprintf('Total mice with at least some data: %d\n', nSize);

% Create the table with proper variable types from the beginning
RQ1_2_dataTable = table('Size', [nSize, 4], ...
    'VariableTypes', {'string', 'string', 'string', 'double'}, ...
    'VariableNames', {'ID', 'sex', 'condition', 'omega2'});

%% LOAD data with per-condition exclusion checking
% Load data and populate table
for iMouse = 1:nSize
    currMouse = mouseIDs{iMouse};

    % Load info file to get sex and condition, and check exclusion criteria
    loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], [], iRep, nReps, 'info');
    infoPath = [char(optionsFile.paths.cohort(cohortNo).data), 'mouse', char(currMouse), '_', loadInfoName, '.mat'];

    % Initialize variables
    shouldExclude = false;
    
    if isfile(infoPath)
        load(infoPath, 'MouseInfoTable');
        RQ1_2_dataTable.ID(iMouse) = currMouse;
        RQ1_2_dataTable.sex(iMouse) = MouseInfoTable.Sex;
        RQ1_2_dataTable.condition(iMouse) = MouseInfoTable.Condition;
        
        % Check exclusion criteria for this mouse
        if isfield(table2struct(MouseInfoTable), 'exclCrit1_met') && ...
           isfield(table2struct(MouseInfoTable), 'exclCrit2_met')
            
            if MouseInfoTable.exclCrit1_met || MouseInfoTable.exclCrit2_met
                shouldExclude = true;
                disp(['Mouse ', currMouse, ' excluded based on exclusion criteria']);
            end
        end
    end

    % Only extract parameters if this mouse should not be excluded
    if ~shouldExclude
        % Load model fit results to get omega2
        loadName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], [], iRep, nReps, []);
        fitPath = [char(optionsFile.paths.cohort(cohortNo).results), 'mouse', char(currMouse), '_', ...
            loadName, '_', optionsFile.dataFiles.rawFitFile{iModel}, '.mat'];

        if isfile(fitPath)
            load(fitPath, 'est');
            % Extract omega2 parameter from the HGF 2-level model
            RQ1_2_dataTable.omega2(iMouse) = est.p_prc.om(2);  % Access omega2 (level 2 parameter)
        else
            RQ1_2_dataTable.omega2(iMouse) = NaN;
        end
    else
        % Set parameter to NaN for excluded mouse
        RQ1_2_dataTable.omega2(iMouse) = NaN;
    end
end

% Remove any rows where parameters are NaN (i.e., mice that were excluded or had no valid data)
validRows = ~isnan(RQ1_2_dataTable.omega2);
RQ1_2_dataTable = RQ1_2_dataTable(validRows, :);

if sum(~validRows) > 0
    fprintf('Removed %d mice with no valid parameter values.\n', sum(~validRows));
end

fprintf('Final table contains %d mice.\n', height(RQ1_2_dataTable));

% Save table as both .mat and .csv
savePath = [optionsFile.paths.cohort(cohortNo).groupLevel, optionsFile.cohort(cohortNo).taskPrefix, ...
    optionsFile.cohort(cohortNo).name, '_RQ1_2_dataTable'];

save([savePath, '.mat'], 'RQ1_2_dataTable');
writetable(RQ1_2_dataTable, [savePath, '.csv']);

disp(['Table saved to: ', savePath, '.csv']);
end