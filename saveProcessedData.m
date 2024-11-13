function saveProcessedData(ExperimentTaskTable, optionsFile, mouseID, taskName, taskDate)
% Helper function to verify and save processed data
load("optionsFile.mat");

assert(verifyExperimentSequence(ExperimentTaskTable), ...
    'InputSeqCheckpoint: Detected error between RewardingSideLever binInputSequence and task outcome');

savePath = fullfile(optionsFile.paths.mouseMatFilesDir, ...
    sprintf('mouse%s_%s_date%s.mat', char(mouseID), char(taskName), char(taskDate)));
save(savePath, 'ExperimentTaskTable');
end