function investigateParameters

optionsFile = runOptions; % specifications for this analysis

load([optionsFile.paths.resultsDir,filesep,'modelInv.mat']);

groupCodes = dummyCodeGroups;

%% CREATE TABLE
dataTbl = table('Size',[length(optionsFile.task.MouseID) 12],...
    'VariableTypes',{'string','logical','double','double','double','double','double','double','double','double','double','double'},...
    'VariableNames',{'mouseID','group','RW_zeta','RW_alpha','HGF_zeta','HGF_omega1','HGF_omega2','sumRLeverPress','avgRLeverPress','omissions','avgResponseTime','avgBeamBreakTime'});

dataTbl.mouseID = optionsFile.task.MouseID; %Load mouseIDs into table
dataTbl.group   = logical(groupCodes); % Load groups based on groupCodes (0=control,1=ucms)

%Load responses into vector
responses = zeros(180,length(optionsFile.task.MouseID));
for n = 1:length(optionsFile.task.MouseID)
    responses(:,n) = allMice(n,1).est.y;
end

% Load responsetime & beamBreak
responseTime  = zeros(180,length(optionsFile.task.MouseID));
beamBreakTime = zeros(180,length(optionsFile.task.MouseID));
for n = 1:length(optionsFile.task.MouseID)
    currMouse     = optionsFile.task.MouseID(n);
    load(fullfile([optionsFile.paths.resultsDir,filesep,'mouse',num2str(currMouse),'.mat']));
    responseTime(:,n)  = ExperimentTaskTable.ResponseTime;
    beamBreakTime(:,n) = ExperimentTaskTable.RecepticalBeamBreak;
    
end

responseTime(responseTime(:,:) < 0.0) = NaN;
beamBreakTime(beamBreakTime(:,:) == 0) = NaN;

dataTbl.sumRLeverPress = nansum(responses,1)';  
dataTbl.avgRLeverPress = nanmean(responses,1)';

for n = 1:length(optionsFile.Task.MouseID)    
    dataTbl.RW_zeta(n)    = allMice(n,2).est.p_obs.ze;
    dataTbl.RW_alpha(n)    = allMice(n,2).est.p_prc.al;
    dataTbl.HGF_zeta(n)    = allMice(n,1).est.p_obs.ze;
    dataTbl.HGF_omega1(n)  = allMice(n,1).est.p_prc.om(2);
    dataTbl.HGF_omega2(n)  = allMice(n,1).est.p_prc.om(3);
    dataTbl.omissions(n)   = length(allMice(n,1).est.irr);
    dataTbl.avgResponseTime(n) = mean(responseTime(:,n),'omitnan');
    dataTbl.avgBeamBreakTime(n) = mean(beamBreakTime(:,n),'omitnan');
end

% [optionsFile,exclIdx] = excludeDataSets(optionsFile,dataTbl.omissions);
% dataTbl(exclIdx,:)    = [];

save([optionsFile.paths.resultsDir,'dataTable.mat'],'dataTbl');

%% PLOT
%Check omissions and if below threshold plot the following!!!!
% for n = 1:length(optionsFile.Task.MouseID) 
%     if dataTbl.omissions(n) < 36


%avgBeamBreakTime
fig = boxplot(dataTbl.avgBeamBreakTime,dataTbl.group,...
    'Labels',{'HealthyControls','UCMS'}, 'Widths',0.3);
xlabel('');
ylabel('Time (sec)');
title('avgBeamBreakTime');
figDir = fullfile([char(optionsFile.paths.plotsDir),filesep,'avgBeamBreakTime']);
save([figDir,'.fig']);
print([figDir,'.png'], '-dpng');
close all;


%avgResponseTime
fig = boxplot(dataTbl.avgResponseTime,dataTbl.group,...
    'Labels',{'HealthyControls','UCMS'}, 'Widths',0.3);
xlabel('');
ylabel('Time (sec)');
title('avgResponseTime');
figDir = fullfile([char(optionsFile.paths.plotsDir),filesep,'avgResponseTime']);
save([figDir,'.fig']);
print([figDir,'.png'], '-dpng');
close all;

%sumRLeverPress
fig = boxplot(dataTbl.sumRLeverPress,dataTbl.group,...
    'Labels',{'HealthyControls','UCMS'}, 'Widths',0.3);
xlabel('');
ylabel('Time (sec)');
title('sumRLeverPress');
figDir = fullfile([char(optionsFile.paths.plotsDir),filesep,'sumRLeverPress']);
save([figDir,'.fig']);
print([figDir,'.png'], '-dpng');
close all;

%avgRLeverPress
fig = boxplot(dataTbl.avgRLeverPress,dataTbl.group,...
    'Labels',{'HealthyControls','UCMS'}, 'Widths',0.3);
xlabel('');
ylabel('Right Lever Presses');
title('avgRLeverPress');
figDir = fullfile([char(optionsFile.paths.plotsDir),filesep,'avgRLeverPress']);
save([figDir,'.fig']);
print([figDir,'.png'], '-dpng');
close all;

%omissions
fig = boxplot(dataTbl.omissions,dataTbl.group,...
    'Labels',{'HealthyControls','UCMS'}, 'Widths',0.3);
xlabel('');
ylabel('');
title('Omissions');
figDir = fullfile([char(optionsFile.paths.plotsDir),filesep,'avgRLeverPress']);
save([figDir,'.fig']);
print([figDir,'.png'], '-dpng');
close all;

%% RW alpha parameter
fig = boxplot(dataTbl.RW_alpha,dataTbl.group,...
    'Colors','b','Labels',{'HealthyControls','UCMS'}, 'Widths',0.3);
xlabel('');
ylabel('alpha');
title('RW alpha parameter posterior');
figDir = fullfile([char(optionsFile.paths.plotsDir),filesep,'RW_alpha_plot']);
save([figDir,'.fig']);
print([figDir,'.png'], '-dpng');
close all;

%% HGF omega1
fig = boxplot(dataTbl.HGF_omega1,dataTbl.group,...
    'Colors','b','Labels',{'HealthyControls','UCMS'}, 'Widths',0.3);
xlabel('');
ylabel('omega1');
title('HGF Omega1 parameter posterior or Belief above rewarding lever side');
figDir = fullfile([char(optionsFile.paths.plotsDir),filesep,'HGF_omega1_plot']);
save([figDir,'.fig']);
print([figDir,'.png'], '-dpng');
close all;

%% HGF omega2
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