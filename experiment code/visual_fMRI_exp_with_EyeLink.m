function visual_fMRI_exp_with_EyeLink
%
% Edden Gerber, March 2017
% NOTE 2: This experiment contains a bug: each block stops running at
% the beginning of the last TR and not at its end (i.e. 1.5 sec too early),
% because a block starting at TR 1 and ending at TR N contains only N-1
% TR periods. This can be fixed by adding one self-timed TR period at the
% end of each block.
%
% It's easier to get the big picutre of this code if you enable "code 
% folding" for code sections. 


%% Set Experiment Parameters

% Setup how this experiment is run right now:
debug_mode = false; % Set to true to make the PsychToolBox screen semi-transparent, 
% and will allow seeing and typing on the Matlab window in the background. 
% Type 'clear screen' or 'sca' to close the experiment screen any time. 
scanning_mode = true; % Set to true to indicate that you are running 
% the experiment on the experiment computer (e.g. it's connected to the
% scanner). 

% Screen size parameters
% (This information could in principle be accessed programatically, but it
% is not always reliable. It has to be correct in order for stimuli to be 
% presented with a correct physical size).  
% The alt setup is for testing the experiment on another computer.
monitor_size_exp_setup_cm = [70 39]; % width and height in cm
monitor_size_alt_setup_cm = [50.8 28.7]; % width and height in cm

distance_from_screen_cm = 131; % From the eyes to the screen (through the mirror)

% Language 
exp_language = 1; % 1 for English, 2 for other, e.g. Hebrew in the original example

% File parameters
output_directory = 'Results';
file_name_instructions_eng = 'instructions_eng.txt';
file_name_instructions_heb_f = 'instructions_f.txt'; % In hebrew the instructions text is gendered...
file_name_instructions_heb_m = 'instructions_m.txt';
file_name_trial_codes = 'exp_codes.mat';
file_name_images = 'Stimuli\stimuli.mat';
file_name_hit_icon = 'Stimuli\icon_hit.bmp';
file_name_miss_icon = 'Stimuli\icon_miss.bmp';

% Stimulus parameters 
stimulus_rectangle_length_degrees = 5;

img_alpha = 1; % transparency level

% Scanner parameters
tr_duration_sec = 1.5;

% Task parameters
target_display_time_sec = 0.5;
response_rt_limit_sec = 4;

% Screen color definitions
background_grayscale_value = 0.5;

% Block parameters
wait_time_before_first_stim_sec = 6;
wait_time_after_last_stim_sec = 0;

% Fixation parameters
fix_cross_size = 10;
fix_cross_width = 2;
fix_cross_grayscale_value = 0; % 0 is black, 1 is white

%% Define Constants

% Keyboard codes
KBOARD_CODE_B = KbName('B');
KBOARD_CODE_C = KbName('C');
KBOARD_CODE_D = KbName('D');
KBOARD_CODE_N = KbName('N');
KBOARD_CODE_Y = KbName('Y');
KBOARD_CODE_RESPONSE_KEYS = [KbName('1!') KbName('2@') KbName('3#') KbName('4$') KbName('6^') KbName('7&') KbName('8*') KbName('9(')];
KBOARD_CODE_ESC = KbName('esc');
SCANNER_KEY = KbName('5%');

% Define inline functions
deg2rad = @(d) d/180*pi;
visual_degree_to_cm = @(angle,dist_from_screen) dist_from_screen * tan(deg2rad(angle));
cm_to_visual_degree = @(shift, dist_from_screen) rad2deg(atan(shift / dist_from_screen));

%% Initialize Variables

disp('Initializing Variables...');

% Add folders to path
if scanning_mode 
    % This is not necessary on the ENU experiment computer
%     addpath(genpath('C:\Program Files\PsychToolbox 3\Psychtoolbox'));
%     addpath('C:\Program Files\PsychToolbox 3\Psychtoolbox\PsychBasic\MatlabWindowsFilesR2007a','-begin');
end

% Load trial lists
Load = load(file_name_trial_codes);
block_codes = Load.block_codes;
practice_codes = Load.practice_codes;
clear Load

% Load  text vectors
% The text was saved in an external data structure originally because it
% was in Hebrew. English text can be written directly within the experiment
% code. 
if exp_language == 1
    Load = load('english_text');
else
    Load = load('hebrew_text');
end
TextStr = Load.TextStr;
clear Load

% Initialize experiment runtime variables
stop_exp = false;
stop_block = false;
num_blocks = length(block_codes);
start_block = 1;
curr_block = 1;
curr_trial = 0;
curr_trial_in_block = 0;
curr_tr = 0;
tr_timestamp = [];

% Initialize behavioral variables
block_hits = 0;
block_false_alarms = 0;
block_misses = 0;
block_correct_rejections = 0;
total_hits = 0;
total_false_alarms = 0;
total_misses = 0;
total_correct_rejections = 0;

