function performBMS(cohortNo,subCohort,iTask,iCondition,iRep)

%% performBMS
%  Performs Bayesian Model Selection to determine what model in the model
%  space describes the data acquired in the current dataset (cohort) best
%
%   SYNTAX:       preformBMS(cohortNo)
%
%   IN: cohortNo:  integer, cohort number, see optionsFile for what cohort
%                            corresponds to what number in the
%                            optionsFile.cohort(cohortNo).name struct.
%
%       subCohort: string, {'control','treatment'} OR [], if you are running this
%                           function for all subCohorts use [], otherwise specify using the appropriate string
%
%       iTask: integer, task number see optionsFile for what task
%                            corresponds to what number.
%
%       iCondition: integer, condition number. See optionsFile for what what place in the cell {cond1, cond2...}
%                            the condition that you want to run this function for in appears. If you are calling
%                            this function from the runAnalysis.m or another wrapper function, loop through
%                            conditions there.
%
%       iRep:       integer, repetition number. iRep= 1 if the current Task is not repeated more than once in this cohort.
%
%       >>!! NOTE: All the above variables are saved inf the optionsFile struct and specifed here: setDatasetSpecifics.m << !!
%
% Original: 29-05-2024; Katharina V. Wellstein,
%           katharina.wellstein@newcastle.edu.au
%
% -------------------------------------------------------------------------
% This file is released under the terms of the GNU General Public Licence
% (GPL), version 3. You can redistribute it and/or modify it under the
% terms of the GPL (either version 3 or, at your option, any later version.
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

%% Suppress SPM/FieldTrip path warnings
warning('off', 'MATLAB:rmpath:DirNotFound');

%% INITIALIZE Variables for running this function

disp('************************************** BAYESIAN MODEL SELECTION **************************************');
disp('*');
disp('*');

% load or run options for running this function
if exist('optionsFile.mat','file')==2
    load('optionsFile.mat');
else
    optionsFile = runOptions();
end

% prespecify variables needed for running this function
nModels  = numel(optionsFile.model.space);
nReps    = optionsFile.cohort(cohortNo).taskRepetitions;
currTask = optionsFile.cohort(cohortNo).testTask(iTask).name;
[mouseIDs,nSize] = getSampleVars(optionsFile,cohortNo,subCohort);

if isempty(optionsFile.cohort(cohortNo).conditions)
    currCondition = [];
else
    currCondition = optionsFile.cohort(cohortNo).conditions{iCondition};
end

% model settings
addpath(genpath([optionsFile.paths.toolboxDir,'spm']));
optionsFile = setup_configFiles(optionsFile,cohortNo);

disp(['*** for ',currCondition, ' mice in ', char(optionsFile.cohort(cohortNo).name), ' cohort ***']);

%% Create study-specific title prefix
if cohortNo == 1
    studyPrefix = 'Study 1: ';
    if ~isempty(subCohort)
        % Capitalise first letter of subCohort
        subCohortFormatted = [upper(subCohort(1)), lower(subCohort(2:end))];
        titlePrefix = [studyPrefix, subCohortFormatted, ' '];
    else
        titlePrefix = studyPrefix;
    end
elseif cohortNo == 2
    % For cohort 2, include repetition number
    titlePrefix = ['Repetition ', num2str(iRep), ' '];
else
    % For cohort 3 and other cohorts, use existing format with conditions
    if ~isempty(currCondition)
        titlePrefix = [currCondition, ' '];
    else
        titlePrefix = '';
    end
end

%% EXCLUDE MICE from this analysis
% check available mouse data and exclusion criteria
noDataArray = zeros(1,nSize);
exclArray   = zeros(1,nSize);

% check for what mice no data is available
for iMouse = 1:nSize
    currMouse = mouseIDs{iMouse};
    loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,...
        [],currCondition,iRep,nReps,'info');
    if isfile([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',loadInfoName,'.mat'])
    else
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

% check what mice are to be excluded based on exclusion criteria
for iMouse = 1:nSize
    currMouse = mouseIDs{iMouse};
    loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,...
        [],currCondition,iRep,nReps,'info');
    load([char(optionsFile.paths.cohort(cohortNo).data),...
        'mouse',char(currMouse),'_',loadInfoName]);
    if any([MouseInfoTable.exclCrit2_met,MouseInfoTable.exclCrit1_met],'all')
        disp(['mouse ', currMouse,' excluded based on exclusion criteria']);
        exclArray(iMouse) = iMouse;
    end
end

exclArray = sort(exclArray,'descend');
exclArray(exclArray==0)=[];

for i=exclArray
    mouseIDs(i) =[];
end
nSize = numel(mouseIDs);

%% LOAD mice
for iMouse = 1:nSize
    currMouse = mouseIDs{iMouse};
    for iModel = 1:nModels
        % load results from real data model inversion
        loadName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,...
            [],currCondition,iRep,nReps,[]);
        load([char(optionsFile.paths.cohort(cohortNo).results),...
            'mouse',char(currMouse),'_',loadName,'_',optionsFile.dataFiles.rawFitFile{iModel},'.mat']);

        res.LME(iMouse,iModel)   = est.optim.LME;
        res.prc_param(iMouse,iModel).ptrans = est.p_prc.ptrans(optionsFile.modelSpace(iModel).prc_idx);
        res.obs_param(iMouse,iModel).ptrans = est.p_obs.ptrans(optionsFile.modelSpace(iModel).obs_idx);
    end
