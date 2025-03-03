function performBMS

%% INITIALIZE Variables for running this function
% specifications for this analysis
if exist('optionsFile.mat','file')==2
    load("optionsFile.mat");
else
    optionsFile = runOptions();
end

disp('************************************** BAYESIAN MODEL SELECTION **************************************');
disp('*');
disp('*');

% >>>>>>>>> COMMENT: here only one cohort is loaded (2023), fid a way to
% load the other cohorts, e.g. 2024_HGFPilot3 and the new ones

load([optionsFile.paths.resultsDir,filesep,'2023_UCMS2',filesep,'modelInv.mat']);

% KW note: the code below only works for those cohorts that have treatments and controls
% in them. That poses the question: Did we have that at all? I think we
% have a within-mice-design, right?
groupCodes = codeGroups;
groups = [find(groupCodes==1) find(groupCodes==0)]; %0 = controls,1 = treatment

addpath(genpath([pwd,filesep,'spm12']));

for modeli = length(optionsFile.model.space)
    for mousei = 1:optionsFile.cohort.nSize
        res.LME(mousei,modeli)   = allMice(mousei,modeli).est.optim.LME;
        res.prc_param(mousei,modeli).ptrans = allMice(mousei,modeli).est.p_prc.ptrans(optionsFile.modelSpace(modeli).prc_idx);
        res.obs_param(mousei,modeli).ptrans = allMice(mousei,modeli).est.p_obs.ptrans(optionsFile.modelSpace(modeli).obs_idx);
    end
en


end