% Initialize screen variables
if scanning_mode
    monitor_size = monitor_size_exp_setup_cm;
else
    monitor_size = monitor_size_alt_setup_cm;
end

whichScreen=max(Screen('Screens'));
ScrInfo = Screen('resolution',whichScreen);
ScrSize = [ScrInfo.width ScrInfo.height];
screen_center_pix = [ceil(ScrInfo.width/2) ceil(ScrInfo.height/2)];
pixels_per_cm = sqrt(ScrSize(1)^2 + ScrSize(2)^2) / sqrt(monitor_size(1)^2 + monitor_size(2)^2);

stimulus_rectangle_size_pixels = visual_degree_to_cm(stimulus_rectangle_length_degrees, distance_from_screen_cm) * pixels_per_cm;

rectangle_stim_pix = floor([screen_center_pix(1)-stimulus_rectangle_size_pixels/2 ...
                            screen_center_pix(2)-stimulus_rectangle_size_pixels/2 ...
                            screen_center_pix(1)+stimulus_rectangle_size_pixels/2 ...
                            screen_center_pix(2)+stimulus_rectangle_size_pixels/2]);


% Load instructions
% English
file_inst = fopen(file_name_instructions_eng,'r','n');
stop = false;
txt = [];
while ~stop
    line = fgets(file_inst);
    if line==-1
        stop = true;
    else
        txt = [txt corrtxt(line) ' '];
    end
end
txt_instr_eng = txt;
fclose(file_inst);
% Hebrew female
file_inst = fopen(file_name_instructions_heb_f,'r','n','windows-1255');
stop = false;
txt = [];
while ~stop
    line = fgets(file_inst);
    if line==-1
        stop = true;
    else
        txt = [txt corrtxt(line) ' '];
    end
end
txt_instr_heb_f = txt;
fclose(file_inst);
% Hebrew male 
file_inst = fopen(file_name_instructions_heb_m,'r','n','windows-1255');
stop = false;
txt = [];
while ~stop
    line = fgets(file_inst);
    if line==-1
        stop = true;
    else
        txt = [txt corrtxt(line) ' '];
    end
end
txt_instr_heb_m = txt;
fclose(file_inst);


% Initialize output expdata structure
% This data structure holds all of the information collected during the
% experiment - including subject parameters and behavioral data.
expdata.info.subject_number = 0;
expdata.info.subject_sex = 0;
expdata.info.dominant_eye = 1;
expdata.info.session_time = datestr(now);
expdata.info.screen_size = ScrSize;
expdata.info.refresh_rate = ScrInfo.hz;
expdata.info.eye_tracker = 0;
expdata.info.tr = 0;
expdata.info.starting_block = 0;
expdata.block_codes = block_codes;

tmpvec = zeros(2,1); % initialize with size 2 just to force a column vector
tmpcel = cell(2,1);  % initialize with size 2 just to force a column vector
expdata.trials = table(tmpvec,tmpvec,tmpvec,tmpcel,tmpvec,tmpvec,tmpcel,tmpvec,tmpvec,tmpvec,...
    tmpvec,tmpvec,tmpvec,tmpvec,tmpvec,tmpvec,tmpvec,tmpvec,...
    'VariableNames',{'trial_number','block_number','block_trial','time','practice','code',...
    'type','duration','soa','true_duration','true_soa','target_latency','response',...
    'response_rt','hits','misses','false_alarms','correct_rejections'});

%% Load and Generate Stimuli

disp('Generating Stimuli...');

% Load face and house images
Load = load(file_name_images);
stimuli.faces = Load.face_images(:,1);
stimuli.houses = Load.house_images(:,1);
clear Load;

% Load hit/miss icons
icon.hit = imread(file_name_hit_icon);
icon.miss = imread(file_name_miss_icon);
% Add transparency masks
icon.hit(:,:,4) = (1-icon.hit(:,:,2) == 0)*255;
icon.miss(:,:,4) = (1-icon.miss(:,:,2) == 0)*255;

%% Run Launch Window

disp('Running Launch Window...');

fig_back_color = [1 1 1]; 
figSize = [320 540];
screen_size = get(0,'screensize');
figPos = [(screen_size(3) - figSize(1))/2 (screen_size(4) - figSize(2))/2 figSize(1) figSize(2)];
% figPos = [0 0 figSize(1) figSize(2)];
h_fig = figure('Toolbar','none','WindowStyle','normal','Units','pixels','Color',fig_back_color,'NumberTitle','off','Name','Experiment Launch Window', ...
    'Units','pixels','Position',figPos,'WindowStyle','modal','KeyPressFcn',@FigureKeyPress);

% subject number
e1Size = [140 20];
uicontrol('style','text','String','Subject Number','Position',[0 figSize(2)-50 figSize(1) 20],'BackgroundColor',fig_back_color,'fontsize',12);
h_e1 = uicontrol('style','edit','Position',[(figSize(1)-e1Size(1))/2 figSize(2)-80 e1Size(1) e1Size(2)],'fontsize',12,'String','0','KeyPressFcn',@FigureKeyPress);

