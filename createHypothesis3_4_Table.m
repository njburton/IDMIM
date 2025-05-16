function createHypothesis3_4_Table

% createHypothesis3_4_Table - Extract prior precision parameters across treatment conditions
%
% This function extracts prior precision parameters from fitted models across three treatment
% conditions (saline, 5mg, 10mg) for each mouse. It collects prior precision estimates for
% volatility parameters from the hierarchical Gaussian filter models (2-level HGF omega2
% prior precision, 3-level HGF omega2 prior precision, and 3-level HGF omega3 prior precision).
% The resulting data table contains one row per mouse with all prior precision parameters
% across conditions, allowing for statistical analysis of how drug treatment affects
% the precision of volatility estimates. The output is saved as both .mat and .csv files.
%
% No input arguments required; configuration is loaded from optionsFile.mat.
% Output: Data table saved to the group-level results directory.
%
% -------------------------------------------------------------------------
%
% Coded by: 2025; Nicholas J. Burton,
%           nicholasjburton91@gmail.com.au
%           https://github.com/njburton
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

% Load options file
if exist('optionsFile.mat','file')==2
    load('optionsFile.mat');
else
    optionsFile = runOptions();
end

% Prespecify variables needed
model_HGF3 = 1;  % HGF 3-level model
model_HGF2 = 2;  % HGF 2-level model

% Prespecify variables needed
iTask = 1;
iRep = 1;
nReps = 1;
cohortNo = 3;
subCohort = [];
currTask = optionsFile.cohort(cohortNo).testTask(1).name;
[mouseIDs, nSize] = getSampleVars(optionsFile, cohortNo, subCohort);

%% EXCLUDE MICE from this analysis
% Check available mouse data and exclusion criteria
noDataArray = zeros(1, nSize);
exclArray = zeros(1, nSize);

for iMouse = 1:nSize
    currMouse = mouseIDs{iMouse};
    % Check if data exists for any condition
    hasData = false;
    for iCond = 1:length(optionsFile.cohort(cohortNo).conditions)
        loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], optionsFile.cohort(cohortNo).conditions{iCond}, iRep, nReps, 'info');
        if isfile([char(optionsFile.paths.cohort(cohortNo).data), 'mouse', char(currMouse), '_', loadInfoName, '.mat'])
            hasData = true;
            break;
        end
    end
    if ~hasData
        disp(['Data for mouse ', currMouse, ' not available in any condition']);
        noDataArray(iMouse) = iMouse;
    end
end

noDataArray = sort(noDataArray, 'descend');
noDataArray(noDataArray == 0) = [];

for i = noDataArray
    mouseIDs(i) = [];
end
nSize = numel(mouseIDs);

for iMouse = 1:nSize
    currMouse = mouseIDs{iMouse};
    for iCond = 1:length(optionsFile.cohort(cohortNo).conditions)
        loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], optionsFile.cohort(cohortNo).conditions{iCond}, iRep, nReps, 'info');
        if isfile([char(optionsFile.paths.cohort(cohortNo).data), 'mouse', char(currMouse), '_', loadInfoName, '.mat'])
            load([char(optionsFile.paths.cohort(cohortNo).data), 'mouse', char(currMouse), '_', loadInfoName]);
            if any([MouseInfoTable.exclCrit2_met, MouseInfoTable.exclCrit1_met], 'all')
                disp(['Mouse ', currMouse, ' excluded based on exclusion criteria']);
                exclArray(iMouse) = iMouse;
                break;
            end
        end
    end
end

exclArray = sort(exclArray, 'descend');
exclArray(exclArray == 0) = [];

for i = exclArray
    mouseIDs(i) = [];
end
nSize = numel(mouseIDs);

% Create table with one row per mouse and columns for each parameter/condition
RQ3_4_dataTable = table('Size', [nSize, 2+9], ...  % 2 basic columns + 9 parameter columns (3 parameters x 3 conditions)
    'VariableTypes', {'string', 'string', ...
    'double', 'double', 'double', ... % HGF2 prior precision omega2
    'double', 'double', 'double', ... % HGF3 prior precision omega2
    'double', 'double', 'double'}, ... % HGF3 prior precision omega3
    'VariableNames', {'ID', 'sex', ...
    'HGF2_priorPrec_omega2_saline', 'HGF2_priorPrec_omega2_5mg', 'HGF2_priorPrec_omega2_10mg', ...
    'HGF3_priorPrec_omega2_saline', 'HGF3_priorPrec_omega2_5mg', 'HGF3_priorPrec_omega2_10mg', ...
    'HGF3_priorPrec_omega3_saline', 'HGF3_priorPrec_omega3_5mg', 'HGF3_priorPrec_omega3_10mg'});

