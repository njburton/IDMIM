function checkPoint = verifyExperimentSequence(getData)

% Initialise checkpoint vector to false
checkPoint = false;
% Initialise counter for matching conditions
validMatches = true;

% Loop through each element in the Outcome sequence
for celli = 1:length(getData.Outcome)
    % If we find a 1 in Outcome
    if getData.Outcome(celli) == 1
        % Check if Choice and RewardingSideLever match
        % Either both should be 0 or both should be 1
        if ~((getData.Choice(celli) == 0 && getData.RewardingLeverSide(celli) == 0) || ...
                (getData.Choice(celli) == 1 && getData.RewardingLeverSide(celli) == 1))
            validMatches = false;
            break;
        end
    end
end

% If all conditions were met, set checkpoint to true
if validMatches
    checkPoint = true; 
end
end