% session number
uicontrol('style','text','String','Session Number','Position',[0 figSize(2)-120 figSize(1) 20],'BackgroundColor',fig_back_color,'fontsize',12);
h_e2 = uicontrol('style','edit','Position',[(figSize(1)-e1Size(1))/2 figSize(2)-150 e1Size(1) e1Size(2)],'fontsize',12,'String','1','KeyPressFcn',@FigureKeyPress);

% Gender
ddLlistSize = [140 40];
uicontrol('style','text','String','Sex','Position',[0 figSize(2)-190 figSize(1) 20],'BackgroundColor',fig_back_color,'fontsize',12);
h_ddList1 = uicontrol('style','popupmenu','position',[(figSize(1)-ddLlistSize(1))/2 figSize(2)-230 ddLlistSize(1) ddLlistSize(2)],'string',{'Female','Male'},'KeyPressFcn',@FigureKeyPress);

% Dominant eye
ddLlistSize = [140 40];
uicontrol('style','text','String','Dominant Eye','Position',[0 figSize(2)-260 figSize(1) 20],'BackgroundColor',fig_back_color,'fontsize',12);
h_ddList2 = uicontrol('style','popupmenu','position',[(figSize(1)-ddLlistSize(1))/2 figSize(2)-300 ddLlistSize(1) ddLlistSize(2)],'string',{'Right','Left'},'KeyPressFcn',@FigureKeyPress);

% starting block selection list
ddListStr = cell(num_blocks,1);
for ii = 1:num_blocks
    ddListStr{ii} = num2str(ii);
end
uicontrol('style','text','String','Select starting block','Position',[0 figSize(2)-330 figSize(1) 20],'BackgroundColor',fig_back_color,'fontsize',12);
h_ddList3 = uicontrol('style','popupmenu','position',[(figSize(1)-ddLlistSize(1))/2 figSize(2)-370 ddLlistSize(1) ddLlistSize(2)],'string',ddListStr,'KeyPressFcn',@FigureKeyPress);

% practice block 
cbSize = [260 20];
h_cb1 = uicontrol('style','checkbox','Position',[(figSize(1)-cbSize(1))/2 figSize(2)-400 cbSize(1) cbSize(2)],'fontsize',12,'String','Run practice block','KeyPressFcn',@FigureKeyPress,...
    'BackgroundColor',fig_back_color,'value',1);

% eye tracker
h_cb2 = uicontrol('style','checkbox','Position',[(figSize(1)-cbSize(1))/2 figSize(2)-430 cbSize(1) cbSize(2)],'fontsize',12,'String','Eye tracker','KeyPressFcn',@FigureKeyPress,...
    'BackgroundColor',fig_back_color,'value',1);


% response buttons
buttonSize = [130 60];
h_b1 = uicontrol('Style','pushbutton','String','Go!','Position',[20 20 buttonSize(1) buttonSize(2)],'Callback',@ButtonPressGo,'fontsize',13,'SelectionHighlight','on','HorizontalAlignment','center');
uicontrol('Style','pushbutton','String','Cancel','Position',[figSize(1)-buttonSize(1)-20 20 buttonSize(1) buttonSize(2)],'Callback',@ButtonPressCancel,'fontsize',13);

% set focus
uicontrol(h_e1);

waitfor(h_fig);
if stop_exp
    return; 
end

% graphical objects callback functions
    function ButtonPressGo(hObject, eventdata)
        uicontrol(h_b1);
        subject_number = str2double(get(h_e1,'String'));
        session_number = str2double(get(h_e2,'String'));
        subject_sex = get(h_ddList1,'value');
        dominant_eye = get(h_ddList2,'value');
        start_block = get(h_ddList3,'value');
        do_practice = get(h_cb1,'value');
        eye_tracker = get(h_cb2,'value');
        
        % check user input 
        if isnan(subject_number)
            msgbox('Invalid subject number');
            return;
        end
        
        if isnan(session_number)
            msgbox('Invalid session number');
            return;
        end
        
        % check if subject data file exists
        save_file_name = ['fmriDG_s' num2str(subject_number) '_' num2str(session_number) '_expdata.mat'];
        if exist([output_directory filesep save_file_name],'file')
            button = questdlg(['File "' save_file_name '" already exists. Replace?'],'Confirm save file name','OK','Cancel','Cancel');
            switch button
                case 'OK'
                    % keep going
                case 'Cancel'
                    return;
            end
        end
        
        % check if eye tracker EDF file exists
        edf_file_name = ['s' num2str( subject_number) '_' num2str(session_number) '.edf'];
        if exist([output_directory filesep edf_file_name],'file')
            button = questdlg(['EDF file "' edf_file_name '" already exists. Replace?'],'Confirm save file name','OK','Cancel','Cancel');
            switch button
                case 'OK'
                    % keep going
                case 'Cancel'
                    return;
            end
        end
        
        expdata.info.subject_number = subject_number;
        expdata.info.subject_sex = subject_sex;
        expdata.info.dominant_eye = dominant_eye;
        expdata.info.eye_tracker = eye_tracker;
        expdata.info.starting_block = start_block;
        
        disp(['File Name:  ' save_file_name]);
        
        close(h_fig);
    end

    function ButtonPressCancel(hObject, eventdata)
        stop_exp = 1;
        close(h_fig);
    end

    function FigureKeyPress(hObject, eventdata)
        if strcmp(eventdata.Key,'return')
            ButtonPressGo;
        end
    end

