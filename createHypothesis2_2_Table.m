function createHypothesis2_2_Table

% createHypothesis2_2_Table - Extract learning and volatility parameters across task repetitions
%
% This function extracts computational model parameters from fitted models across three task
% repetitions for each mouse. It collects volatility parameters from the
% hierarchical Gaussian filter models (2-level (omega2) and 3-level (omega2, omega3))
% and learning rate (alpha) from the Rescorla-Wagner model. The resulting data table contains
% one row per mouse with parameters from all models and repetitions, allowing for
% statistical analysis of how these parameters change with repeated task exposure.
% The output is saved as both .mat and .csv files.
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

% Prespecify models to extract parameters from
model_HGF3 = 1;  % HGF 3-level model
model_HGF2 = 2;  % HGF 2-level model
model_RW = 3;    % Rescorla-Wagner model

% Prespecify variables needed
iTask = 1;
nReps = 3;
cohortNo = 2;
subCohort = [];
currTask = optionsFile.cohort(cohortNo).testTask(1).name;
[mouseIDs, nSize] = getSampleVars(optionsFile, cohortNo, subCohort);

%% EXCLUDE MICE from this analysis
% Check available mouse data and exclusion criteria
noDataArray = zeros(1, nSize);
exclArray = zeros(1, nSize);

for iMouse = 1:nSize
    currMouse = mouseIDs{iMouse};
    loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], [], 1, nReps, 'info');
    if ~isfile([char(optionsFile.paths.cohort(cohortNo).data), 'mouse', char(currMouse), '_', loadInfoName, '.mat'])
        disp(['Data for mouse ', currMouse, ' not available']);
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
    loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], [], 1, nReps, 'info');
    load([char(optionsFile.paths.cohort(cohortNo).data), 'mouse', char(currMouse), '_', loadInfoName]);
    if any([MouseInfoTable.exclCrit2_met, MouseInfoTable.exclCrit1_met], 'all')
        disp(['Mouse ', currMouse, ' excluded based on exclusion criteria']);
        exclArray(iMouse) = iMouse;
    end
end

exclArray = sort(exclArray, 'descend');
exclArray(exclArray == 0) = [];

for i = exclArray
    mouseIDs(i) = [];
end
nSize = numel(mouseIDs);

% Create table with one row per mouse and columns for each parameter/repetition
RQ2_2_dataTable = table('Size', [nSize, 2+12], ...  % 2 basic columns + 12 parameter columns (4 parameters x 3 reps)
    'VariableTypes', {'string', 'string', ...
    'double', 'double', 'double', ... % HGF2 omega2
    'double', 'double', 'double', ... % HGF3 omega2
    'double', 'double', 'double', ... % HGF3 omega3
    'double', 'double', 'double'}, ... % RW alpha
    'VariableNames', {'ID', 'sex', ...
    'HGF2_omega2_rep1', 'HGF2_omega2_rep2', 'HGF2_omega2_rep3', ...
    'HGF3_omega2_rep1', 'HGF3_omega2_rep2', 'HGF3_omega2_rep3', ...
    'HGF3_omega3_rep1', 'HGF3_omega3_rep2', 'HGF3_omega3_rep3', ...
    'RW_alpha_rep1', 'RW_alpha_rep2', 'RW_alpha_rep3'});

