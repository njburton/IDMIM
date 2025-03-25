% %% Step 3: create condensed.mat file for analysis with fitModels function
load("optionsFile.mat")

dirFiles     = dir(fullfile(optionsFile.paths.resultsDir,'*.mat')); %search for all files in ResultsDir
allFilenames = {dirFiles.name}'; % put all file names into vector

mouseList = zeros(length(allFilenames),1);

for fileInDir = 1:length(allFilenames)
    currFile = fullfile(optionsFile.paths.resultsDir,filesep,allFilenames(fileInDir));
    mouseID = char(cell2mat(extractBetween(currFile,'mouse','_NJB_HGF'))); % find numbers between mouse and taskName
    mouseList(fileInDir,1) = str2num(mouseID);
end

currMiceInDir = unique(mouseList); % list of current mice with data files in the resultsDir

%updateMouseDatabase(currMiceInDir);

% create struct-based dataBase to contain all mice data for operant tasks
mouseDB = struct();

for mousei = 1:length(currMiceInDir)
    currMouse = currMiceInDir(mousei);
    %search dir for all files for this mouseID
    mouseFileList = find(contains(allFilenames,currMouse));

    

    mouseDB(mousei).ID = currMouse;
    mouseDB(mousei).strain = 'C57BL6';
    mouseDB(mousei).sex = 
    mouseDB(mousei).age =
    mouseDB(mousei).group =

end   
 
%     %create structs for 5 weeks of data
%     for week = 1:5
%         for day = 1:7 %initialise daily data for each week
%             mouseDB(mousei).week(week).day(day).date %to be filled with actual date
%             mouseDB(mousei).week(week).day(day).sessionNumber = (week - 1) * 7 + day; %to be filled with actual date
%             mouseDB(mousei).week(week).day(day).isWeekend = day == 6 || day == 7; %flag for weekend session
% 
%             %             % Task data
%             %             mouseDB(mousei).week(week).day(day).trials = struct (...
%             %                 'taskName', [], ...
%             %                 'taskDataPath',[],...
%             %                 'chamber',[],...
%             %                 'choice',[],...
%             %                 'outcome',[],...
%             %                 'RewardingLever',[],...
%             %                 'trialStartTime',[],... % in seconds
%             %                 'leverPressTime',[],...
%             %                 'responseTime',[],...
%             %                 'hitRate',[]);
%             %
%             %             % Session summary
%             %             mouseDB(mousei).week(week).day(day).summary = struct(...
%             %                 'totalRewards',0,...
%             %                 'totalTimeouts',0,...
%             %                 'hitRate',0);
%             %         end % end of day loop
%             %
%             %         % weekly summary
%             %         mouseDB(mousei).week(week).summary = struct(...
%             %             'meanTotalRewards', 0, ...
%             %             'meanHitRate', 0, ...
%             %             'meanWeekdayTotalRewards',0, ...
%             %             'meanWeekendTotalRewards',0);
%             %     end % end of week loop
%             % end
%             %
%             %
%             % % create checkpoint to see if the current dataBaseTable version is larger
%             % % in length than the previously saved one, if it is larger (meaning more
%             % % mouse data), overwrite file to expand dataBase
%             %
%             % % save cohortToAnalyse.mat
%             % savePathAndName = [char(optionsFile.paths.resultsDir),filesep,'dataBaseTable.mat'];
%             % save(savePathAndName,'dataBaseTable');
%             %
%             %
%             % % Example function to update session summary
            % function sessionSum = updateSessionSummary(trials, isWeekend)
            %     sessionSum.totalTrials = length(trials);
            %     sessionSum.correctTrials = sum([trials.outcome] == 1);
            %     sessionSum.accuracy = sessionSum.correctTrials / sessionSum.totalTrials * 100;
            %     sessionSum.meanReactionTime = mean([trials.reactionTime]);
            %     sessionSum.totalRewards = sum([trials.outcome] == 1);
            %     % Calculate session duration from first to last trial timestamp
            %     sessionSum.sessionDuration = (trials(end).timeStamp - trials(1).timeStamp) * 24 * 60;  % Convert to minutes
            % end
            %
            % % Example function to update weekly summary
            % function weeklySum = updateWeeklySummary(dailySummaries, isWeekendArray)
            %     weeklySum.averageAccuracy = mean([dailySummaries.accuracy]);
            %     weeklySum.averageTrialsPerDay = mean([dailySummaries.totalTrials]);
            %     weeklySum.totalRewards = sum([dailySummaries.totalRewards]);
            %
            %     % Calculate separate weekend and weekday accuracy
            %     weekendSummaries = dailySummaries(isWeekendArray);
            %     weekdaySummaries = dailySummaries(~isWeekendArray);
            %
            %     weeklySum.averageWeekendAccuracy = mean([weekendSummaries.accuracy]);
            %     weeklySum.averageWeekdayAccuracy = mean([weekdaySummaries.accuracy]);
            %
            %     % Custom learning progress metric (placeholder)
            %     weeklySum.learningProgress = weeklySum.averageAccuracy;
            % end
            
            %updateMouseDatabase(currMiceInDir);