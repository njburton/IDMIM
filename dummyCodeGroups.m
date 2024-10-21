function groupCodes = dummyCodeGroups

optionsFile = runOptions; % specifications for this analysis

% initialize groupCodes array
groupCodes = zeros(numel(optionsFile.task.MouseID),1);
temp = string(optionsFile.task.MouseID);
groupIdx = find(strcmp(extractAfter(temp,2),"2"));

groupCodes(groupIdx) = 1;
end