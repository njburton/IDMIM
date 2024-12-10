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

%% CREATE TABLE
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

saveDir = [optionsFile.paths.plotsDir,filesep,'investigateParameters',filesep];
createParameterViolins(dataTbl, saveDir);

%% STATS

% [H,P,CI,STATS] = ttest(dataTbl.RW_alpha(find(groupCodes)),dataTbl.RW_alpha(find(~groupCodes)));
% [H,P,CI,STATS] = ttest(dataTbl.HGF_omega1(find(groupCodes)),dataTbl.HGF_omega1(find(~groupCodes)));
% [H,P,CI,STATS] = ttest(dataTbl.HGF_omega2(find(groupCodes)),dataTbl.HGF_omega2(find(~groupCodes)));
toc
end