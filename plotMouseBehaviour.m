function plotMouseBehaviour

% read data in - task tables

optionsFile = runOptions;

for n = 1:optionsFile.Task.nSize

    currMouse = optionsFile.Task.MouseID(n);
    load([char(optionsFile.paths.resultsDir),'\mouse',num2str(currMouse)])
    load(fullfile([char(optionsFile.paths.resultsDir),'\mouse',num2str(currMouse),'HGFFitABA1.mat']));
end

%% Create task performance graph tiles
%Ommissions, responseTimes,
mousePerformanceTile = tiledlayout(2,3);
title(mousePerformanceTile, 'Mouse task performance graph','FontSize',20);

%Tile1 - Response of currMouse
ax1 = nexttile;
histogram(eHGFFit.y);
%ylim([0.3 0.8]);
title('Responses');

%Tile2 - Omissions
ax2 = nexttile;
Omits = length(eHGFFit.irr);
Y = Omits;
bar(Omits,Y,0.5);
%ylim([0.3 0.8]);
title('Omissions');

%Tile3 - omissions over task timeline
ax3 = nexttile;
eHGFFit.irr;
%Y =
title('omissions over task timeline');

%Tile 4 - responseTimes over Trial stemplot
ax4 = nexttile([1 3]);
responseTimes = ExperimentTaskTable.ResponseTime;
responseTimes(responseTimes(:,1) < 0.0) = 0.0;
stem(responseTimes,'filled');
%ylim([0.0 15]);
title('ResponseTimes (TrialStartTime - LeverPressTime');

%Save tiledPlot
figdir = fullfile([char(optionsFile.paths.resultsDir),'\mouse',num2str(currMouse),'HGFFitABA1']);
save([figdir,'.fig'])
print([figdir,'.png'], '-dpng')

%% Compute CoarseChoiceStrategies
% lose-switch, lose-stay, win-switch, win-stay stickiness
% explore/exploit
% and plot on graph
mouseCoarseChoiceStratTile = tiledlayout(2,4,'TileSpacing','Compact');
%Tile 1 - lose-switch, lose-stay, win-switch, win-stay
%Omits)
nexttile([1,2])
histogram(ChoiceColumn.Choices);

%Tile 1 -
%Omits)
nexttile([1,2])
histogram(ChoiceColumn.Choices);

%Tile 3 -
%Omits)
nexttile(6,[1,2])
histogram(ChoiceColumn.Choices);

%%Win-stay
% Initialize counters
count_stay_win = 0; % Counter for P(stay | win)

end
