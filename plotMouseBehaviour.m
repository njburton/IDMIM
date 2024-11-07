function plotMouseBehaviour

load('optionsFile.mat');


omittedTrialsCounter =zeros(optionsFile.paths.nTrials,1);

for n = 1:optionsFile.cohort.nSize
    currMouse = optionsFile.task.MouseID(n);
    load(fullfile([char(optionsFile.paths.resultsDir),'\mouse',num2str(currMouse),'eHGFFit.mat']));

    % Create task performance graph tiles
    %Ommissions, responseTimes,
    mousePerformanceTile = tiledlayout(3,2);
    title(mousePerformanceTile, char(['Mousetask', num2str(currMouse),'performance graph']),'FontSize',20);

    %Tile1 - Response of currMouse
    ax1 = nexttile([1 1]);
    h = histogram(eHGFFit.y);
    ylim([-0.1, 200]);
    title('Lever responses');
    xlabel('LeftLever, RightLever');
    ylabel('# of lever presses');
    xticks([0 1])
    yticks([0 50 100 150 200])

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
    omissionTrials = zeros(1,optionsFile.paths.nTrials);
    omissionTrials(eHGFFit.irr) = 1;

    omissionTrialsAvg = zeros(1,optionsFile.paths.nTrials);
    omissionTrialAvg = ((sum(eHGFFit.irr)) / length(eHGFFit.irr));
    omissionTrialsAvg(round(omissionTrialAvg)) = 1;

    bar(trials,omissionTrials,0.5, "red")
    hold on;
    bar(trials,omissionTrialsAvg,0.7,"green")
    xlabel('Trials');
    ylabel('');
    title('Omissions over time - GreenBar is Avg omission');

    %Tile 4 - responseTimes >5sec over Trial stemplot   
    ax4 = nexttile([1 2]);
    responseTimes = ExperimentTaskTable.ResponseTime;
    responseTimes(responseTimes(:,1) < 5.0) = 0.0; %Change any negative values to 0.0
    s = stem(responseTimes,'filled',MarkerSize=6,Marker='.');
    title('ResponseTimes (TrialStartTime - LeverPressTime) longer than 5secs ');
    xlabel('Trial');
    ylabel('Time (sec)');

    %Save tiledPlot
    figdir = fullfile([char(optionsFile.paths.plotsDir),'\mouse',num2str(currMouse),'_MouseBehaviourPlot']);
    save([figdir,'.fig'])
    print([figdir,'.png'], '-dpng')

    %Create empy vector with same amount of trials
    omitMatrix = zeros(optionsFile.paths.nTrials,1); %fill with zeros
    %Add each omission trial to OmitMatrix to plot later
    for k = eHGFFit.irr %For each omitted trial
        omitMatrix((k),1) = 1; %Add a 1 to the corresponding row/trial in OmitMatrix
    end

    %Add OmitMatrix to Counter if currMouse passes our criteria of <20% ommissions
    if length(eHGFFit.irr) >= 36   %Ommissions criteria is 20% of total trials, 180, which is 36
        disp("Detected mouse with too many omissions and broken omission criteria of 20%");
    else
        %Add omitted trials to OmittedTrialCounter
        omittedTrialsCounter = (omittedTrialsCounter + omitMatrix);
    end

end

close all;

%Plot omissions over trials for all mice
fig = bar(omittedTrialsCounter);
title('Omission distribution over task. Outliers have been removed from this plot');
xlabel('Trial');
ylabel('Number of omissions');

%Save tiledPlot
figdir = fullfile([char(optionsFile.paths.plotsDir),'OverallOmissionDistributionPlot']);
save([figdir,'.fig'])
print([figdir,'.png'], '-dpng')
