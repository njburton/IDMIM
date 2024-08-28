% Open the file in read mode
fileID = fopen('2023-11-29_12h16m_Subject 372.txt', 'r');

% Check if the file opened successfully
if fileID == -1
    error('File could not be opened');
end

% Initialize variables
lastLineNumber = -1; % To store the line number of the last 'H'
currentLineNumber = 0; % To keep track of the current line number

% Read the file line by line
while ~feof(fileID)
    % Read the current line
    currentLine = fgetl(fileID);
    % Increment the line number
    currentLineNumber = currentLineNumber + 1;
    % Check if the line contains the letter 'H'
    if contains(currentLine, 'H')
        % Update the last line number where 'H' was found
        lastLineNumber = currentLineNumber;
    end
end

% Close the file
fclose(fileID);

% Display the result
if lastLineNumber == -1
    disp('The letter ''H'' was not found in the file.');
else
    fprintf('The last occurrence of the letter ''H'' is in line number: %d\n', lastLineNumber);
end