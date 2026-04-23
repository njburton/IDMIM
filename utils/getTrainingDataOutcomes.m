function trainingVals = getTrainingDataOutcomes(cohortNo)

% load or run options for running this function
if exist('optionsFile.mat','file')==2
    load('optionsFile.mat');
else
    optionsFile = runOptions();
end


for iMouse  = 1:nSize
    currMouse = optionsFile.cohort(cohortNo).mouseIDs{iMouse};
    load([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',...
                        saveExpName,'.mat']);
   
    trainingVals(iMouse) = nansum(TrainingTaskTable.Choice)/(181*(181/sum(TrainingTaskTable.RewardingLeverSide)));

end


end