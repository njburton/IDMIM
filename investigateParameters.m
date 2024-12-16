function investigateParameters
%% investigateParameters - Process and extract experimental task data from MED-PC files
%
% SYNTAX:  investigateParameters(optionsFile)
% INPUT:   optionsFile - Structure containing analysis options and paths
% OUTPUT:  optionsFile - Updated structure after data processing
%
% Authors: Katharina Wellstein (30/5/2023), Nicholas Burton (23/2/2024)
% -------------------------------------------------------------------------
tic

% Load options
load("optionsFile.mat");
% Load modelInv.mat
load([optionsFile.paths.mouseModelFitFilesDir,filesep,'modelInv.mat']);
load(char(fullfile(optionsFile.paths.databaseDir, optionsFile.fileName.dataBaseFileName)));

%% CREATE ARCHIVEDATATABLE
TASK_TABLE_SPEC = {...
    'MouseID',            'string';
    'Group',              'string';
    'Sex',                'string';
    'Task',               'string';
    'TaskRepetition',     'single';
    'omissions',          'double';
    'HGF3_zeta',          'double';
    'HGF3_wt',            'double';
    'HGF3_omega2',        'single';
    'HGF3_omega3',        'double';
    'HGF3_sahat1',        'double';
    'HGF3_sahat2',        'double';
    'HGF3_sahat3',        'double';
    'HGF3_epsi2',         'double';
    'HGF3_epsi3',         'double';
    'HGF2_zeta',          'double';
    'HGF2_wt',            'double';
    'HGF2_omega2',        'single';
    'HGF2_sahat1',        'double';
    'HGF2_sahat2',        'double';
    'HGF2_sahat3',        'double';
    'HGF2_epsi2',         'double';
    'HGF2_epsi3',         'double';
    'RW_zeta',            'double';
    'RW_alpha',           'double'};

