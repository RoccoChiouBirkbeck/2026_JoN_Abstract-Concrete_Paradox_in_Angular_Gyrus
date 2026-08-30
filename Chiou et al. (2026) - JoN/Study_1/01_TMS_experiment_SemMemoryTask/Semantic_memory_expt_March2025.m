function Semantic_memory_expt_March2025

ExpFolder = uigetdir; % use 'uigetdir' so that you can indicate the path to get to the designated folder

try
    rand('twister',sum(100*clock)); %#ok<RAND> % seed random number generator 
    
    AssertOpenGL;
    KbName('UnifyKeyNames'); experiment = 'TMS_experiment'; Participant = 0; SessionType = 0;
    %% Dialog box
    answer = inputdlg({'Participant #:','Session type (0 = practice; 1 = Vertex; 2 = AG):'},...
        'Enter the following information', 1,{num2str(Participant), num2str(SessionType)}); 
    % '1' means that each question can recieve one row of input
    [ParticipantString, SessionTypeString] = deal(answer{:});
    Participant = str2double(ParticipantString); %
    SessionType = str2double(SessionTypeString); %  
     
    
    % set up if it's practice or real experiment
    switch SessionType            % SessionType is defined in Dialog Box
        case 0                    % if you enter '0'
            Prac_Ver_AG = 1;      % this will be a practice session
        case 1                    % if you enter '1'
            Prac_Ver_AG = 2;      % this will be a Vertex session
        case 2                    % if you enter '2'
            Prac_Ver_AG = 3;      % this will be an AG session    
        otherwise
            error('Task type %d is invalid', TaskType);
    end
    
    % output file name
    if Prac_Ver_AG == 2
        dataFileName = sprintf('%s_%03d_Vertex.txt', experiment, Participant);
    elseif Prac_Ver_AG ==3
        dataFileName = sprintf('%s_%03d_AG.txt', experiment, Participant);
    end
    
    %% colour settings; FeedBack colours will be white for the real experiment
    colBackground = [255 255 255]; colFixation = [0 0 0]; colWords = [128 128 128];
    if Prac_Ver_AG == 1
        colFeedbackCorrect = [0 150 0]; % correct feedback - GREEN
        colFeedbackError =   [150 0 0]; % erroneous feedback - RED
    else
        colFeedbackCorrect = colBackground; %
        colFeedbackError =   colBackground; %
    end
    
    %% Open main window, double-buffered fullscreen window
    Screen('Preference', 'SkipSyncTests', 1);        % skip sync test
    Screen('Preference', 'VisualDebugLevel', 0);     % no debugging
    Screen('Preference','SuppressAllWarnings', 1);   % no warming
    
    % Use 'OpenWindow' to create a white main screen 
    screenNumber=max(Screen('Screens'));             
    [w,rect] = Screen('OpenWindow',screenNumber,colBackground);    
    refreshDuration = Screen('GetFlipInterval', w);  % get the refresh rate of your computer
    durSlack = refreshDuration / 2.0;
    
    % use 'ListenChar(2)' can prevent keypresses from entering Matlab command window
    HideCursor; ListenChar(2);
    % 'BlendFunction' can combine old/new colour values onto the same pixel
    Screen(w, 'BlendFunction', GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    % return the x,y coordinates of the centre of screen (rect)
    fullscreen = [0,0,rect(3),rect(4)];
    [centerX, centerY] = RectCenter(rect);           
    

    %% load words
    if Participant <=9 Participant_folder = strcat('Subj_0',num2str(Participant)); 
    elseif Participant >9 Participant_folder = strcat('Subj_',num2str(Participant)); end

    if (Prac_Ver_AG == 1)  || (Prac_Ver_AG == 2) % practice trials always come from the Vertex set!
        load(fullfile(ExpFolder,Participant_folder,'Vertex_Conc_words.mat')); % this can create 150 trials
        load(fullfile(ExpFolder,Participant_folder,'Vertex_Abst_words.mat')); % this can create another 150 trials
    elseif (Prac_Ver_AG == 3)
        load(fullfile(ExpFolder,Participant_folder,'AG_Conc_words.mat')); % this can create 150 trials
        load(fullfile(ExpFolder,Participant_folder,'AG_Abst_words.mat')); % this can create another 150 trials
    end

    %% create a list of 300 trials
    StimuliArray = cell(300, 3);
    if (Prac_Ver_AG == 1)  || (Prac_Ver_AG == 2)
        % concrete words
        for i=1:75   StimuliArray{i,1} = Vertex_Conc_words.reference{i}; end
        for i=76:150 StimuliArray{i,1} = Vertex_Conc_words.reference{i-75}; end
        for i=1:75   StimuliArray{i,2} = Vertex_Conc_words.related{i}; end
        for i=76:150 StimuliArray{i,2} = Vertex_Conc_words.unrelated{i-75}; end
        % abstract words
        for i=151:225  StimuliArray{i,1} = Vertex_Abst_words.reference{i-150}; end
        for i=226:300  StimuliArray{i,1} = Vertex_Abst_words.reference{i-225}; end
        for i=151:225  StimuliArray{i,2} = Vertex_Abst_words.related{i-150}; end
        for i=226:300  StimuliArray{i,2} = Vertex_Abst_words.unrelated{i-225}; end
    elseif Prac_Ver_AG == 3
        % concrete words
        for i=1:75   StimuliArray{i,1} = AG_Conc_words.reference{i}; end
        for i=76:150 StimuliArray{i,1} = AG_Conc_words.reference{i-75}; end
        for i=1:75   StimuliArray{i,2} = AG_Conc_words.related{i}; end
        for i=76:150 StimuliArray{i,2} = AG_Conc_words.unrelated{i-75}; end
        % abstract words
        for i=151:225  StimuliArray{i,1} = AG_Abst_words.reference{i-150}; end
        for i=226:300  StimuliArray{i,1} = AG_Abst_words.reference{i-225}; end
        for i=151:225  StimuliArray{i,2} = AG_Abst_words.related{i-150}; end
        for i=226:300  StimuliArray{i,2} = AG_Abst_words.unrelated{i-225}; end
    end

    %% Load speech files based on Condition_index
    % concrete words - match
    for i = 51:75
       clipName = StimuliArray{i,1}; clipName = strcat(clipName,'.wav');
       [y,Fs] = audioread(fullfile(ExpFolder,'SpeechClips',clipName));
       StimuliArray{i,3} = y;
    end
    % concrete words - mismatch
    for i = 126:150
       clipName = StimuliArray{i,1}; clipName = strcat(clipName,'.wav');
       [y,Fs] = audioread(fullfile(ExpFolder,'SpeechClips',clipName));
       StimuliArray{i,3} = y;
    end
    % abstract words - match
    for i = 201:225
       clipName = StimuliArray{i,1}; clipName = strcat(clipName,'.wav');
       [y,Fs] = audioread(fullfile(ExpFolder,'SpeechClips',clipName));
       StimuliArray{i,3} = y;
    end
    % abstract words - mismatch
    for i = 276:300
       clipName = StimuliArray{i,1}; clipName = strcat(clipName,'.wav');
       [y,Fs] = audioread(fullfile(ExpFolder,'SpeechClips',clipName));
       StimuliArray{i,3} = y;
    end    

    %% number of blocks
    if Prac_Ver_AG == 1
        numBlocks = 1; numTrials = 20;        
    else
        numBlocks = 1; numTrials = 300;
    end
   
    %% Durations
    timeFixation = 1.0;
    timeStimulus_1 = 0.5;
    time3SecsBlank = 3.0;
    timeStimulus_2 = 4.0;
    timeITI = 1.0; 
    
    %% load the instruction file
    if rem(Participant,2) ~= 0
        inst = imread(fullfile(ExpFolder,'Instruction_odd.jpg'));
    else
        inst = imread(fullfile(ExpFolder,'Instruction_even.jpg'));
    end
    inst = Screen('MakeTexture',w,inst);

    %% text setup
    Screen('TextFont', w, 'Arial');
    Screen('TextSize', w, 60);
    Screen('TextStyle', w, 0);
        
    %% defining the coords of central fixation point 
    x0 = centerX;                   % x0 is the middle of x-axis
    y0 = centerY;                   % y0 is the middle of y-axis
    fixation_size = [x0-5,y0-5,x0+5,y0+5]; image_size = [0,0,779,518]; 
    onscreen_size = CenterRectOnPoint(image_size,x0,y0);

    %% Response key set-up
    respButton(1) = KbName('1'); 
    if IsOSX
        respButton(2) = KbName('2');
    elseif IsWin
        respButton(2) = KbName('2'); 
    else
        error('no keyboard mapping for this operating system');
    end
    respAbort = KbName('ESCAPE');   % press ESC to leave
    allowedResponses = [respButton(1) respButton(2)];

    %% present the instruction image
    Screen('FillRect',w,colBackground,fullscreen); 
    Screen('DrawTexture',w,inst);Screen('Flip',w);
    while KbCheck, WaitSecs(0.001); end
    KbWait;    
    [keyDown, keyTime, keyCode] = KbCheck;
    if keyCode(respAbort)
        error('abort key pressed');
    end
    while KbCheck, WaitSecs(0.001); end
    Screen('FillRect',w,colBackground,fullscreen);
    Screen('Flip',w);
    WaitSecs(0.5);

    %% Texts shown before experimental trials
    Screen('FillRect',w,colBackground,fullscreen);
    if Prac_Ver_AG == 1
        DrawFormattedText(w, 'Press any button to start the practice', 'center', 'center', colFixation);
    else
        DrawFormattedText(w, 'Press any button to start the experiment', 'center', 'center', colFixation);
    end
    Screen('Flip',w);
    while KbCheck, WaitSecs(0.001); end
    KbWait;
    [keyDown, keyTime, keyCode] = KbCheck; %#ok<*ASGLU>
    if keyCode(respAbort)
        error('abort key pressed');
    end
    while KbCheck, WaitSecs(0.001); end
    Screen('FillRect',w,colBackground,fullscreen);
    Screen('Flip',w);
    WaitSecs(0.5);

    %% Each session contains 300 trials
    Condition_index = randperm(300);

    % Get some stuff ready before the task
    MaxPriority(w, 'KbCheck', 'GetSecs');    

    %% the start of the block loop
    for block = 1:numBlocks   

        % the start of the trial loop
        for trial = 1:numTrials  
            
            % record the time of each trial
            time = clock; time = time(4:6); 
            time = sprintf('%d__%d__%.0f', time(1),time(2),time(3));
            
            while KbCheck
                WaitSecs(0.001); % make sure no key is being pressed
            end

            % specify the condition of the current trial
            Trial_index = Condition_index(trial);

            % get the condition label of the current trials
            if Trial_index >=1 && Trial_index <= 25
                Condition = 1;   Condi_label = '01_SimVis_Conc_Match';    
                
            elseif Trial_index >=26 && Trial_index <= 50
                Condition = 2;   Condi_label = '02_SeqVisVis_Conc_Match'; 
               
            elseif Trial_index >=51 && Trial_index <= 75
                Condition = 3;   Condi_label = '03_SeqSpchVis_Conc_Match';   

            elseif Trial_index >=76 && Trial_index <= 100
                Condition = 4;   Condi_label = '04_SimVis_Conc_Mismatch'; 

            elseif Trial_index >=101 && Trial_index <= 125
                Condition = 5;   Condi_label = '05_SeqVisVis_Conc_Mismatch';    

            elseif Trial_index >=126 && Trial_index <= 150
                Condition = 6;   Condi_label = '06_SeqSpchVis_Conc_Mismatch';

            elseif Trial_index >=151 && Trial_index <= 175
                Condition = 7;   Condi_label = '07_SimVis_Abst_Match';    

            elseif Trial_index >=176 && Trial_index <= 200
                Condition = 8;   Condi_label = '08_SeqVisVis_Abst_Match'; 

            elseif Trial_index >=201 && Trial_index <= 225
                Condition = 9;   Condi_label = '09_SeqSpchVis_Abst_Match';    

            elseif Trial_index >=226 && Trial_index <= 250
                Condition = 10;  Condi_label = '10_SimVis_Abst_Mismatch'; 

            elseif Trial_index >=251 && Trial_index <= 275
                Condition = 11;  Condi_label = '11_SeqVisVis_Abst_Mismatch';  

            elseif Trial_index >=276 && Trial_index <= 300
                Condition = 12;  Condi_label = '12_SeqSpchVis_Abst_Mismatch'; 
            end

            % define the three types of situations
            if (Condition == 1) || (Condition == 4) || (Condition == 7) || (Condition == 10)      % simultaneous
                Condi_type = 'SimVis';
            elseif (Condition == 2) || (Condition == 5) || (Condition == 8) || (Condition == 11)  % sequential words
                Condi_type = 'SeqVisVis';
            elseif (Condition == 3) || (Condition == 6) || (Condition == 9) || (Condition == 12)  % speech then word
                Condi_type = 'SeqSpchVis';
            end

            % define correct response
            if rem(Participant,2) ~= 0                                                  % if participant number is odd
                if (Condition == 1) || (Condition == 2) || (Condition == 3) || ...
                        (Condition == 7 ) || (Condition == 8) || (Condition == 9)       % if the words are related
                    correctResp = respButton(1);                                        % press 1 for related trials
                elseif (Condition == 4) || (Condition == 5) || (Condition == 6) || ...
                        (Condition == 10) || (Condition == 11) || (Condition == 12)     % if the words are unrelated
                    correctResp = respButton(2);                                        % press 2 for unrelated trials
                end
            else                                                                        % if participant number is even
                if (Condition == 1) || (Condition == 2) || (Condition == 3) || ...
                        (Condition == 7 ) || (Condition == 8) || (Condition == 9)       % if the words are related
                    correctResp = respButton(2);                                        % press 2 for related trials
                elseif (Condition == 4) || (Condition == 5) || (Condition == 6) || ...
                        (Condition == 10) || (Condition == 11) || (Condition == 12)     % if the words are unrelated
                    correctResp = respButton(1);                                        % press 1 for unrelated trials
                end
            end
            
            % reset the responseCode & responseName
            responseName = 'none'; responseCode = [];

            %% the 1st event: Fixation at the centre
            Screen('FillRect',w,colBackground,fullscreen);
            Screen('FillOval',w,colFixation,fixation_size);
            
            tLastOnset = Screen('Flip', w);            
            tFixationStart = tLastOnset;                        
            tNextOnset = tFixationStart + timeFixation - durSlack;


            %% the 2nd event: the 1st stimulus

            Screen('FillRect',w,colBackground,fullscreen);
            if strcmp(Condi_type,'SimVis')                                  % simultaneous
                % target font = 92 point
                Screen('TextSize', w, 95);
                % make it bold to highlight
                Screen('TextStyle', w, 1);
                % prepare the text to present                
                TwoWords = sprintf('%s\n\n%s', StimuliArray{Trial_index,1}, StimuliArray{Trial_index,2});
                DrawFormattedText(w, TwoWords, 'center', 'center', colFixation);

            elseif strcmp(Condi_type,'SeqVisVis')                           % sequential words   
                % prime font = 80 point
                Screen('TextSize', w, 85);
                % make the font italic
                Screen('TextStyle', w, 2);
                DrawFormattedText(w, StimuliArray{Trial_index,1} , 'center', 'center', colFixation);

            elseif strcmp(Condi_type,'SeqSpchVis')                          % speech then word
                sound(StimuliArray{Trial_index,3},Fs);
            end
                      
            tLastOnset = Screen('Flip', w, tNextOnset); 
            
            if strcmp(Condi_type,'SimVis')
                tTargetOnset = tLastOnset;
            else
                tPrimeOnset = tLastOnset;
            end

            if strcmp(Condi_type,'SimVis')          
                tNextOnset = tTargetOnset + timeStimulus_2 - durSlack;             % 4-s target duration in max
            else
                tNextOnset = tPrimeOnset + timeStimulus_1 - durSlack;              % 0.5-s prime duration always
            end

            if strcmp(Condi_type,'SimVis')                                         % record key response
                [keyDown, keyTime, keyCode] = KbCheck;                             % provided it's SimVis
                while ~keyDown && GetSecs <= tNextOnset
                    [keyDown, keyTime, keyCode] = KbCheck;                         % perform KbCheck
                    if (keyDown)                                                   % if a key is pressed
                        rt = 1000*(keyTime - tTargetOnset);                        % calculate RT in msec

                        responseCode = find(keyCode);                              % obtain its keyCode
                        responseName = KbName(keyCode);                            % and its keyName
                    end
                    if responseCode == respAbort                                   % if ESCAPE is pressed
                        error('abort key pressed');                                % abort the experiment
                    end
                end
            end

            %% the 3rd event: the 2nd stimulus

            if ~strcmp(Condi_type,'SimVis')

                % there's a 3-seconds interval between prime and target
                % in the SeqVisVis condition and the SeqSpchVis condition
                Screen('FillRect',w,colBackground,fullscreen);
                tLastOnset = Screen('Flip', w, tNextOnset);
                tNextOnset = tPrimeOnset + time3SecsBlank - durSlack;

                % prepare the contents & format the text
                Screen('FillRect',w,colBackground,fullscreen);
                Screen('TextSize', w, 95);
                Screen('TextStyle', w, 1); 
                DrawFormattedText(w, StimuliArray{Trial_index,2} , 'center', 'center', colFixation);

                % flip the text
                tLastOnset = Screen('Flip', w, tNextOnset);
                tTargetOnset = tLastOnset;
                tNextOnset = tTargetOnset + timeStimulus_2 - durSlack;
               
                [keyDown, keyTime, keyCode] = KbCheck;
                while ~keyDown && GetSecs <= tNextOnset
                    [keyDown, keyTime, keyCode] = KbCheck;                         % perform KbCheck
                    if (keyDown)                                                   % if a key is pressed
                        rt = 1000*(keyTime - tTargetOnset);                        % calculate RT in msec

                        responseCode = find(keyCode);                              % obtain its keyCode
                        responseName = KbName(keyCode);                            % and its keyName
                    end
                    if responseCode == respAbort                                   % if ESCAPE is pressed
                        error('abort key pressed');                                % abort the experiment
                    end
                end              
                
            end
            
            
            %% Define different types of response          
            if isempty(responseCode)
                % no response is made
                respString = 'no_response';
                responseName = 'no_resp';
                accuracy = -1;
                rt = NaN;
            else
                if numel(responseCode) > 1
                    % multiple buttons pressed
                    respString = 'multiple_resp';
                    responseName = 'multiple_resp';
                    accuracy = -2;
                elseif responseCode == correctResp            % if responseCode is the correct key defined in correctResp
                    respString = sprintf('%d', responseCode); % use sprintf to assign data into the variable 'respString'
                    num2str(respString);                      % use num2str 'resString' to convert digit into string
                    accuracy = 1;                             % accuracy is 1 (correct)
                elseif responseCode ~= correctResp && any(allowedResponses == responseCode)
                    respString = sprintf('%d', responseCode); % if it is an allowed key but isn't the correct one
                    num2str(respString);                      % again record the incorrect key that is pressed
                    accuracy = 0;                             % accuracy is 0 (error)
                else
                    % the a non-allowed key is pressed
                    respString = sprintf('%d', responseCode);
                    num2str(respString); responseName = 'not_allowed_key';
                    accuracy = -3;
                end
            end
                        
            %% Prepare the feedback
            Screen('TextSize', w, 60);
            Screen('TextStyle', w, 0);
            colFeedback = colFeedbackError; % default feedback text is red
            if accuracy == -1
                feedback = 'NO RESPONSE - TOO SLOW';
            elseif accuracy == -2
                feedback = 'MULTIPLE KEYS PRESSED';
            elseif accuracy == -3
                feedback = 'NON-ALLOWED KEY PRESSED';
            elseif accuracy == 0
                feedback = sprintf('TRIAL %d - ERROR', trial);
            elseif accuracy == 1                                           
                feedback = sprintf('TRIAL %d - CORRECT', trial);         
                colFeedback = colFeedbackCorrect;                        
            end

            %% start writing data into the output file
            if Prac_Ver_AG ~= 1
                dataFile = fopen(dataFileName, 'r'); % try to open/read the file

                if dataFile == -1     % if that file cannot be read (if it doesn't exist, hence -1), create the header
                    header = ...
                        'TimeStamp,Block,Trial,Condition,Stimulus_1,Stimulus_2,Correct_resp,Actual_resp,Accuracy,RT\n'; % header
                else                  % if that file exists
                    fclose(dataFile); % close the file
                    header = [];      % no need to create a header
                end
                
                dataFile = fopen(dataFileName, 'a'); % create a new file (if it doesn't exist) & append data to the end of the file
                if dataFile == -1                    % if the file cannot be created due to an unknown technical reason
                    error('cannot open data file %s for writing', dataFileName); % return an error message
                end
                
                if ~isempty(header)                  % if the header is created earlier 
                    fprintf(dataFile, header);       % use 'fprintf' to write the header into the text file
                end                                  % this only matters for the first trial; in later trias, header = []

                fprintf(dataFile,'%s,%d,%d,%s,%s,%s,%d,%d,%d,%0.0f\n',... % 
                    time, block, trial, Condi_label, StimuliArray{Trial_index,1}, ...
                    StimuliArray{Trial_index,2}, correctResp, responseCode, accuracy, rt);
                
                % wrapping up (for this trial)
                fclose(dataFile);
            end           
            
            %% present feedback
            Screen('FillRect', w, colBackground,fullscreen);
            DrawFormattedText(w, feedback, 'center', 'center', colFeedback); 
            tLastOnset = Screen('Flip', w);                              
            tFeedbackOnset = tLastOnset;
            tNextOnset = tFeedbackOnset + timeITI - durSlack;

            % clear screen after the 1s feedback duration is up
            Screen('FillRect', w, colBackground, fullscreen);
            Screen('Flip', w, tNextOnset);                               

        end % the end of the trial loop
        
        %% present the inter-block instruction
        Screen('FillRect',w,colBackground,fullscreen); BlockLeft = numBlocks - block; 
        if BlockLeft > 1        
            InterBlock = sprintf('Take a short break!\n\n\n\nThere are %d blocks left.', BlockLeft);
        elseif BlockLeft == 1   
            InterBlock = sprintf('Take a short break!\n\n\n\nThere is %d block left.', BlockLeft);
        elseif BlockLeft < 1   
            InterBlock = sprintf('All done!\n\n\n\nThere is %d block left.', BlockLeft);
        end
        
        if Prac_Ver_AG == 1
            DrawFormattedText(w, 'Take a short break!\n\n\n\n\nAre you familiar with the task?',...
                'center', 'center', colFixation);           
        elseif Prac_Ver_AG ~= 1            
            DrawFormattedText(w, InterBlock, 'center', 'center', colFixation);
        end
        
        Screen('Flip',w);
        while KbCheck, WaitSecs(0.001); end
        KbWait;
        while KbCheck, WaitSecs(0.001); end
        Screen('FillRect',w,colBackground,fullscreen);
        Screen('Flip',w);
        WaitSecs(1.0);
    end % the end of the block loop

    %% show the final words when the practise/experiment is done
    Screen('FillRect',w,colBackground,fullscreen);
    if Prac_Ver_AG == 1
        DrawFormattedText(w, 'The practice is over\n\n\n\nReady to continue?', 'center', 'center', colFixation);
    else
        DrawFormattedText(w, 'Hooray! Please call the experimenter.', 'center', 'center', colFixation);
    end
    Screen('Flip',w);
    while KbCheck, WaitSecs(0.001); end
    KbWait;
    while KbCheck, WaitSecs(0.001); end
    Screen('FillRect',w,colBackground,fullscreen);
    Screen('Flip',w); WaitSecs(1);    
    Screen('Close',w);
    
    %% finally, move data file(s) to a designated folder
    %  create Result folder if it doesn't exist
    if Prac_Ver_AG ~= 1
        if ~exist(fullfile(pwd,'Results'),'dir')
            mkdir('Results');
        end
        result = dir(fullfile('*.txt'));
        movefile('*.txt','Results','f');
    end
    
catch %#ok<CTCH>
    ple;
    Screen('Close',w);
    Priority(0);
    ListenChar(1);
    ShowCursor;
end % the end of the try catch loop

Priority(0);
ListenChar(1);
ShowCursor;

Screen('CloseAll');