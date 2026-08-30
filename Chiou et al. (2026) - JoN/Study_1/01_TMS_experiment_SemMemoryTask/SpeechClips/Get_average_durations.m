% Set the directory containing your .wav files
filePattern = fullfile(pwd, '*.wav'); % Find all .wav files
fileList = dir(filePattern); % Get a list of all .wav files

% Preallocate duration array
numFiles = length(fileList);
durations = zeros(numFiles, 1);

% Loop through each file and get duration
for k = 1:numFiles
    filename = fullfile(pwd, fileList(k).name);
    info = audioinfo(filename);
    durations(k) = info.Duration; % Duration in seconds
end

% Optional: total or average duration
totalDuration = sum(durations);
averageDuration = mean(durations); stdDuration = std(durations);
fprintf('Average Duration: %.2f seconds\n', averageDuration);
fprintf('Standard deviation: %.2f seconds\n', stdDuration);

%% Average duration: 0.86 seconds; Standard deviation: 0.10 seconds