dataTbl = table('Size', [length(rawDataFileInfo.MouseID), size(TASK_TABLE_SPEC, 1)], ...
    'VariableTypes', TASK_TABLE_SPEC(:,2)', ...
    'VariableNames', TASK_TABLE_SPEC(:,1)');

%% CREATE DATAANALYSISTABLE
TASK_TABLE2_SPEC = {...
    'MouseID',            'string';
    'Group',              'string';
    'Sex',                'string';
    'omissions',          'double';
    'HGF3_wt_TestA_Rep1', 'double';
    'HGF3_wt_TestA_Rep2', 'double';
    'HGF3_wt_TestA_Rep3', 'double';
    'HGF3_wt_TestB_Rep1', 'double';
    'HGF3_wt_TestB_Rep2', 'double';
    'HGF3_wt_TestB_Rep3', 'double';
    'HGF2_wt_TestA_Rep1', 'double';
    'HGF2_wt_TestA_Rep2', 'double';
    'HGF2_wt_TestA_Rep3', 'double';
    'HGF2_wt_TestB_Rep1', 'double';
    'HGF2_wt_TestB_Rep2', 'double';
    'HGF2_wt_TestB_Rep3', 'double';
    'HGF3_omega3_TestA_Rep1', 'double';
    'HGF3_omega3_TestA_Rep2', 'double';
    'HGF3_omega3_TestA_Rep3', 'double';
    'HGF3_omega3_TestB_Rep1', 'double';
    'HGF3_omega3_TestB_Rep2', 'double';
    'HGF3_omega3_TestB_Rep3', 'double';
    'HGF2_omega3_TestA_Rep1', 'double';
    'HGF2_omega3_TestA_Rep2', 'double';
    'HGF2_omega3_TestA_Rep3', 'double';
    'HGF2_omega3_TestB_Rep1', 'double';
    'HGF2_omega3_TestB_Rep2', 'double';
    'HGF2_omega3_TestB_Rep3', 'double';
    'HGF3_omega2_TestA_Rep1', 'double';
    'HGF3_omega2_TestA_Rep2', 'double';
    'HGF3_omega2_TestA_Rep3', 'double';
    'HGF3_omega2_TestB_Rep1', 'double';
    'HGF3_omega2_TestB_Rep2', 'double';
    'HGF3_omega2_TestB_Rep3', 'double';
    'HGF2_omega2_TestA_Rep1', 'double';
    'HGF2_omega2_TestA_Rep2', 'double';
    'HGF2_omega2_TestA_Rep3', 'double';
    'HGF2_omega2_TestB_Rep1', 'double';
    'HGF2_omega2_TestB_Rep2', 'double';
    'HGF2_omega2_TestB_Rep3', 'double';
    'RW_alpha_TestA_Rep1', 'double';
    'RW_alpha_TestA_Rep2', 'double';
    'RW_alpha_TestA_Rep3', 'double';
    'RW_alpha_TestB_Rep1', 'double';
    'RW_alpha_TestB_Rep2', 'double';
    'RW_alpha_TestB_Rep3', 'double'};

    JASPDataTbl = table('Size', [length(rawDataFileInfo.MouseID), size(TASK_TABLE2_SPEC, 1)], ...
    'VariableTypes', TASK_TABLE2_SPEC(:,2)', ...
    'VariableNames', TASK_TABLE2_SPEC(:,1)');

    %% dataTbl
for mousei = 1:length(rawDataFileInfo.MouseID)
    dataTbl.MouseID(mousei)        = rawDataFileInfo.MouseID(mousei);
    dataTbl.Sex(mousei)            = rawDataFileInfo.sex(mousei);
    dataTbl.Group(mousei)          = rawDataFileInfo.group(mousei);
    dataTbl.Task(mousei)           = rawDataFileInfo.Task(mousei);
    dataTbl.TaskRepetition(mousei) = rawDataFileInfo.TaskRepetition(mousei);
    dataTbl.omissions(mousei)      = width(allMice(mousei).est.irr);  

    %computationalParameters
    dataTbl.HGF3_zeta(mousei)       = allMice(mousei,1).est.p_obs.ze;
    dataTbl.HGF3_wt(mousei)         = mean(allMice(mousei,1).est.traj.wt(:,1));
    dataTbl.HGF3_omega2(mousei)     = allMice(mousei,1).est.p_prc.om(2);
    dataTbl.HGF3_omega3(mousei)     = allMice(mousei,1).est.p_prc.om(3);
    dataTbl.HGF3_sahat1(mousei)     = mean(allMice(mousei,1).est.traj.sahat(:,1));
    dataTbl.HGF3_sahat2(mousei)     = mean(allMice(mousei,1).est.traj.sahat(:,2));
    dataTbl.HGF3_sahat3(mousei)     = mean(allMice(mousei,1).est.traj.sahat(:,3));
    dataTbl.HGF3_epsi2(mousei)      = mean(allMice(mousei,1).est.traj.epsi(:,2));
    dataTbl.HGF3_epsi3(mousei)      = mean(allMice(mousei,1).est.traj.epsi(:,3));
    dataTbl.HGF2_zeta(mousei)       = allMice(mousei,2).est.p_obs.ze;
    dataTbl.HGF2_wt(mousei)         = mean(allMice(mousei,2).est.traj.wt(:,1));
    dataTbl.HGF2_omega2(mousei)     = allMice(mousei,2).est.p_prc.om(2);
    dataTbl.HGF2_sahat1(mousei)     = mean(allMice(mousei,2).est.traj.sahat(:,1));
    dataTbl.HGF2_sahat2(mousei)     = mean(allMice(mousei,2).est.traj.sahat(:,2));
    dataTbl.HGF2_sahat3(mousei)     = mean(allMice(mousei,2).est.traj.sahat(:,3));
    dataTbl.HGF2_epsi2(mousei)      = mean(allMice(mousei,2).est.traj.epsi(:,2));
    dataTbl.HGF2_epsi3(mousei)      = mean(allMice(mousei,2).est.traj.epsi(:,3));
    dataTbl.RW_zeta(mousei)         = allMice(mousei,3).est.p_obs.ze;
    dataTbl.RW_alpha(mousei)        = allMice(mousei,3).est.p_prc.al;
end

save([optionsFile.paths.resultsDir,'investigateParametersResults.mat'],'dataTbl');
%writetable(dataTbl,[optionsFile.paths.resultsDir,'investigateParametersResults.csv']);

%create table with just TestTaskData
testTaskData = rawDataFileInfo(rawDataFileInfo.Task=='TestTaskA') && (rawDataFileInfo.Task=='TestTaskB');

%% JASPDataTbl
for mousei = 1:length(rawDataFileInfo.MouseID)
    JASPDataTbl.MouseID(mousei)        = rawDataFileInfo.MouseID(mousei);
    JASPDataTbl.Sex(mousei)            = rawDataFileInfo.sex(mousei);
    JASPDataTbl.Group(mousei)          = rawDataFileInfo.group(mousei);
    JASPDataTbl.omissions(mousei)      = width(allMice(mousei).est.irr);  
    %computationalParameters
    JASPDataTbl.HGF3_wt_TestA_Rep1(mousei) = mean(allMice(mousei,1).est.traj.wt(:,1));
    JASPDataTbl.HGF3_wt_TestA_Rep2(mousei) = mean(allMice(mousei,1).est.traj.wt(:,1));
    JASPDataTbl.HGF3_wt_TestA_Rep3(mousei) = mean(allMice(mousei,1).est.traj.wt(:,1));
    JASPDataTbl.HGF3_wt_TestB_Rep1(mousei) = mean(allMice(mousei,1).est.traj.wt(:,1));
    JASPDataTbl.HGF3_wt_TestB_Rep2(mousei) = mean(allMice(mousei,1).est.traj.wt(:,1));
    JASPDataTbl.HGF3_wt_TestB_Rep3(mousei) = mean(allMice(mousei,1).est.traj.wt(:,1));
    JASPDataTbl.HGF2_wt_TestA_Rep1(mousei) = mean(allMice(mousei,2).est.traj.wt(:,1));
    JASPDataTbl.HGF2_wt_TestA_Rep2(mousei) = mean(allMice(mousei,2).est.traj.wt(:,1));
    JASPDataTbl.HGF2_wt_TestA_Rep3(mousei) = mean(allMice(mousei,2).est.traj.wt(:,1));
    JASPDataTbl.HGF2_wt_TestB_Rep1(mousei) = mean(allMice(mousei,2).est.traj.wt(:,1));
    JASPDataTbl.HGF2_wt_TestB_Rep2(mousei) = mean(allMice(mousei,2).est.traj.wt(:,1));
    JASPDataTbl.HGF2_wt_TestB_Rep3(mousei) = mean(allMice(mousei,2).est.traj.wt(:,1));
    JASPDataTbl.HGF3_omega3_TestA_Rep1(mousei) = allMice(mousei,1).est.p_prc.om(3);
    JASPDataTbl.HGF3_omega3_TestA_Rep2(mousei) = allMice(mousei,1).est.p_prc.om(3);
    JASPDataTbl.HGF3_omega3_TestA_Rep3(mousei) = allMice(mousei,1).est.p_prc.om(3);
    JASPDataTbl.HGF3_omega3_TestB_Rep1(mousei) = allMice(mousei,1).est.p_prc.om(3);
    JASPDataTbl.HGF3_omega3_TestB_Rep2(mousei) = allMice(mousei,1).est.p_prc.om(3);
    JASPDataTbl.HGF3_omega3_TestB_Rep3(mousei) = allMice(mousei,1).est.p_prc.om(3);
    JASPDataTbl.HGF2_omega3_TestA_Rep1(mousei) = allMice(mousei,2).est.p_prc.om(3);
    JASPDataTbl.HGF2_omega3_TestA_Rep2(mousei) = allMice(mousei,2).est.p_prc.om(3);
    JASPDataTbl.HGF2_omega3_TestA_Rep3(mousei) = allMice(mousei,2).est.p_prc.om(3);
    JASPDataTbl.HGF2_omega3_TestB_Rep1(mousei) = allMice(mousei,2).est.p_prc.om(3);
    JASPDataTbl.HGF2_omega3_TestB_Rep2(mousei) = allMice(mousei,2).est.p_prc.om(3);
    JASPDataTbl.HGF2_omega3_TestB_Rep3(mousei) = allMice(mousei,2).est.p_prc.om(3);
    JASPDataTbl.HGF3_omega2_TestA_Rep1(mousei) = allMice(mousei,1).est.p_prc.om(2);
    JASPDataTbl.HGF3_omega2_TestA_Rep2(mousei) = allMice(mousei,1).est.p_prc.om(2);
    JASPDataTbl.HGF3_omega2_TestA_Rep3(mousei) = allMice(mousei,1).est.p_prc.om(2);
    JASPDataTbl.HGF3_omega2_TestB_Rep1(mousei) = allMice(mousei,1).est.p_prc.om(2);
    JASPDataTbl.HGF3_omega2_TestB_Rep2(mousei) = allMice(mousei,1).est.p_prc.om(2);
    JASPDataTbl.HGF3_omega2_TestB_Rep3(mousei) = allMice(mousei,1).est.p_prc.om(2);
    JASPDataTbl.HGF2_omega2_TestA_Rep1(mousei) = allMice(mousei,2).est.p_prc.om(2);
    JASPDataTbl.HGF2_omega2_TestA_Rep2(mousei) = allMice(mousei,2).est.p_prc.om(2);
    JASPDataTbl.HGF2_omega2_TestA_Rep3(mousei) = allMice(mousei,2).est.p_prc.om(2);
    JASPDataTbl.HGF2_omega2_TestB_Rep1(mousei) = allMice(mousei,2).est.p_prc.om(2);
    JASPDataTbl.HGF2_omega2_TestB_Rep2(mousei) = allMice(mousei,2).est.p_prc.om(2);
    JASPDataTbl.HGF2_omega2_TestB_Rep3(mousei) = allMice(mousei,2).est.p_prc.om(2);
    JASPDataTbl.RW_alpha_TestA_Rep1(mousei) = allMice(mousei,3).est.p_prc.al;
    JASPDataTbl.RW_alpha_TestA_Rep2(mousei) = allMice(mousei,3).est.p_prc.al;
    JASPDataTbl.RW_alpha_TestA_Rep3(mousei) = allMice(mousei,3).est.p_prc.al;
    JASPDataTbl.RW_alpha_TestB_Rep1(mousei) = allMice(mousei,3).est.p_prc.al;
    JASPDataTbl.RW_alpha_TestB_Rep2(mousei) = allMice(mousei,3).est.p_prc.al;
    JASPDataTbl.RW_alpha_TestB_Rep3(mousei) = allMice(mousei,3).est.p_prc.al;
end

save([optionsFile.paths.resultsDir,'JASPinvParametersResults.mat'],'JASPDataTbl');
writetable(dataTbl,[optionsFile.paths.resultsDir,'JASPinvParametersResults.csv']);




saveDir = [optionsFile.paths.plotsDir,filesep,'investigateParameters',filesep];
createParameterViolins(dataTbl, saveDir);

%% STATS

% [H,P,CI,STATS] = ttest(dataTbl.RW_alpha(find(groupCodes)),dataTbl.RW_alpha(find(~groupCodes)));
% [H,P,CI,STATS] = ttest(dataTbl.HGF_omega1(find(groupCodes)),dataTbl.HGF_omega1(find(~groupCodes)));
% [H,P,CI,STATS] = ttest(dataTbl.HGF_omega2(find(groupCodes)),dataTbl.HGF_omega2(find(~groupCodes)));
toc
end