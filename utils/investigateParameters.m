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

%% CREATE DATAANALYSISTABLE
TASK_TABLE2_SPEC = {...
    'MouseID',            'string';
    'Group',              'string';
    'Sex',                'string';
    'omissions_TestTaskA_Rep1',          'double';
    'omissions_TestTaskA_Rep2',          'double';
    'omissions_TestTaskA_Rep3',          'double';
    'omissions_TestTaskB_Rep1',          'double';
    'omissions_TestTaskB_Rep2',          'double';
    'omissions_TestTaskB_Rep3',          'double';
    'HGF3_omega3_TestA_Rep1', 'double';
    'HGF3_omega3_TestA_Rep2', 'double';
    'HGF3_omega3_TestA_Rep3', 'double';
    'HGF3_omega3_TestB_Rep1', 'double';
    'HGF3_omega3_TestB_Rep2', 'double';
    'HGF3_omega3_TestB_Rep3', 'double';
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

JASPDataTbl = table('Size', [optionsFile.cohort.nSize, size(TASK_TABLE2_SPEC, 1)], ...
    'VariableTypes', TASK_TABLE2_SPEC(:,2)', ...
    'VariableNames', TASK_TABLE2_SPEC(:,1)');

%create table with just TestTaskData
testTaskAIdx=find(strcmp(rawDataFileInfo.Task(:),"TestTaskA"));
testTaskBIdx=find(strcmp(rawDataFileInfo.Task(:),"TestTaskB"));
testTaskIdx = [testTaskAIdx;testTaskBIdx];

%% JASPDataTbl
for mousei = 1:optionsFile.cohort.nSize
    JASPDataTbl.MouseID(mousei)        = optionsFile.cohort.controlGroup(mousei);
    JASPDataTbl.Group(mousei)          = 'control';
    mouseIdx=find(strcmp(rawDataFileInfo.MouseID(:),optionsFile.cohort.controlGroup(mousei)));
    currMouseIdx = intersect(mouseIdx,testTaskIdx);
     JASPDataTbl.Sex(mousei) = rawDataFileInfo.sex(currMouseIdx(1));
     if mousei == 4
         disp('stop')
     end
    for i = 1:numel(currMouseIdx)
        filei=currMouseIdx(i);
        if ~isempty(intersect(filei,testTaskAIdx))
            %computationalParameters
            if rawDataFileInfo.TaskRepetition(filei)==1
            JASPDataTbl.omissions_TestTaskA_Rep1(mousei) = length(allMice(filei).est.irr);
            JASPDataTbl.HGF3_omega3_TestA_Rep1(mousei) = allMice(filei,1).est.p_prc.om(3);
            JASPDataTbl.HGF3_omega2_TestA_Rep1(mousei) = allMice(filei,1).est.p_prc.om(2);
            JASPDataTbl.HGF2_omega2_TestA_Rep1(mousei) = allMice(filei,2).est.p_prc.om(2);
            JASPDataTbl.RW_alpha_TestA_Rep1(mousei) = allMice(filei,3).est.p_prc.al;
            elseif rawDataFileInfo.TaskRepetition(filei)==2
            JASPDataTbl.omissions_TestTaskA_Rep2(mousei) = length(allMice(filei).est.irr);    
            JASPDataTbl.HGF3_omega3_TestA_Rep2(mousei) = allMice(filei,1).est.p_prc.om(3);
            JASPDataTbl.HGF3_omega2_TestA_Rep2(mousei) = allMice(filei,1).est.p_prc.om(2);
            JASPDataTbl.HGF2_omega2_TestA_Rep2(mousei) = allMice(filei,2).est.p_prc.om(2);
            JASPDataTbl.RW_alpha_TestA_Rep2(mousei) = allMice(filei,3).est.p_prc.al;
            else
            JASPDataTbl.omissions_TestTaskA_Rep3(mousei) = length(allMice(filei).est.irr);    
            JASPDataTbl.HGF3_omega3_TestA_Rep3(mousei) = allMice(filei,1).est.p_prc.om(3);
            JASPDataTbl.HGF3_omega2_TestA_Rep3(mousei) = allMice(filei,1).est.p_prc.om(2);
            JASPDataTbl.HGF2_omega2_TestA_Rep3(mousei) = allMice(filei,2).est.p_prc.om(2);
            JASPDataTbl.RW_alpha_TestA_Rep3(mousei) = allMice(filei,3).est.p_prc.al;
            end
        else
            if rawDataFileInfo.TaskRepetition(filei)==1
            JASPDataTbl.omissions_TestTaskB_Rep1(mousei) = length(allMice(filei).est.irr);
            JASPDataTbl.HGF3_omega3_TestB_Rep1(mousei) = allMice(filei,1).est.p_prc.om(3);
            JASPDataTbl.HGF3_omega2_TestB_Rep1(mousei) = allMice(filei,1).est.p_prc.om(2);
            JASPDataTbl.HGF2_omega2_TestB_Rep1(mousei) = allMice(filei,2).est.p_prc.om(2);
            JASPDataTbl.RW_alpha_TestB_Rep1(mousei) = allMice(filei,3).est.p_prc.al;
            elseif rawDataFileInfo.TaskRepetition(filei)==2
            JASPDataTbl.omissions_TestTaskB_Rep2(mousei) = length(allMice(filei).est.irr);
            JASPDataTbl.HGF3_omega3_TestB_Rep2(mousei) = allMice(filei,1).est.p_prc.om(3);
            JASPDataTbl.HGF3_omega2_TestB_Rep2(mousei) = allMice(filei,1).est.p_prc.om(2);
            JASPDataTbl.HGF2_omega2_TestB_Rep2(mousei) = allMice(filei,2).est.p_prc.om(2);
            JASPDataTbl.RW_alpha_TestB_Rep2(mousei) = allMice(filei,3).est.p_prc.al;
            else
            JASPDataTbl.omissions_TestTaskB_Rep3(mousei) = length(allMice(filei).est.irr);
            JASPDataTbl.HGF3_omega3_TestB_Rep3(mousei) = allMice(filei,1).est.p_prc.om(3);
            JASPDataTbl.HGF3_omega2_TestB_Rep3(mousei) = allMice(filei,1).est.p_prc.om(2);
            JASPDataTbl.HGF2_omega2_TestB_Rep3(mousei) = allMice(filei,2).est.p_prc.om(2);
            JASPDataTbl.RW_alpha_TestB_Rep3(mousei) = allMice(filei,3).est.p_prc.al;
            end
        end

    end
end

% Check if any zeros that should be NaN because they origin from empty
% datasets

checkTable = table2array(JASPDataTbl);
[rows, cols] = find(strcmp(checkTable,"0"));
JASPDataTbl(rows,cols)={NaN};

    save([optionsFile.paths.resultsDir,filesep,'JASPinvParametersResults.mat'],'JASPDataTbl');
    writetable(JASPDataTbl,[optionsFile.paths.resultsDir,filesep,'JASPinvParametersResults.csv']);

    saveDir = [optionsFile.paths.plotsDir,filesep,'investigateParameters',filesep];
    createParameterViolins(dataTbl, saveDir);

    toc
end