% Populate the table with one row per mouse
for iMouse = 1:nSize
    currMouse = mouseIDs{iMouse};

    % Load basic info from rep 1 (for ID and sex)
    loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], [], 1, nReps, 'info');
    infoPath = [char(optionsFile.paths.cohort(cohortNo).data), 'mouse', char(currMouse), '_', loadInfoName, '.mat'];

    if isfile(infoPath)
        load(infoPath, 'MouseInfoTable');
        RQ2_2_dataTable.ID(iMouse) = currMouse;
        RQ2_2_dataTable.sex(iMouse) = MouseInfoTable.Sex;
    else
        RQ2_2_dataTable.ID(iMouse) = currMouse;
        RQ2_2_dataTable.sex(iMouse) = "";
    end

    % For each repetition, extract parameters from all three models
    for iRep = 1:nReps
        % Get file name for this repetition
        loadName = getFileName(optionsFile.cohort(cohortNo).taskPrefix, currTask, [], [], iRep, nReps, []);

        % Extract HGF 2-level omega2
        hgf2_col = ['HGF2_omega2_rep', num2str(iRep)];
        fitPath = [char(optionsFile.paths.cohort(cohortNo).results), 'mouse', char(currMouse), '_', ...
            loadName, '_', optionsFile.dataFiles.rawFitFile{model_HGF2}, '.mat'];

        if isfile(fitPath)
            load(fitPath, 'est');
            RQ2_2_dataTable.(hgf2_col)(iMouse) = est.p_prc.om(2);
        else
            RQ2_2_dataTable.(hgf2_col)(iMouse) = NaN;
        end

        % Extract HGF 3-level omega2 and omega3
        hgf3_omega2_col = ['HGF3_omega2_rep', num2str(iRep)];
        hgf3_omega3_col = ['HGF3_omega3_rep', num2str(iRep)];
        fitPath = [char(optionsFile.paths.cohort(cohortNo).results), 'mouse', char(currMouse), '_', ...
            loadName, '_', optionsFile.dataFiles.rawFitFile{model_HGF3}, '.mat'];

        if isfile(fitPath)
            load(fitPath, 'est');
            RQ2_2_dataTable.(hgf3_omega2_col)(iMouse) = est.p_prc.om(2);
            RQ2_2_dataTable.(hgf3_omega3_col)(iMouse) = est.p_prc.om(3);
        else
            RQ2_2_dataTable.(hgf3_omega2_col)(iMouse) = NaN;
            RQ2_2_dataTable.(hgf3_omega3_col)(iMouse) = NaN;
        end

        % Extract Rescorla-Wagner alpha parameter
        rw_col = ['RW_alpha_rep', num2str(iRep)];
        fitPath = [char(optionsFile.paths.cohort(cohortNo).results), 'mouse', char(currMouse), '_', ...
            loadName, '_', optionsFile.dataFiles.rawFitFile{model_RW}, '.mat'];

        if isfile(fitPath)
            load(fitPath, 'est');
            if isfield(est.p_prc, 'al')
                RQ2_2_dataTable.(rw_col)(iMouse) = est.p_prc.al;
            else
                RQ2_2_dataTable.(rw_col)(iMouse) = NaN;
            end
        else
            RQ2_2_dataTable.(rw_col)(iMouse) = NaN;
        end
    end
end

% Remove any rows with ALL NaN values across parameter columns
allNanRows = true(nSize, 1);
for iRep = 1:nReps
    hgf2_col = ['HGF2_omega2_rep', num2str(iRep)];
    hgf3_omega2_col = ['HGF3_omega2_rep', num2str(iRep)];
    hgf3_omega3_col = ['HGF3_omega3_rep', num2str(iRep)];
    rw_col = ['RW_alpha_rep', num2str(iRep)];

    % Check if all parameters are NaN for this repetition
    allNanRows = allNanRows & isnan(RQ2_2_dataTable.(hgf2_col)) & ...
        isnan(RQ2_2_dataTable.(hgf3_omega2_col)) & ...
        isnan(RQ2_2_dataTable.(hgf3_omega3_col)) & ...
        isnan(RQ2_2_dataTable.(rw_col));
end

if any(allNanRows)
    RQ2_2_dataTable(allNanRows, :) = [];
    fprintf('Removed %d rows with no parameter values across all repetitions.\n', sum(allNanRows));
end

% Save table as both .mat and .csv
savePath = [optionsFile.paths.cohort(cohortNo).groupLevel, optionsFile.cohort(cohortNo).taskPrefix, ...
    optionsFile.cohort(cohortNo).name, '_RQ2_2_dataTable'];

save([savePath, '.mat'], 'RQ2_2_dataTable');
writetable(RQ2_2_dataTable, [savePath, '.csv']);

disp(['Table saved to: ', savePath, '.csv']);
end