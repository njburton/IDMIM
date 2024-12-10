function rmasv
load('optionsFile.mat');
asvFiles = dir(fullfile(optionsFile.paths.projDir, '**', '*.asv'));
if ~isempty(asvFiles)
    cellfun(@(f,d) delete(fullfile(d,f)), {asvFiles.name}, {asvFiles.folder});
    fprintf('Removed %d .asv files from project directory\n', length(asvFiles));
else
    disp('No .asv files found in project directory');
end
end

% call function by typing 'rmasv' into command window