function investigateParameters

try
    load('optionsFile.mat');
catch
    optionsFile = runOptions; % specifications for this analysis
end

load([optionsFile.paths.resultsDir,filesep,'modelInv.mat']);

groupCodes = dummyCodeGroups;

%% CREATE TABLE
posteriorTbl = table('Size',[length(optionsFile.Task.MouseID) 5],...
    'VariableTypes',{'string','logical','double','double','double'},...
    'VariableNames',{'mouseID','group','RW_alpha','HGF_omega1','HGF_omega2'});

posteriorTbl.mouseID = optionsFile.Task.MouseID;

posteriorTbl.group = logical(groupCodes);

for n = 1:length(optionsFile.Task.MouseID)
    posteriorTbl.RW_alpha(n)   = allMice(n,2).est.p_prc.al;
    posteriorTbl.HGF_omega1(n) = allMice(n,1).est.p_prc.om(2);
    posteriorTbl.HGF_omega2(n) = allMice(n,1).est.p_prc.om(3);
end

%% PLOT
fig = boxplot(posteriorTbl.RW_alpha,posteriorTbl.group);
figDir = fullfile([char(optionsFile.paths.plotsDir),filesep,'RW_alpha_plot']);
save([figDir,'.fig']);
print([figDir,'.png'], '-dpng');
close all;

fig = boxplot(posteriorTbl.HGF_omega1,posteriorTbl.group);
figDir = fullfile([char(optionsFile.paths.plotsDir),filesep,'HGF_omega1_plot']);
save([figDir,'.fig']);
print([figDir,'.png'], '-dpng');
close all;

fig = boxplot(posteriorTbl.HGF_omega2,posteriorTbl.group);
figDir = fullfile([char(optionsFile.paths.plotsDir),filesep,'HGF_omega2_plot']);
save([figDir,'.fig']);
print([figDir,'.png'], '-dpng');
close all;

%% STATS
% for example...
anova(groupCodes,posteriorTbl.RW_alpha);
anova(groupCodes,posteriorTbl.HGF_omega1);
anova(groupCodes,posteriorTbl.HGF_omega2);

end