%% Initialize Input/Output Devices

disp('Initializing I/O...');

% Start recording output to the Matlab command window
log_file_name = ['fmriDG_s' num2str(subject_number) '_' num2str(session_number) '_log.txt'];
diary(fullfile(output_directory,log_file_name));
diary on;

%% Initialize Eye-Tracker

if eye_tracker

    disp('Initizlizing Eye Tracker...');

    % Initialization of the connection with Eyelink.
    % exit program if this fails.
    eyelink_connected = EyelinkInit;
    if ~eyelink_connected
        disp('EyeLinkInit failed');
        terminate_exp;
        return;
    end
    
    Eyelink('command', 'link_sample_data = LEFT,RIGHT,GAZE,AREA');

    % open file to record data to
    status = Eyelink('openfile', edf_file_name);
    if status ~= 0
        disp(['Error opening eyelink file: error code ' num2str(status) '.']);
        terminate_exp;
        return;
    end
end

%% Initinalize PsychToolBox Display

try % The purpose of the try-catch code is to catch any run-time errors and 
    % make sure that they also result in a graceful abort of the
    % experiment (otherwise the PsychToolBox screen will remain on
    % and we won't see the error).
    
    disp('Initalizing Display...');
    clear Screen % just in case

    % Set debug mode
    if debug_mode
        PsychDebugWindowConfiguration(0,0.5);
    end

    % Open a graphics window
    [window,rect] = Screen('OpenWindow', whichScreen);

    % Set alpha blending function (this allows transparency)
    Screen(window,'BlendFunction',GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    % Hide the mouse cursor
    if ~debug_mode
        HideCursor(whichScreen);
    end

    % Retrieve color codes for black, white, gray and red
    black = BlackIndex(window);  % Retrieves the CLUT color code for black.
    white = WhiteIndex(window);  % Retrieves the CLUT color code for white.
    gray = (white - black)*background_grayscale_value + black; 
    red = [white/2 black black];

    % Define fixation cross
    [X,Y] = RectCenter(rect);
    FixCross = [X-fix_cross_width,Y-fix_cross_size,X+fix_cross_width,Y+fix_cross_size;X-fix_cross_size,Y-fix_cross_width,X+fix_cross_size,Y+fix_cross_width];
    FixCross_target = [X-fix_cross_size,Y-fix_cross_width,X+fix_cross_size,Y+fix_cross_width];

    Screen('Flip', window); 
    pause(0.1);

    % Load textures
    disp('Loading textures...');
    num_face_images = length(stimuli.faces);
    for i = 1:num_face_images
        textures.faces{i} = Screen('MakeTexture', window, stimuli.faces{i});
    end
    num_house_images = length(stimuli.houses);
    for i = 1:num_house_images
        textures.houses{i} = Screen('MakeTexture', window, stimuli.houses{i});
    end
    
    textures.icons.hit = Screen('MakeTexture', window, icon.hit);
    textures.icons.miss = Screen('MakeTexture', window, icon.miss);

    % Set font
    Screen('TextFont',window,'Times New Roman(Hebrew)');
    Screen('Textfont', window, '-:lang=he');  
    Screen('Preference','TextEncodingLocale','en_US.ISO8859-1');
    
catch err % This is what happens if there was an error within the function
    % Show error
    disp('ERROR! terminating...');    
    
    disp('Saving expdata...');
    % save exp data
    save([output_directory filesep save_file_name],'expdata');
    
    disp('Saving workspace for debugging');
    % save exp data as well as entire workspace for debugging 
    save([output_directory filesep 'fmriDG_s' num2str(subject_number) '_' num2str(session_number) '_crash_workspace.mat']);
    
    % terminate
    terminate_exp;
    commandwindow;
    
    disp('Now throwing error:');
    for i = length(err.stack):-1:1
        disp(err.stack(i));
    end
    disp(['ERROR: ' err.message]);
    
    % Close diary
    diary off
    
    return;
end

%% Run Experiment

try % The purpose of the try-catch code is to catch any run-time errors and 
    % make sure that they also result in a graceful abort of the
    % experiment (otherwise the PsychToolBox screen will remain on
    % and we won't see the error).
    
    % Start logging keyboard (and TR trigger) input
    % There is some error that can come up where the experiment will not
    % start after the first run due to some problem with the Kb Queue. 
    % Closing and restarting Matlab is one solution for this... 
    KbQueueCreate;
    KbQueueStart;
    
    disp('Show instructions...');
    
    % Instructions
    if exp_language == 1
        txt = txt_instr_eng;
    else
        if subject_sex == 1
            txt = txt_instr_heb_f;
        else
            txt = txt_instr_heb_m;
        end
    end
    DrawFormattedText(window,double(txt),'center','center',black,[],[],[],2);
    Screen('Flip', window); 
    KbQueueFlush;
    while wait_for_tr_or_kb_input
    end
    
    % Calibrate eye tracker 
    if eye_tracker
        % Provide Eyelink with details about the graphics environment
        % and perform some initializations. The information is returned
        % in a structure that also contains useful defaults
        % and control codes (e.g. tracker state bit and Eyelink key values).
        el=EyelinkInitDefaults(window);

        txt = 'Configuring eye tracker \n Press any key to continue.';
        DrawFormattedText(window,double(txt),'center','center',black,[],[],[],2);  
        Screen('Flip', window); 
        pause(0.1);  KbWait;

        txt = 'Skip eye-tracker calibration? Y/N';
        Screen('FillRect', window, gray);
        DrawFormattedText(window,double(txt),'center','center',black,[],[],[],2);
        Screen('Flip', window); 
        ynselected= false;
        while ~ynselected && ~stop_exp
            pause(0.1); [~,keyCodes] = KbWait;
            keyCodes = find(keyCodes);
            if ismember(keyCodes,KBOARD_CODE_Y)
                ynselected = true;
                run_calibrate = false;
            else
                ynselected = true;
                run_calibrate = true;
            end
        end
        if run_calibrate 
            % Calibrate the eye tracker
            EyelinkDoTrackerSetup(el);

            % Do a final check of calibration using driftcorrection
            EyelinkDoDriftCorrection(el);
        end

        Eyelink('StartRecording');
        
        eye_used = Eyelink('EyeAvailable'); % get eye that's tracked
        if eye_used == el.BINOCULAR; % if both eyes are tracked
            eye_used = el.LEFT_EYE; % use left eye
        end
        disp(['Eye used: ' num2str(eye_used)]);

        Eyelink('StopRecording');

    end
    
    % Run practice block
    while do_practice && ~stop_exp

        disp('Run practice Block...');

        curr_block = 0; % Block 0 indicates a practice block
        run_block(curr_block); % nested function

        txt = corrtxt(TextStr.RepeatPractice);
        Screen('FillRect', window, gray);
        DrawFormattedText(window,double(txt),'center','center',black,[],[],[],2);
        Screen('Flip', window); 
        ynselected = false;
        while ~ynselected && ~stop_exp
            pause(0.1); 
            [~,keyCodes] = KbWait;
            keyCodes = find(keyCodes);
            if ismember(keyCodes,KBOARD_CODE_Y)
                ynselected = true;
            elseif ismember(keyCodes,KBOARD_CODE_N)
                ynselected = true;
                do_practice = false;
            end
        end
    end

    disp('Run test blocks...');

    curr_block = start_block; % set starting block
    total_false_alarms = 0; % reset
    total_hits = 0; % reset
    
    
    % Get first scanner trigger
    fprintf('Waiting for first scanner input trigger...\n');
    wait_for_tr_or_kb_input;
    
    % The actual experiment runs within this loop: 
    while curr_block <= num_blocks && ~stop_exp
        disp(['Block ' num2str(curr_block)]);
        run_block(curr_block);
        curr_block = curr_block + 1; 
    end

    % Save data
    disp('Saving Data...');
    txt = corrtxt(TextStr.SavingData);
    Screen('FillRect', window, gray);
    DrawFormattedText(window,double(txt),'center','center',black,[],[],[],2);
    Screen('Flip', window); 
    save([output_directory filesep save_file_name],'expdata');

    % Thank you
    txt = corrtxt(TextStr.ThankYou);
    Screen('FillRect', window, gray);
    DrawFormattedText(window,double(txt),'center','center',black,[],[],[],2);
    Screen('Flip', window); 
    pause(0.8);

    % Shut down experiment
    disp('Terminating Exp...');
    terminate_exp;
    
    % Close diary
    diary off

catch err % This is what happens if there was an error within the function
    % Show error
    disp('ERROR! terminating...');    
    
    disp('Saving expdata...');
    % save exp data
    save([output_directory filesep save_file_name],'expdata');
    
    disp('Saving workspace for debugging');
    % save exp data as well as entire workspace for debugging 
    save([output_directory filesep 'fmriDG_s' num2str(subject_number) '_' num2str(session_number) '_crash_workspace.mat']);
    
    % terminate
    terminate_exp;
    commandwindow;
    
    disp('Now throwing error:');
    for i = length(err.stack):-1:1
        disp(err.stack(i));
    end
    disp(['ERROR: ' err.message]);
    
    % Close diary
    diary off
    
    return;
end

disp('Done.');

%% Nested functions
% Nested functions are define within another function's function...end
% block (the main expriment function in this case). They are different from
% external functions in that they can see the workspace of the calling
% function, so there's no need to pass them all these variables as
% arguments. 

    function run_block(block_num)
        
        wait_trs_before_block = ceil(wait_time_before_first_stim_sec / tr_duration_sec);
        wait_trs_after_block = ceil(wait_time_after_last_stim_sec / tr_duration_sec);

        if block_num == 0
            practice = true;
        else
            practice = false; 
        end
        
        % Initialize block variables
        curr_trial_in_block = 0;
        block_hits = 0;
        block_false_alarms = 0;
        block_misses = 0;
        block_correct_rejections = 0;
        
        % Display block start screen
        go = false;
        while ~go
            
            if practice
                if subject_sex == 1
                    txt = [corrtxt(TextStr.PracticeBlockF) '\n\n' ...
                        '(''c'' for calibration, ''d'' for drift check) \n\n'];
                else
                    txt = [corrtxt(TextStr.PracticeBlockM) '\n\n' ...
                        '(''c'' for calibration, ''d'' for drift check) \n\n'];
                end
            else
                if subject_sex == 1
                    txt = [TextStr.Block num2str(curr_block) ' \n\n' TextStr.PressAnyKeyF '\n\n' ...
                        '(''c'' for calibration, ''d'' for drift check) \n\n' ...
                        'Press any button and then start scanner \n'];
                else
                    txt = [TextStr.Block num2str(curr_block) ' \n\n' TextStr.PressAnyKeyM '\n\n' ...
                        '(''c'' for calibration, ''d'' for drift check) \n\n' ...
                        'Press any button and then start scanner \n'];
                end
            end
            
            Screen('FillRect', window, gray);
            DrawFormattedText(window,double(txt),'center','center',black,[],[],[],2);
            Screen('Flip', window);
            
            [~, pressed, pressed_keys] = wait_for_tr_or_kb_input;
            if pressed_keys(SCANNER_KEY)
                % do nothing
            elseif pressed_keys(KBOARD_CODE_C)
                if eye_tracker
                    EyelinkDoTrackerSetup(el);
                end
            elseif pressed_keys(KBOARD_CODE_D)
                if eye_tracker
                    EyelinkDoDriftCorrection(el);
                end  
            elseif any(pressed_keys(KBOARD_CODE_RESPONSE_KEYS))
                which_key = find(ismember(KBOARD_CODE_RESPONSE_KEYS, find(pressed_keys)),1,'first');
                
                txt2 = ['Response key ' num2str(which_key) ' pressed'];
                Screen('FillRect', window, gray);
                DrawFormattedText(window,double(txt2),'center','center',black,[],[],[],2);
                Screen('Flip', window);
                pause(0.02);
                DrawFormattedText(window,double(txt),'center','center',black,[],[],[],2);
                Screen('Flip', window);
            elseif pressed % any other button was pressed except d, c and the scanner trigger key
                go = true;
            end 
        end
        
        if practice
            trial_codes = practice_codes;
        else
            trial_codes = block_codes{block_num};
        end
        
        nTrials = size(trial_codes,1);
        
        % Wait before starting first trial
        for r = 1:wait_trs_before_block
            % Draw fixation
            Screen('FillRect', window, fix_cross_grayscale_value, FixCross');
            Screen('Flip', window); 
            
            % Wait for scanner trigger
            while ~wait_for_tr_or_kb_input
            end
            
            if stop_block
                break;
            end
        end
        
        % Start eye-tracker recording
        if eye_tracker
            Eyelink('StartRecording');
        end
        
        % Run block trials
        for iTrial = 1:nTrials
            if stop_block
                stop_block = false;
                break;
            end
            run_trial(trial_codes(iTrial,:));
            
            % Wait after last trial (this is not outside the loop so that 
            % the "break" case will skip it too)
            if iTrial == nTrials
                for r = 1:wait_trs_after_block
                    % wait
                    while ~wait_for_tr_or_kb_input
                    end
                end
            end
        end
        
        % Stop eye-tracker recording 
        if eye_tracker
            Eyelink('StopRecording');
        end
        
        % Show feedback screen
        txt = [TextStr.Identified num2str(block_hits) TextStr.TargetsOutOf num2str(block_hits + block_misses) '\n' ...
        TextStr.NotIdentified num2str(block_false_alarms) TextStr.NonTargetsOutOf num2str(block_false_alarms + block_correct_rejections) '\n\n'];
        if subject_sex == 1
            txt = [txt corrtxt(TextStr.PressAnyKeyF)];
        else
            txt = [txt corrtxt(TextStr.PressAnyKeyM)];
        end
        Screen('FillRect', window, ceil(gray*0.8));
        DrawFormattedText(window,double(txt),'center','center',black,[],[],[],2);
        Screen('Flip', window); 
        % wait for any key
        while wait_for_tr_or_kb_input
        end
    end

    function run_trial(trial_codes)
        % This is where everything happens
        
        % Initialize trial variables
        if curr_block == 0
            practice = true;
        else
            practice = false;
        end
        subject_responded = false;
        target_latency = trial_codes.target_latency;
        target_shown_time = now;
        target_shown = false;
        
        % Compute timing variables
        trial_tr = 0; 
        duration_by_trs = ceil(trial_codes.duration / tr_duration_sec);
        soa_by_trs = ceil(trial_codes.soa / tr_duration_sec);

        % Run over all screen refreshes within the trial duration (duration + ISI):
        while trial_tr < soa_by_trs
            
            tr = false;
            while ~tr % wait until the next TR
                pause(0.001);
                [tr, pressed, pressed_keys] = wait_for_tr_or_kb_input;
                
                % If trial was aborted, exit the function
                if stop_block
                    return;
                end
                
                % Check if there was a response from the input box
                resp_buttons = pressed_keys(KBOARD_CODE_RESPONSE_KEYS);
                if any(resp_buttons)
                    if subject_responded == false % only if this is the first response in this trial                        

                        % record reaction time
                        press_time = min(resp_buttons(resp_buttons>0));
                        response_rt_sec = press_time - target_shown_time;
                        
                        % record performance
                        if target_shown == 0; % false alarm;
                            block_false_alarms = block_false_alarms + 1;
                            total_false_alarms = total_false_alarms + 1;
                        else % hit
                            subject_responded = true;
                            if response_rt_sec < response_rt_limit_sec
                                block_hits = block_hits + 1;
                                total_hits = total_hits + 1;
                            end
                        end
                    end
                end
            end
            
            % Next TR has started
            trial_tr = trial_tr + 1;

            % Initialize canvas
            Screen('FillRect', window, gray);

            % If we are within the stimulus duration period, it should 
            % be drawn on the screen.
            if trial_tr > 0 && trial_tr <= duration_by_trs 
                
                % Draw stimulus according to its type
                switch(trial_codes.type{1})
                    case 'face'
                        img_idx = trial_codes.image_index;
                        Screen('DrawTexture', window, textures.faces{img_idx}, [], rectangle_stim_pix,[],[],img_alpha);
                    case 'house'
                        img_idx = trial_codes.image_index;
                        Screen('DrawTexture', window, textures.houses{img_idx}, [], rectangle_stim_pix,[],[],img_alpha);
                end
            end
            
            % Display target
            if trial_tr == floor(target_latency/tr_duration_sec)
                % Draw target
                Screen('FillRect', window, fix_cross_grayscale_value, FixCross_target');
                Screen('Flip', window);
                target_shown_time = GetSecs;
                target_shown = true;
                pause(target_display_time_sec);
                % Now we need to re-draw the image if it was there
                if trial_tr > 0 && trial_tr <= duration_by_trs 
                    switch(trial_codes.type{1})
                        case 'face'
                            img_idx = trial_codes.image_index;
                            Screen('DrawTexture', window, textures.faces{img_idx}, [], rectangle_stim_pix,[],[],img_alpha);
                        case 'house'
                            img_idx = trial_codes.image_index;
                            Screen('DrawTexture', window, textures.houses{img_idx}, [], rectangle_stim_pix,[],[],img_alpha);
                    end
                end
            end
            
            % Draw fixation
            Screen('FillRect', window, fix_cross_grayscale_value, FixCross');
            Screen('Flip', window);
            
            % Record timing information
            if trial_tr <= 1 % could be 0 if no fixation, in which case trialStartTime still needs to be initialized
                trialStartTime = now;
            elseif trial_tr == duration_by_trs+1 % stimulus ended
                stimulusEndTime = now;
                durationTime_sec = (stimulusEndTime - trialStartTime)*24*3600;
            elseif trial_tr == soa_by_trs  % trial ends next TR
                trialEndTime = now + tr_duration_sec;
                soaTime_sec = (trialEndTime - trialStartTime)*24*3600;
            end
        end

        % Send message to Eyelink
        if eye_tracker
            msg = ['TR ' num2str(curr_tr)];
            Eyelink('Message',msg);
        end
        
        % If subject did not respond during this trial, check if it was a target trial. 
        if target_shown && ~subject_responded % miss
            block_misses = block_misses + 1;
            total_misses = total_misses + 1;
        elseif ~target_shown && ~subject_responded % correct rejection
            block_correct_rejections = block_correct_rejections + 1;
            total_correct_rejections = total_correct_rejections + 1;
        end

        % Record trial information in expdata
        curr_trial = curr_trial + 1;
        curr_trial_in_block = curr_trial_in_block + 1;

        % Trial information
        % Add new table row (this line is only necessary to avoid a warning
        % issued by matlab if a new line is created just by entering the
        % first variable, as in the subsequent line). 
        expdata.trials(curr_trial,:) = table(0,0,0,{0},0,0,{0},0,0,0,0,0,0,0,0,0,0,0);
        % Update table
        expdata.trials.block_number(curr_trial) = curr_block;
        expdata.trials.trial_number(curr_trial) = curr_trial;
        expdata.trials.block_trial(curr_trial) = curr_trial_in_block;
        expdata.trials.time{curr_trial} = trialStartTime;
        expdata.trials.practice(curr_trial) = practice;
        expdata.trials.code(curr_trial) = trial_codes.onset_code;
        expdata.trials.duration(curr_trial) = trial_codes.duration;
        expdata.trials.type{curr_trial} = trial_codes.type{1};
        expdata.trials.target_latency(curr_trial) = trial_codes.target_latency;
        expdata.trials.soa(curr_trial) = trial_codes.soa;
        expdata.trials.response(curr_trial) = 0;

        % Behavioral information
        expdata.trials.true_duration(curr_trial) = (durationTime_sec + 1/ScrInfo.hz);
        expdata.trials.true_soa(curr_trial) = soaTime_sec;
        if subject_responded
            expdata.trials.response(curr_trial) = 1;
            expdata.trials.response_rt(curr_trial) = response_rt_sec;
        end
        expdata.trials.hits(curr_trial) = total_hits;
        expdata.trials.misses(curr_trial) = total_misses;
        expdata.trials.false_alarms(curr_trial) = total_false_alarms;
        expdata.trials.correct_rejections(curr_trial) = total_correct_rejections;
    end

    function [tr, pressed, pressed_keys] = wait_for_tr_or_kb_input
        tr = false;
        pressed = false;
        while ~pressed
            pause(0.001);
            [pressed, pressed_keys] = KbQueueCheck;
        end
        if pressed_keys(SCANNER_KEY)
            curr_tr = curr_tr + 1;
            tr_timestamp(curr_tr) = pressed_keys(SCANNER_KEY);
            tr = true;
        elseif pressed_keys(KBOARD_CODE_ESC)
            query_stop;
        end
    end

    function query_stop
        
        txt = 'Press ''y'' to end experiment, ''b'' to end the block, \n or any other key to continue';
        Screen('FillRect', window, gray);
        DrawFormattedText(window,double(txt),'center','center',black,[],[],[],2);
        Screen('Flip',window);
         
        wait_for_response = true;
        while wait_for_response
            pause(0.001);
            [pressed, pressed_keys] = KbQueueCheck;
            if pressed_keys(KBOARD_CODE_Y)
                stop_block = true;
                stop_exp = true;
                wait_for_response = false;
            elseif pressed_keys(KBOARD_CODE_B)
                stop_block = true;
                wait_for_response = false;
            elseif pressed
                wait_for_response = false;
            end
        end
        Screen('FillRect', window, gray);
        Screen('Flip',window);
    end

    function terminate_exp()
        
        % Restore the mouse cursor.
        ShowCursor;
        
        % Close all window and textures
        % For some reason "Screen('CloseAll')" doens't seem to work. 
        if exist('textures','var')
            for i=1:num_face_images
                Screen('Close',textures.faces{i});                
            end
            for i=1:num_house_images
                Screen('Close',textures.houses{i});                
            end
        end
        
        % Close PTB screen
        sca;
        
        % Retrieve Eyelink EDF file and shut down:
        if eye_tracker
            if eyelink_connected
                disp('Retrieving EDF file from eye-tracker.');
                Eyelink('CloseFile');
                curr_dir = pwd;
                cd(output_directory);
                stat = Eyelink('ReceiveFile',edf_file_name);
                cd(curr_dir);
                if stat ~= 0
                    disp(['Error in retrieving EDF file: ' edf_file_name]);
                end
                
                Eyelink('Shutdown');
            end
        end
        
        % Give focus back to Matlab
        commandwindow;
        
    end

    function out = corrtxt(in)
        % apply correction to hebrew text so that punctuation at the end of 
        % the string does not move to the beginning and vice versa. It 
        % helps to make Hebrew text more readable but it's not perfect - if 
        % you have consecutive punctuation marks or Hebrew and English 
        % within the same line, some of the text may be in the wrong order. 
        % Bidirectional text is a hassle! 

        i = length(in);
        while i > 0
        %     if in(i) >= 1488 && in(i) <= 1514 
            if in(i) > 64
                break;
            else
                i = i - 1;
            end
        end
        j = 1;
        while j <= length(in)
            if in(j) >= 1488 && in(i) <= 1514 
                break;
            else
                j = j + 1;
            end
        end

        out = [ in(end:-1:(i+1)) in(j:i) in(1:(j-1)) ];
        out = double(out);
    end

end
