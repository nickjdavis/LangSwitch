function eeg_process_subjects_switch(controlFile)

eeglab

T = readtable(controlFile, 'Delimiter',',', 'Format', 'auto')

nSubjects = size(T,1);


for i=1:nSubjects
    % STEP 1 - open raw data, preprocess, save events
    fname = strcat(T.Folder{i},'\',T.Raw{i});
    % 1.1 - Open data
    EEG = pop_fileio(fname, 'dataformat','auto');
    EEG.setname=T.Participant{i};
    % 1.1a - Add electrode locations
    EEG = pop_chanedit(EEG, 'load',...
        {'C:\\Users\\Nick\\Documents\\MATLAB\\eeglab\\sample_locs\\standard_waveguard64_duke_edited.elc','filetype','autodetect'});
    % 1.2 - Save events
    %eventsfile = strrep(fname,'.set','_events.txt');
    %pop_expevents(EEG, eventsfile, 'samples')
    eventsfile = strrep(fname,'.set','_eventlist.txt');
    EEG  = pop_creabasiceventlist( EEG , 'BoundaryNumeric', { -99 }, 'BoundaryString', { 'boundary' }, 'Eventlist', eventsfile ); % GUI: 09-Jul-2024 17:36:16
    % 1.3 - Preprocess (downsample 1000 -> 500 Hz)
    newname = strcat(T.Participant{i},'_res');
    newfullname = strcat(T.Folder{i},'\',newname,'.set');
    if ~isfile(newfullname)
        EEG = pop_resample( EEG, 500);
        EEG.setname = newname;
    else
        disp('- Downsampled file already exists - loading existing file.')
        EEG = pop_fileio(newfullname, 'dataformat','auto');
        EEG.setname = newname;
    end
    % 1.4 - Preprocess (filter 0.1 - 30Hz)
    newname = strcat(T.Participant{i},'_res_f');
    newfullname = strcat(T.Folder{i},'\',newname,'.set');
    if ~isfile(newfullname)
        EEG = pop_eegfiltnew(EEG, 'locutoff',0.01,'hicutoff',30);
        %setName = strrep(fname,'.set','_f.set')
        EEG.setname = strcat(EEG.setname, '_f');
        EEG = pop_saveset( EEG, 'filename', EEG.setname,'filepath',strcat(T.Folder{i},'\'));
    else
        disp('- Filtered file already exists - loading existing file.')
        EEG = pop_fileio(newfullname, 'dataformat','auto');
        EEG.setname = newname;
    end

    %eeglab redraw
    
    % STEP 2 - Edit events file
    neweventsfile = edit_eventfile(eventsfile);

    % STEP 3 - use edited events file to process ERPs
    % 3.1 - Load edited events
    EEG = pop_importeegeventlist( EEG, neweventsfile , 'ReplaceEventList', 'on' ); 
    % 3.2 - Import binlist
    EEG  = pop_binlister( EEG , 'BDF', 'D:\Data\LangSwitch\BDF_v3.txt', 'IndexEL',  1, 'SendEL2', 'EEG', 'UpdateEEG', 'on', 'Voutput', 'EEG' ); % GUI: 10-Jul-2024 22:47:38
    % 3.3 - Use bin list to create epochs
    EEG = pop_epochbin( EEG , [-200.0  800.0],  'pre');

    % 3.4 - Average ERPs
    ERPfile = strcat(T.Participant{i},'.erp');
    ERP = pop_averager( EEG , 'Criterion', 'good', 'DQ_custom_wins', 0, 'DQ_flag', 0, 'DQ_preavg_txt', 0, 'ExcludeBoundary', 'on' );
    ERP = pop_savemyerp( ERP, 'erpname',T.Participant{i}, 'filename', ERPfile, 'filepath', strcat(T.Folder{i},'\'), 'Warning','off');

    % 3.5 - Plot ERPs
    %{
    ERP = pop_ploterps( ERP,  1:4,  1:64 , 'Axsize', [ 0.05 0.08], 'BinNum', 'on', 'Blc', 'pre', 'Box', [ 8 8], 'ChLabel', 'on', 'FontSizeChan',...
        10, 'FontSizeLeg',  12, 'FontSizeTicks',  10, 'LegPos', 'bottom', 'Linespec', {'k-' , 'r-' , 'b-' , 'g-' }, 'LineWidth',  1, 'Maximize',...
        'on', 'Position', [ 67.7143 26.2941 106.857 31.9412], 'Style', 'Classic', 'Tag', 'ERP_figure', 'Transparency',  0, 'xscale', [ -200.0 798.0   -200:200:600 ],...
        'YDir', 'normal', 'yscale', [ -300.0 300.0   -100:50:100 ] );
    %}

    % 3.6 - Save ERPs amps to file
    ERP = pop_loaderp( 'filename', ERPfile, 'filepath', strcat(T.Folder{i},'\') );
    ALLERP = pop_geterpvalues( ERP, [ 150 350],  1:8,  3 , ...
        'Baseline', 'pre', 'FileFormat', 'wide',...
        'Filename', strcat(T.Folder{i},'\',T.Participant{i},'_Amps.txt'),...
        'Fracreplace', 'NaN', 'InterpFactor',  1, 'Measure', 'peakampbl', ...
        'Mlabel', 'N2', 'Neighborhood',  3, 'PeakOnset',  1, ...
        'Peakpolarity', 'negative', 'Peakreplace', 'absolute', ...
        'Resolution',  3 );


    STUDY=[]; CURRENTSTUDY=0; ALLEEG=[]; EEG=[]; CURRENTSET=[]; ERP=[];
end 



%% ------------------------------------------------------------------

function outfile = edit_eventfile (eventfile)

% open files
outfile = strrep(eventfile,'.txt','_edited_sw.txt');
fidIN = fopen(eventfile);
fidOUT= fopen(outfile,'w');

postStim = 0;
nEvents = 0;
currLang = 0; % 0=Ignore, 1=Eng, 2=Urdu

% open marker file and read data
tline = fgetl(fidIN);
while ischar(tline)
    if isempty(tline)
        % do nothing
        fprintf(fidOUT,'%s\n',tline);
    elseif strcmp(tline(1),'#')
        % header/info line - add without editing
        fprintf(fidOUT,'%s\n',tline);
    else
        nEvents = nEvents+1;
        % replace NaN with succeeding number
        ecodeloc = strfind(tline,'NaN');
        pre = tline(1:(ecodeloc-1));
        post = tline((ecodeloc+3):end);
        % need to parse 'post' to get new code
        % Next lines get numeric code (C, Cn) plus rest of line (S{2})
        S = regexp(post,',','split');
        C = regexp(S{1},'\d*','match');
        Cn = str2num(C{:}); % numeric code
        % check code and edit if needed
        % three-digit codes are more pleasing!
        % NB two different ways to find break point in expt...
        if contains(S{2},'Impedance')
            Cn = 903;
            if nEvents>50, postStim = 1; end;
        end
        if Cn==9001
            Cn = 901;
            if nEvents>50, postStim = 1; end;
        end
        if Cn==9002
            Cn = 902;
            if nEvents>50, postStim = 1; end;
        end
        if contains(S{2},'incorrect')
            Cn = 501;
        elseif contains(S{2},'correct')
            % NB - this relies on finding 'incorrect' first
            Cn = 500;
        end
        if (Cn==101 || Cn==102 || Cn==201 || Cn==202)
            if Cn==101 % ENGLISH
                if currLang==1 % E, NS
                    Cn = 601;
                elseif currLang==2 % E, S
                    Cn = 602;
                else % Ignore
                    Cn = 600;
                end
                currLang = 1;
            end
            if Cn==102 % URDU
                if currLang==1 % U, S
                    Cn = 604;
                elseif currLang==2 % U, NS
                    Cn = 603;
                else % Ignore
                    Cn = 600;
                end
                currLang = 2;
            end
            if Cn==201
                if currLang==1 % E, NS
                    Cn = 701;
                elseif currLang==2 % E, S
                    Cn = 702;
                else % Ignore
                    Cn = 700;
                end
                currLang = 1;
            end
            if Cn==202
                if currLang==1 % U, S
                    Cn = 704;
                elseif currLang==2 % U, NS
                    Cn = 703;
                else % Ignore
                    Cn = 700;
                end
                currLang = 2;
            end
            if postStim==1
                % To identify post-stimulation trials
                Cn = Cn+10;
            end
        end
        newline = sprintf('%s\t%d\t%s',pre,Cn,S{2});
        tline = newline;
        fprintf(fidOUT,'%s\n',tline);
    end
    %disp(tline)
    tline = fgetl(fidIN);
end
fclose(fidIN);
fclose(fidOUT);

%% ------------------------------------------------------------------
     
%{
function outfile = edit_eventfile_switch (eventfile)

% open files
outfile = strrep(eventfile,'.txt','_edited_sw.txt');
fidIN = fopen(eventfile);
fidOUT= fopen(outfile,'w');

postStim = 0;
nEvents = 0;

% open marker file and read data
tline = fgetl(fidIN);
while ischar(tline)
    if isempty(tline)
        % do nothing
        fprintf(fidOUT,'%s\n',tline);
    elseif strcmp(tline(1),'#')
        % header/info line - add without editing
        fprintf(fidOUT,'%s\n',tline);
    else
        nEvents = nEvents+1;
        % replace NaN with succeeding number
        ecodeloc = strfind(tline,'NaN');
        pre = tline(1:(ecodeloc-1));
        post = tline((ecodeloc+3):end);
        % need to parse 'post' to get new code
        % Next lines get numeric code (C, Cn) plus rest of line (S{2})
        S = regexp(post,',','split');
        C = regexp(S{1},'\d*','match');
        Cn = str2num(C{:}); % numeric code
        % check code and edit if needed
        % three-digit codes are more pleasing!
        % NB two different ways to find break point in expt...
        if contains(S{2},'Impedance')
            Cn = 903;
            if nEvents>50, postStim = 1; end;
        end
        if Cn==9001
            Cn = 901;
            if nEvents>50, postStim = 1; end;
        end
        if Cn==9002
            Cn = 902;
            if nEvents>50, postStim = 1; end;
        end
        if contains(S{2},'incorrect')
            Cn = 501;
        elseif contains(S{2},'correct')
            % NB - this relies on finding 'incorrect' first
            Cn = 500;
        end
        if (Cn==101 || Cn==102 || Cn==201 || Cn==202) && postStim==1
            % To identify post-stimulation trials
            Cn = Cn+10;
        end
        newline = sprintf('%s\t%d\t%s',pre,Cn,S{2});
        tline = newline;
        fprintf(fidOUT,'%s\n',tline);
    end
    %disp(tline)
    tline = fgetl(fidIN);
end
fclose(fidIN);
fclose(fidOUT);

%}