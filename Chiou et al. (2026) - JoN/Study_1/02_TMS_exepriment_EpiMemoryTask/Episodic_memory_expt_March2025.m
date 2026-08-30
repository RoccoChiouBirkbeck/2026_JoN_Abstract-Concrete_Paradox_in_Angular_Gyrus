function Episodic_memory_expt_March2025

ExpFolder = uigetdir; % use 'uigetdir' so that you can indicate the path to get to the designated folder

try
    rand('twister',sum(100*clock)); %#ok<RAND> % seed random number generator
    
    AssertOpenGL;
    KbName('UnifyKeyNames'); experiment = 'Episodic_memory'; Participant = 0; SessionType = 0;
    %% Dialog box
    answer = inputdlg({'Participant #:','Session type (0 = practice; 1 = Vertex; 2 = AG):'},...
        'Enter the following information', 1,{num2str(Participant), num2str(SessionType)}); 
    % '1' means that each question can recieve one row of input
    [ParticipantString, SessionTypeString] = deal(answer{:});
    Participant = str2double(ParticipantString); %
    SessionType = str2double(SessionTypeString); %  
     
    
    % set up if it's practice or Vertex or AG session
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
    if Prac_Ver_AG == 1                 % feedback is provided during practice
        colFeedbackCorrect = [0 150 0]; % correct feedback - GREEN
        colFeedbackError =   [150 0 0]; % erroneous feedback - RED
    else
        colFeedbackCorrect = colBackground; % but no feedback during real task
        colFeedbackError =   colBackground; % white text on white background
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

    if (Prac_Ver_AG == 1)  || (Prac_Ver_AG == 2) 
        load(fullfile(ExpFolder,Participant_folder,'Vertex_Conc_words.mat')); 
        load(fullfile(ExpFolder,Participant_folder,'Vertex_Abst_words.mat')); 
        load(fullfile(ExpFolder,Participant_folder,'Vertex_New_words.mat'));
    elseif (Prac_Ver_AG == 3)
        load(fullfile(ExpFolder,Participant_folder,'AG_Conc_words.mat')); 
        load(fullfile(ExpFolder,Participant_folder,'AG_Abst_words.mat')); 
        load(fullfile(ExpFolder,Participant_folder,'AG_New_words.mat'));
    end

    %% create a list of 120 trials
    StimuliArray = cell(120, 2);
    if (Prac_Ver_AG == 1)  || (Prac_Ver_AG == 2)
        % old concrete words
        Temporary_array = Shuffle(Vertex_Conc_words.reference);
        for i=1:30   StimuliArray{i,1} = Temporary_array{i}; StimuliArray{i,2} = 'Old'; end
        % old abstract words
        Temporary_array = Shuffle(Vertex_Abst_words.reference);
        for i=31:60  StimuliArray{i,1} = Temporary_array{i}; StimuliArray{i,2} = 'Old'; end
        % new words
        for i=61:120 StimuliArray{i,1} = Vertex_New_words{i-60}; StimuliArray{i,2} = 'New'; end      
    elseif Prac_Ver_AG == 3
        % old concrete words
        Temporary_array = Shuffle(AG_Conc_words.reference);
        for i=1:30   StimuliArray{i,1} = Temporary_array{i}; StimuliArray{i,2} = 'Old'; end
        % old abstract words
        Temporary_array = Shuffle(AG_Abst_words.reference);
        for i=31:60  StimuliArray{i,1} = Temporary_array{i}; StimuliArray{i,2} = 'Old'; end
        % new words
        for i=61:120 StimuliArray{i,1} = AG_New_words{i-60}; StimuliArray{i,2} = 'New'; end
    end
    StimuliArray = Shuffle(StimuliArray,2); % the randomised list of trials used in task
    
    %% number of blocks
    if Prac_Ver_AG == 1
        numBlocks = 1; numTrials = 5;        
    else
        numBlocks = 1; numTrials = 120;
    end
   
    %% Durations
    timeFixation = 1.000; % 1-second fixation 
    timeStimulus = 600.0; % 10 mins = unlimited
    timeITI = 1.0;        % 1-second inter-trial
    
    %% load the instruction file          
    inst = imread(fullfile(ExpFolder,'Instruction.jpg'));
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
    respButton(1) = KbName('1');      % new
    if IsOSX
        respButton(2) = KbName('2'); 
    elseif IsWin
        respButton(2) = KbName('2');  % old
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

    %% Get some stuff ready before the task
    MaxPriority(w, 'KbCheck', 'GetSecs');    

    %% the start of the block loop
    for block = 1:numBlocks              
        %% the start of the trial loop
        for trial = 1:numTrials  
            
            % record the time of each trial
            time = clock; time = time(4:6); 
            time = sprintf('%d__%d__%.0f', time(1),time(2),time(3));
            
            while KbCheck
                WaitSecs(0.001); % make sure no key is being pressed
            end

            % define the condition and correct response
            if strcmp(StimuliArray{trial,2},'New') == 1              % new word
                Condi_type = '01_New'; correctResp = respButton(1);
            elseif strcmp(StimuliArray{trial,2},'Old') == 1          % old word
                Condi_type = '02_Old'; correctResp = respButton(2);
            end
            
            % reset the responseCode & responseName
            responseName = 'none'; responseCode = [];

            %% the 1st event: Fixation at the centre
            Screen('FillRect',w,colBackground,fullscreen);
            Screen('FillOval',w,colFixation,fixation_size);
            
            tLastOnset = Screen('Flip', w);            
            tFixationStart = tLastOnset;                        
            tNextOnset = tFixationStart + timeFixation - durSlack;


            %% the 2nd event: the word stimulus

            Screen('FillRect',w,colBackground,fullscreen);
                       
            % font = 100 point
            Screen('TextSize', w, 100);
            % make the font italic
            Screen('TextStyle', w, 1);
            DrawFormattedText(w, StimuliArray{trial,1} ,...
                'center', 'center', colFixation);            
                      
            tLastOnset = Screen('Flip', w, tNextOnset); 
            tTargetOnset = tLastOnset;
            tNextOnset = tTargetOnset + timeStimulus - durSlack;
            
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

            %% define four types of response outcomes
            if (responseCode == respButton(1)) && (strcmp(StimuliArray{trial,2},'New') == 1)      % judging 'new' as 'new'
                response_outcome = 'Hit';
            elseif (responseCode == respButton(2)) && (strcmp(StimuliArray{trial,2},'Old') == 1)  % judging 'old' as 'old'
                response_outcome = 'Correct reject';
            elseif (responseCode == respButton(1)) && (strcmp(StimuliArray{trial,2},'Old') == 1)  % judging 'old' as 'new'
                response_outcome = 'False alarm';
            elseif (responseCode == respButton(2)) && (strcmp(StimuliArray{trial,2},'New') == 1)  % judging 'new' as 'old'
                response_outcome = 'Miss';
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
                        'TimeStamp,Block,Trial,Condition,Stimulus,Correct_resp,Actual_resp,Accuracy,Outcome,RT\n'; % header
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

                fprintf(dataFile,'%s,%d,%d,%s,%s,%d,%d,%d,%s,%0.0f\n',... % 
                    time, block, trial, Condi_type, StimuliArray{trial,1}, ...
                    correctResp, responseCode, accuracy, response_outcome, rt);
                
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