end


%% PERFORM rfx BMS
[res.BMS.alpha,res.BMS.exp_r,res.BMS.xp,res.BMS.pxp,res.BMS.bor] = spm_BMS(res.LME);

%VBA toolbox code here
%Use wiki to help costruct LME array in correct orientation 
%1st test to do check that counterbalancing worked, if no effects collapse across sex
%2nd test, check theres no effect of sex, if no difference between sex, collapse across conditions
% create 3-dimensional array with rows (mice), cols (model) and, 3d (condition/group/sex/counterbalancing)


if optionsFile.doCreatePlots
    % Create figure title based on cohort and condition
    if cohortNo == 3
        % For cohort 3, create study-specific titles with capitalised condition
        conditionFormatted = [upper(currCondition(1)), lower(currCondition(2:end))];
        bms_title = sprintf('Study 3: %s Bayesian Model Selection', conditionFormatted);
        subject_title_prefix = sprintf('Study 3: %s Subject-level Model Comparison', conditionFormatted);
    else
        % For other cohorts, use existing format
        bms_title = ['Bayesian Model Selection results of ',subCohort,currCondition,currTask,' repetition ',num2str(iRep),' group'];
        subject_title_prefix = [titlePrefix]; % Assuming titlePrefix is defined elsewhere
    end

    % Create figure
    pos0 = get(0,'screenSize');
    pos = [1,pos0(4)/2,pos0(3)/1.2,pos0(4)/1.2];

    %Plotting details
    %Create figure
    figure('WindowState','maximized','Name','BMS all','Color',[1 1 1]);

    % plot BMS results
    hold on; subplot(1,3,1); bar(1, res.BMS.exp_r(1),'FaceColor',[0.266666666666667 0.447058823529412 0.768627450980392],'EdgeColor',[0.149 0.149 0.149]);
    hold on; subplot(1,3,1); bar(2, res.BMS.exp_r(2),'FaceColor',[0.929411764705882 0.490196078431373 0.192156862745098],'EdgeColor',[0.149 0.149 0.149]);
    hold on; subplot(1,3,1); bar(3, res.BMS.exp_r(3),'FaceColor',[0.43921568627451 0.67843137254902 0.27843137254902],'EdgeColor',[0.149 0.149 0.149]);
    ylabel ('Posterior probability', 'FontSize', 22,'FontName','Arial'); ylim([0 1]);

    set(gca, 'XTick', []);
    set(gca,'box','off'); get(gca, 'YTick'); set(gca, 'FontSize', 22);
    ax1       = subplot(1,3,1);
    ax1.YTick = [0 0.25 0.5 0.75 1.0];
    ax1.GridLineStyle = ":";
    ax1.XTick = [];
    ax1.YGrid ="on";
    ax1.YTick = [0 0.25 0.5 0.75 1];
    h_leg     = legend(optionsFile.model.names{1},optionsFile.model.names{2},optionsFile.model.names{3}, 'Location', 'northeast');
    set(h_leg,'box','off','FontSize', 22);
    set(gca, 'color','none');

    hold on; subplot(1,3,2); bar(1, res.BMS.xp(1),'FaceColor',[0.266666666666667 0.447058823529412 0.768627450980392],'EdgeColor',[0.149 0.149 0.149]);
    hold on; subplot(1,3,2); bar(2, res.BMS.xp(2),'FaceColor',[0.929411764705882 0.490196078431373 0.192156862745098],'EdgeColor',[0.149 0.149 0.149]);
    hold on; subplot(1,3,2); bar(3, res.BMS.xp(3),'FaceColor',[0.43921568627451 0.67843137254902 0.27843137254902],'EdgeColor',[0.149 0.149 0.149]);
    ylabel('Exceedance probability', 'FontSize', 22,'FontName','Arial'); ylim([0 1]);
    set(gca, 'XTick', []);
    set(gca,'box','off'); get(gca, 'YTick'); set(gca, 'FontSize', 22);
    ax2 = subplot(1,3,2);
    ax2.YTick = [0 0.25 0.5 0.75 1.0];
    ax2.GridLineStyle = ":";
    ax2.XTick = [];
    ax2.YGrid ="on";
    ax2.YTick = [0 0.25 0.5 0.75 1];
    set(gca, 'color', 'none');

    hold on; subplot(1,3,3); bar(1, res.BMS.pxp(1),'FaceColor',[0.266666666666667 0.447058823529412 0.768627450980392],'EdgeColor',[0.149 0.149 0.149]);
    hold on; subplot(1,3,3); bar(2, res.BMS.pxp(2),'FaceColor',[0.929411764705882 0.490196078431373 0.192156862745098],'EdgeColor',[0.149 0.149 0.149]);
    hold on; subplot(1,3,3); bar(3, res.BMS.pxp(3),'FaceColor',[0.43921568627451 0.67843137254902 0.27843137254902],'EdgeColor',[0.149 0.149 0.149]);
    ylabel('Protected exceedance probability', 'FontSize', 22,'FontName','Arial'); ylim([0 1]);
    set(gca, 'XTick', []);
    set(gca,'box','off'); get(gca, 'YTick'); set(gca, 'FontSize', 22);
    ax2       = subplot(1,3,3);
    ax2.YTick = [0 0.25 0.5 0.75 1.0];
    ax2.GridLineStyle = ":";
    ax2.XTick = [];
    ax2.YGrid ="on";
    ax2.YTick = [0 0.25 0.5 0.75 1];

    % Use the cohort-specific title
    sgtitle(bms_title, 'FontSize', 22,'FontName','Arial');
    set(gcf, 'color', 'white');
    set(gca, 'color', 'none');

    %Save plot
    saveName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,subCohort,currCondition,iRep,nReps,[]);
    figdir = fullfile(optionsFile.paths.cohort(cohortNo).groupLevel, [saveName, '_BMS']);

    % Check if directory exists, create if needed
    [filepath, ~, ~] = fileparts(figdir);
    if ~exist(filepath, 'dir')
        mkdir(filepath);
    end

    print(figdir, '-dpng', '-r300');
    savefig([figdir, '.fig']);
    close all;

    %% Subject-Level Model Comparison Heatmap
    figure('WindowState', 'maximized', 'Name', 'Subject-Level Model Comparison', 'Color', [1 1 1]);

    % Normalise LME per subject to make values comparable
    % Subtract the maximum LME value for each subject (row)
    normalised_lme = res.LME - max(res.LME, [], 2);

    if ~isempty(mouseIDs) && length(mouseIDs) == size(res.LME, 1)
        subject_labels = mouseIDs;
    else
        subject_labels = cellstr(strcat('Subject ', num2str((1:size(res.LME, 1))')));
    end

    % Set standardized color range based on cohort
    switch cohortNo
        case 1
            standardized_min = -7;
        case 2
            standardized_min = -12;
        case 3
            standardized_min = -14;
        otherwise
            % Fallback for any other cohorts
            min_value = min(normalised_lme(:));
            standardized_min = -ceil(abs(min_value));
    end

    % Create heatmap title based on cohort
    if cohortNo == 3
        conditionFormatted = [upper(currCondition(1)), lower(currCondition(2:end))];
        heatmap_title = sprintf('Study 3: %s Subject-level Model Comparison', conditionFormatted);
    else
        heatmap_title = [titlePrefix, 'Subject-level Model Comparison'];
    end

    % Create heatmap with standardised color limits
    h = heatmap(optionsFile.model.names, subject_labels, normalised_lme);
    h.Title = heatmap_title;
    h.XLabel = 'Model';
    h.YLabel = 'Subject ID';
    h.ColorbarVisible = 'on';

    % Using a diverging colormap
    colormap(flipud(brewermap(64, '-RdBu')));

    % Set standardised color limits for consistent comparison across cohorts
    h.ColorLimits = [standardized_min, 0];

    h.CellLabelFormat = '%.1f';
    h.FontSize = 22;
    h.FontName = 'Arial';
    h.GridVisible = 'on';

    % Save the subject-level comparison plot
    figdir_subject = fullfile(optionsFile.paths.cohort(cohortNo).groupLevel, [saveName, '_Subject_Level_Comparison']);

    % Check if directory exists, create if needed
    [filepath, ~, ~] = fileparts(figdir_subject);
    if ~exist(filepath, 'dir')
        mkdir(filepath);
    end

    print(figdir_subject, '-dpng', '-r300');
    savefig([figdir_subject, '.fig']);
    close all;

    disp(['*** Bayesian Model Selection of ',char(optionsFile.cohort(cohortNo).name), ' complete and plots successfully saved to ', optionsFile.paths.cohort(cohortNo).groupLevel,'. ***']);

end

%% Restore warnings
warning('on', 'MATLAB:rmpath:DirNotFound');

end