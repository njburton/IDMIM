function [optionsFile,omissionExclIdx] = excludeDataSets(optionsFile,omissions)

omissionExclIdx = find(omissions>60);
optionsFile.task.MouseID(omissionExclIdx) =[];

end