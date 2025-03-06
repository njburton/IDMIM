function checkPoint = verifyExperimentSequence(data)

% Initialise checkpoint vector to false
checkPoint = false;
% Initialise counter for matching conditions
validMatches = true;

% Loop through each element in the Outcome sequence
for iCell = 1:length(data.Outcome)
    % If we find a 1 in Outcome
    if data.Outcome(iCell) == 1
        % Check if Choice and RewardingSideLever match
        % Either both should be 0 or both should be 1
        if ~((data.Choice(iCell) == 0 && data.RewardingLeverSide(iCell) == 0) || ...
                (data.Choice(iCell) == 1 && data.RewardingLeverSide(iCell) == 1))
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