% Populate the table
for iMouse = 1:nSize
    currMouse = mouseIDs{iMouse};

    % Set ID
    RQ3_4_dataTable.ID(iMouse) = currMouse;

    % Get basic info (sex) from the first available condition file
    for iCond = 1:length(optionsFile.cohort(cohortNo).conditions)
        loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], optionsFile.cohort(cohortNo).conditions{iCond}, iRep, nReps, 'info');
        infoPath = [char(optionsFile.paths.cohort(cohortNo).data), 'mouse', char(currMouse), '_', loadInfoName, '.mat'];
        if isfile(infoPath)
            load(infoPath, 'MouseInfoTable');
            RQ3_4_dataTable.sex(iMouse) = MouseInfoTable.Sex;
            break;
        end
    end

    % Get prior precision values for each condition
    conditions = {'saline', '5mg', '10mg'};

    for iCond = 1:length(conditions)
        currCondition = conditions{iCond};

        % Get file name base for this condition
        loadName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], currCondition, iRep, nReps, []);

        % HGF 2-level - prior precision of omega2
        hgf2_col = ['HGF2_priorPrec_omega2_', currCondition];
        fitPath = [char(optionsFile.paths.cohort(cohortNo).results), 'mouse', char(currMouse), '_', ...
            loadName, '_', optionsFile.dataFiles.rawFitFile{model_HGF2}, '.mat'];

        if isfile(fitPath)
            load(fitPath, 'est');
            if isfield(est.traj, 'sahat') && size(est.traj.sahat, 2) >= 2
                RQ3_4_dataTable.(hgf2_col)(iMouse) = est.traj.sahat(1, 2);  % First precision estimate of omega2
            else
                warning('Prior precision field est.traj.sahat(1,2) not found for mouse %s in condition %s (HGF2)', currMouse, currCondition);
                RQ3_4_dataTable.(hgf2_col)(iMouse) = NaN;
            end
        else
            RQ3_4_dataTable.(hgf2_col)(iMouse) = NaN;
        end

        % HGF 3-level - load file once for both omega2 and omega3
        fitPath = [char(optionsFile.paths.cohort(cohortNo).results), 'mouse', char(currMouse), '_', ...
            loadName, '_', optionsFile.dataFiles.rawFitFile{model_HGF3}, '.mat'];

        if isfile(fitPath)
            load(fitPath, 'est');

            % HGF 3-level - prior precision of omega2
            hgf3_omega2_col = ['HGF3_priorPrec_omega2_', currCondition];
            if isfield(est.traj, 'sahat') && size(est.traj.sahat, 2) >= 2
                RQ3_4_dataTable.(hgf3_omega2_col)(iMouse) = est.traj.sahat(1, 2);  % First precision estimate of omega2
            else
                warning('Prior precision field est.traj.sahat(1,2) not found for mouse %s in condition %s (HGF3)', currMouse, currCondition);
                RQ3_4_dataTable.(hgf3_omega2_col)(iMouse) = NaN;
            end

            % HGF 3-level - prior precision of omega3
            hgf3_omega3_col = ['HGF3_priorPrec_omega3_', currCondition];
            if isfield(est.traj, 'sahat') && size(est.traj.sahat, 2) >= 3
                RQ3_4_dataTable.(hgf3_omega3_col)(iMouse) = est.traj.sahat(1, 3);  % First precision estimate of omega3
            else
                warning('Prior precision field est.traj.sahat(1,3) not found for mouse %s in condition %s', currMouse, currCondition);
                RQ3_4_dataTable.(hgf3_omega3_col)(iMouse) = NaN;
            end
        else
            % If file doesn't exist, set both HGF3 parameters to NaN
            hgf3_omega2_col = ['HGF3_priorPrec_omega2_', currCondition];
            hgf3_omega3_col = ['HGF3_priorPrec_omega3_', currCondition];
            RQ3_4_dataTable.(hgf3_omega2_col)(iMouse) = NaN;
            RQ3_4_dataTable.(hgf3_omega3_col)(iMouse) = NaN;
        end
    end
end

% Remove any rows with ALL NaN values across parameter columns
allNanRows = true(nSize, 1);
conditions = {'saline', '5mg', '10mg'};

for iCond = 1:length(conditions)
    currCondition = conditions{iCond};
    hgf2_col = ['HGF2_priorPrec_omega2_', currCondition];
    hgf3_omega2_col = ['HGF3_priorPrec_omega2_', currCondition];
    hgf3_omega3_col = ['HGF3_priorPrec_omega3_', currCondition];

    % Check if all parameters are NaN for this condition
    allNanRows = allNanRows & isnan(RQ3_4_dataTable.(hgf2_col)) & ...
        isnan(RQ3_4_dataTable.(hgf3_omega2_col)) & ...
        isnan(RQ3_4_dataTable.(hgf3_omega3_col));
end

if any(allNanRows)
    RQ3_4_dataTable(allNanRows, :) = [];
    fprintf('Removed %d rows with no prior precision values across all conditions.\n', sum(allNanRows));
end

% Save table as both .mat and .csv
savePath = [optionsFile.paths.cohort(cohortNo).groupLevel, optionsFile.cohort(cohortNo).taskPrefix, ...
    optionsFile.cohort(cohortNo).name, '_RQ3_4_dataTable'];

save([savePath, '.mat'], 'RQ3_4_dataTable');
writetable(RQ3_4_dataTable, [savePath, '.csv']);

disp(['Table saved to: ', savePath, '.csv']);
end