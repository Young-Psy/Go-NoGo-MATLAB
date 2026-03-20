function [] = GO_NOGO2()
clearvars;close all;clc;
%% get sub&exp information
expinfo = [];
dlgprompt = {'Subject ID:'...
    'Age:'};
dlgname = 'Sub&Exp information';
numlines = 1;
defaultanswer = {'Sub2024','0'};
ans1 = inputdlg(dlgprompt,dlgname,numlines,defaultanswer);
expinfo.id = ans1{1};
expinfo.age = str2num(ans1{2});

sexStrList    = {'Female','Male'};
handStrList   = {'Right','Left'};
[sexidx,v]    = listdlg('PromptString','Gender:','SelectionMode','Single','ListString',sexStrList);
expinfo.sex   = sexStrList{sexidx};
if ~v; expinfo.sex  = 'NA'; end
[handidx,v]   = listdlg('PromptString','Handedness:','SelectionMode','Single','ListString',handStrList);
expinfo.hand  = handStrList{handidx};
if ~v; expinfo.hand = 'NA'; end

% set stimulus parameters
expinfo.RedColor = [255;0;0];
expinfo.GreenColor = [0;255;0];
expinfo.GrayColor  = [190;190;190];
expinfo.BackgroundColor = [0;0;0];
expinfo.InstructionColor = [120;120;120];
expinfo.visangle  = 1.5;

% set instruction
textStart = ['欢迎参加本次实验，\n'...
    '在注视点结束之后会呈现一个信号。\n'...
    '看见绿色信号请在1s之内尽快按空格键，\n'...
    '看见红色信号无需按键，只需等待结束，\n'...
    '红色信号出现如果按键则信号变为灰色。'];
textEnd = ['实验结束。\n'...
    '感谢参与！'];

% Key assignment
KbName('UnifyKeyNames');
spaceKey   = KbName('space');
quitKey    = KbName('escape');
while KbCheck; end
ListenChar(2);

% Set the folder and filename for data save
destdir = './Go_NOGO/';
if ~exist(destdir,'dir'),mkdir(destdir);end
expinfo.path2save = strcat(destdir,expinfo.id,'GO_NOGO_',mfilename,'_',datestr(now,30));

data = [];
data.expinfo = expinfo;
save(expinfo.path2save,'data');

% set other parameters
viewDistance = 600; % viewing distance (mm)
whichScreen  = 0; % screen index for use
winRect      = []; % initial winPtr size, empty indicates a whole screen winPtr
pixelDepth   = 32;
numBuffer    = 2;
stereoMode   = 0;
multiSample  = 0;
imagingMode  = [];

