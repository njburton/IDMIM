function plotMouseBehaviour

% read data in - task tables
try
    load('optionsFile.mat');
catch
    optionsFile = runOptions; % specifications for this analysis
end

OmittedTrialsCounter =zeros(180,1);

for n = 1:optionsFile.Task.nSize

    currMouse = optionsFile.Task.MouseID(n);
    load([char(optionsFile.paths.resultsDir),'\mouse',num2str(currMouse)])
    load(fullfile([char(optionsFile.paths.resultsDir),'\mouse',num2str(currMouse),'HGFFitABA1.mat']));


    %Create vector to calculate statistics with each row as a mouse

    


    %% Create task performance graph tiles
    %Ommissions, responseTimes,
    mousePerformanceTile = tiledlayout(3,2);
    title(mousePerformanceTile, 'Mouse task performance graph','FontSize',20);

    %Tile1 - Response of currMouse
    ax1 = nexttile([1 1]);
    h = histogram(eHGFFit.y)
    ylim([-0.1, 200]);
    title('Lever responses');
    xlabel('LeftLever, RightLever');
    ylabel('# of lever presses');
    xticks([0 1])
    yticks([0 50 100 150 200])
   
    %Inlude # of responses above histogram in future
%     % Compute center of bins
%     binCnt = h.BinEdges(2:end) - h.BinWidth/2;
%     % Get bar heights
%     barHeights = h.Values;
%     % plot count at top of bins
%     hold on
%     plot(binCnt, barHeights, '')
    
    %Tile2 - Omissions
    ax2 = nexttile([1 1]);
    Omits = length(eHGFFit.irr);
    Y = Omits;
    p = bar(Omits,Y,0.5);
    ylim([-0.1, sum(Omits + 3)]);
    title('Omission Count');
    xlabel('Trial');
    ylabel('# of omissions');
    

    %Tile3 - omissions over task timeline
    ax3 = nexttile([1 2]);
    trials = 1:180;
    responseList = eHGFFit.y;
    OmitMatrix = zeros(180,1);
    for k = eHGFFit.irr
        OmitMatrix((k),1) = 1;
    end

    omissionTrials = zeros(1,180)
    omissionTrials(eHGFFit.irr) = 1
    bar(trials,omissionTrials,0.5, "red")
    xlabel('Trials');
    ylabel('');
    title('Omissions over time');
    xlabel('Trial');
    ylabel('');

    %Add omitted trials to OmittedTrialCounter
    OmittedTrialsCounter = (OmittedTrialsCounter + OmitMatrix)
    

    %Tile 4 - responseTimes over Trial stemplot   %Reduce size of ball
    %point top on stem plot 15/8/24 NB
    ax4 = nexttile([1 2]);
    responseTimes = ExperimentTaskTable.ResponseTime;
    responseTimes(responseTimes(:,1) < 0.0) = 0.0; %Change any negative values to 0.0
    s = stem(responseTimes,'filled');
    title('ResponseTime (TrialStartTime - LeverPressTime)');
    xlabel('Trial');
    ylabel('Time (sec)');

    %Save tiledPlot
    figdir = fullfile([char(optionsFile.paths.plotsDir),'\mouse',num2str(currMouse),'_MouseBehaviourPlot']);
    save([figdir,'.fig'])
    print([figdir,'.png'], '-dpng')

end

close all;

%Plot omissions over trials for all mice
fig = bar(OmittedTrialsCounter)
title('Omission distribution over task');
xlabel('Trial');
ylabel('Number of omissions');

%Save tiledPlot
figdir = fullfile([char(optionsFile.paths.plotsDir),'OverallOmissionDistributionPlot']);
save([figdir,'.fig'])
print([figdir,'.png'], '-dpng')


% %% Compute CoarseChoiceStrategies
% % lose-switch, lose-stay, win-switch, win-stay stickiness
% % explore/exploit
% % and plot on graph
% mouseCoarseChoiceStratTile = tiledlayout(2,4,'TileSpacing','Compact');
% %Tile 1 - lose-switch, lose-stay, win-switch, win-stay
% %Omits)
% nexttile([1,2])
% histogram(ChoiceColumn.Choices);
%
% %Tile 1 -
% %Omits)
% nexttile([1,2])
% histogram(ChoiceColumn.Choices);
%
% %Tile 3 -
% %Omits)
% nexttile(6,[1,2])
% histogram(ChoiceColumn.Choices);
%
% %%Win-stay
% % Initialize counters
% count_stay_win = 0; % Counter for P(stay | win)
%
% end
