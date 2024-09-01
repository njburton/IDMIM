function investigateParameters

try
    load('optionsFile.mat');
catch
    optionsFile = runOptions; % specifications for this analysis
end

load([optionsFile.paths.resultsDir,filesep,'modelInv.mat']);

groupCodes = dummyCodeGroups;

%% CREATE TABLE
dataTbl = table('Size',[length(optionsFile.Task.MouseID) 10],...
    'VariableTypes',{'string','logical','double','double','double','double','double','double','double','double'},...
    'VariableNames',{'mouseID','group','RW_zeta','RW_alpha','HGF_zeta','HGF_omega1','HGF_omega2','sumLLeverPress','avgLLeverPress','omissions'});

dataTbl.mouseID = optionsFile.Task.MouseID;
dataTbl.group = logical(groupCodes);

responses = zeros(180,length(optionsFile.Task.MouseID));
for n = 1:length(optionsFile.Task.MouseID)
    responses(:,n) = allMice(n,1).est.y;
end

dataTbl.sumLLeverPress = nansum(responses,1)';
dataTbl.avgLLeverPress = nanmean(responses,1)';

for n = 1:length(optionsFile.Task.MouseID)    
    dataTbl.RW_zeta(n)    = allMice(n,2).est.p_obs.ze;
    dataTbl.RW_alpha(n)    = allMice(n,2).est.p_prc.al;
    dataTbl.HGF_zeta(n)    = allMice(n,1).est.p_obs.ze;
    dataTbl.HGF_omega1(n)  = allMice(n,1).est.p_prc.om(2);
    dataTbl.HGF_omega2(n)  = allMice(n,1).est.p_prc.om(3);
    dataTbl.omissions(n)   = length(allMice(n,1).est.irr);
end
save([optionsFile.paths.resultsDir,'dataTable_widerZeta.mat'],'dataTbl');

%% PLOT
fig = boxplot(dataTbl.RW_alpha,dataTbl.group, ...
    'Colors','b','Labels',{'HealthyControls','UCMS'}, 'Widths',0.3);
xlabel('');
ylabel('alpha');
title('Rescorla Wagner alpha parameter posterior');
figDir = fullfile([char(optionsFile.paths.plotsDir),filesep,'RW_alpha_plot']);
save([figDir,'.fig']);
print([figDir,'.png'], '-dpng');
close all;

fig = boxplot(dataTbl.HGF_omega1,dataTbl.group,...
    'Colors','b','Labels',{'HealthyControls','UCMS'}, 'Widths',0.3);
xlabel('');
ylabel('omega1');
title('HGF Omega1 parameter posterior');
figDir = fullfile([char(optionsFile.paths.plotsDir),filesep,'HGF_omega1_plot']);
save([figDir,'.fig']);
print([figDir,'.png'], '-dpng');
close all;

fig = boxplot(dataTbl.HGF_omega2,dataTbl.group, ...
    'Colors','b','Labels',{'HealthyControls','UCMS'}, 'Widths',0.3);
xlabel('');
ylabel('omega2');
title('HGF Omega2 parameter posterior');
figDir = fullfile([char(optionsFile.paths.plotsDir),filesep,'HGF_omega2_plot']);
save([figDir,'.fig']);
print([figDir,'.png'], '-dpng');
close all;

%% STATS

[H,P,CI,STATS] = ttest(dataTbl.RW_alpha(find(groupCodes)),dataTbl.RW_alpha(find(~groupCodes)))
[H,P,CI,STATS] = ttest(dataTbl.HGF_omega1(find(groupCodes)),dataTbl.HGF_omega1(find(~groupCodes)))
[H,P,CI,STATS] = ttest(dataTbl.HGF_omega2(find(groupCodes)),dataTbl.HGF_omega2(find(~groupCodes)))

end