%% Standard coding practice, use try/catch to allow cleanup on error.
try
    % This script calls Psychtoolbox commands available only in
    % OpenGL-based versions of Psychtoolbox. The Psychtoolbox command
    % AssertPsychOpenGL will issue an error message if someone tries to
    % execute this script on a computer without an OpenGL Psychtoolbox.
    AssertOpenGL;
    
    % Screen is able to do a lot of configuration and performance checks on
    % open, and will print out a fair amount of detailed information when
    % it does. These commands supress that checking behavior and just let
    % the program go straight into action. See ScreenTest for an example of
    % how to do detailed checking.
    oldVisualDebugLevel    = Screen('Preference','VisualDebugLevel',3);
    oldSuppressAllWarnings = Screen('Preference','SuppressAllWarnings',1);
    
    % Open a screen winPtr and get winPtr information.
    [winPtr, winRect] = Screen('OpenWindow',whichScreen,expinfo.BackgroundColor,winRect,pixelDepth,numBuffer,stereoMode,multiSample,imagingMode);
    Screen('BlendFunction',winPtr,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
    Screen('TextSize',winPtr,35);
    Screen('TextFont',winPtr,'Kaiti');
    [x0,y0] = RectCenter(winRect);
    ifi = Screen('GetFlipInterval',winPtr);
    [width_mm, height_mm] = Screen('DisplaySize', whichScreen);
    screenSize    = [width_mm, height_mm];
    winResolution = [winRect(3)-winRect(1),winRect(4)-winRect(2)];
    ppd = viewDistance*tan(pi/180)*winResolution./screenSize;
    ppd = round(ppd);
    stimsize = ppd(1)*expinfo.visangle;
    
    
    
    % Hide mouse curser and set the priority level
    HideCursor;
    priorityLevel = MaxPriority(winPtr);
    Priority(priorityLevel);
    
    % prepare for the fix figure
    fix{1} = imread(['.\stim\' num2str(1) '.png'],'png');
    for i = 1:size(fix{1},1)
        for j = 1:size(fix{1},2)
            if fix{1}(i,j,1:3) ~= expinfo.BackgroundColor
                fix{1}(i,j,1:3) = expinfo.InstructionColor;
            end
        end
    end
    textfix{1} = Screen('MakeTexture',winPtr,fix{1});
    
    %% start trial
    rng('Shuffle');
    stim = [repmat(1,1, 60), repmat(2, 1, 40)];
%     stim = [repmat('Go', 1, 60), repmat('NoGo', 1, 40)];
%     stim = repmat('Go', 60, 1) + repmat('NoGo', 40, 1);
%     stimrand = randperm(100);
%     stimrand = cell(100,1);
    
    
    trlT = 100;
    GoRTs = zeros(trlT,2);
    GoNoRes  = 0;
    NoGoErrors = 0;
    trl = 1;
    
    % present start instrcution
    BoundsRect1 = Screen('TextBounds',winPtr,double(textStart));
    DrawFormattedText(winPtr,double(textStart),x0+1000-(BoundsRect1(3)-BoundsRect1(1))/2,y0-(BoundsRect1(4)-BoundsRect1(2))/2,expinfo.InstructionColor);
    Screen('Flip',winPtr)
    while 1
        [keydown, ~, keycode] = KbCheck;
        if keydown
            while KbCheck; end
            if keycode(spaceKey)|| keycode(quitKey); break; end
        end
    end
    while trl <= 100
        data.seq = Shuffle (stim);
        Screen('DrawTexture',winPtr,textfix{1},[],[x0-stimsize/2,y0-stimsize/2,x0+stimsize/2,y0+stimsize/2]);
        Screen('Flip', winPtr);
        WaitSecs(0.5 + 0.5.*rand);
        
        if data.seq(trl) == 1
            Screen('FillOval', winPtr, expinfo.GreenColor, [x0-stimsize/2,y0-stimsize/2,x0+stimsize/2,y0+stimsize/2]);
            Screen('Flip',winPtr);
            t0 = GetSecs;
            while GetSecs - t0 <= 1
                [keydown, ~, keycode] = KbCheck;
                if keydown
                    while KbCheck; end
                    if keycode(spaceKey); break; end
                    GoRTs = [GoRTs, GetSecs - t0];
                else
                    GoNoRes = GoNoRes + 1;
                end
            end
        else
            Screen('FillOval', winPtr, expinfo.RedColor, [x0-stimsize/2,y0-stimsize/2,x0+stimsize/2,y0+stimsize/2]);
            Screen('Flip',winPtr);
            t1 = GetSecs;
            while GetSecs - t1 <= 1
                [keydown, ~, keycode] = KbCheck;
                if keydown
                    while KbCheck; end
                    if keycode(spaceKey)
                        Screen('FillOval', winPtr, expinfo.GrayColor, [x0-stimsize/2,y0-stimsize/2,x0+stimsize/2,y0+stimsize/2]);
                        Screen('Flip',winPtr);
                        NoGoErrors =NoGoErrors +1 ;
                    end
                end
            end
        end
        trl = trl + 1;
        
    end
    % save all the results after each trl
    data.GoRTs = GoRTs;
    data.GoNoRes = GoNoRes;
    data.NoGoErrors = NoGoErrors;
    save(expinfo.path2save,'data');
    
    % The end statement of the experiment
    DrawFormattedText(winPtr,double(textEnd),150,y0-40,expinfo.InstructionColor);
    Screen('Flip',winPtr);
    WaitSecs(2.0);
    Screen('FillRect',winPtr,expinfo.BackgroundColor);
    Screen('Flip',winPtr);
    Screen('CloseAll');
    ShowCursor;
    fclose('all');
    Priority(0);
    % Restore preferences
    Screen('Preference', 'VisualDebugLevel', oldVisualDebugLevel);
    Screen('Preference', 'SuppressAllWarnings', oldSuppressAllWarnings);
    ListenChar(0);
    
catch
    % Catch error.
    Screen('FillRect',winPtr,expinfo.BackgroundColor);
    Screen('Flip',winPtr);
    Screen('CloseAll');
    ShowCursor;
    fclose('all');
    Priority(0);
    % Restore preferences
    Screen('Preference', 'VisualDebugLevel', oldVisualDebugLevel);
    Screen('Preference', 'SuppressAllWarnings', oldSuppressAllWarnings);
    ListenChar(0);
    psychrethrow(psychlasterror);
end
