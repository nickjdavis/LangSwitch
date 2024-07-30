%% BASIC EEG PREPROCESSING & ERP OUTPUT FOR ALL PARTICIPANT FILES %%


%% VARIABLE INIT %%

%mainDir = 'C:/Users/PsyTech/OneDrive - MMU/Data/eego'
mainDir = 'D:\Data\LangSwitch\participants';

% prefix = input('Enter file prefix... (string) ');

% studyDir = [mainDir '/' prefix];
studyDir = mainDir;

rawFiles = [studyDir '/_raw/cnt'];
electrodeNames = {"0Z","1Z","2Z","3Z","4Z","1L","1R","1LB","1RB","2L","2R","3L","3R","4L","4R","1LC","1RC","1LA","1RA","1LD","1RD","2LB","2LC","2RC","2RB","3LB","3RB","3LC","3RC","2LD","2RD","3RD","3LD","9Z","8Z","7Z","6Z","5Z","10L","10R","9L","9R","8L","8R","7L","7R","6L","6R","5L","5R","4LD","4RD","5LC","5RC","5LB","5RB","3LA","3RA","2LA","2RA","4LC","4RC","4LB","4RB"};

pList = input('Enter participant list... (comma-separated strings inside {})\n');
pTotal = length(pList);

mkdir([studyDir '/_participants']);

pID = '';
pDir = '';
eegFile = '';


%% OPEN EEGLAB %%
eeglab


%% IMPORT RAW DATA & EXPORT IMPORTED EVENTS %%

for pN=1:pTotal

    pID = '';
	pDir = '';

	pID = pList{pN};
	pDir = [studyDir '/_participants/' pID];
	mkdir(pDir);
    
    disp(['pID to import =' pID])
    %% LOAD EEG DATA FROM CNT FILE USING ANT EEPROBE %%
    eegFile = [prefix '_' pID '.cnt'];
	EEG = pop_loadeep_v4([rawFiles '/' eegFile]);
	
    %% EXPORT EVENTS (FOR EDITING) %%
    pop_expevents(EEG, [pDir '/' pID '_events.txt'], 'samples');
    
    %% INITIAL EEGLAB SET SAVING %%
	setName = pID;
	EEG.setname = setName;
	EEG = pop_saveset( EEG, 'filename',[setName '.set'], 'filepath',[pDir '/']);
	[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname',[setName],'overwrite',['off']);
    eeglab redraw
	%winopen([pDir '/' pID '_events.txt'])
    
    disp(['pID events to edit =' pID])

end

disp(['SECTION END: fix events via Excel or script!'])


%% CLEARS WHOLE STUDY (ALL SETS) %%
STUDY = []; CURRENTSTUDY = 0; ALLEEG = []; EEG=[]; CURRENTSET=[];
eeglab redraw


%% EEG PREPROCESSING %%

for pN=1:pTotal
    
    pID = '';
	pDir = '';

    pID = pList{pN};
	pDir = [studyDir '/_participants/' pID];
    
    %% LOAD EEGLAB SET FILE %%
    EEG = pop_loadset('filename',[pID '.set'], 'filepath', [pDir '/']);
    %eeglab redraw

    setName = EEG.setname;
    
    %% IMPORT AMENDED EVENT LIST %%
    EEG = pop_importevent( EEG, 'append','no', 'event',[pDir '/' pID '_events.txt'], 'fields',{'number', 'latency', 'type', 'duration'}, 'skipline',1, 'timeunit',NaN, 'align',0, 'optimalign','off');
    EEG = pop_saveset( EEG, 'savemode','resave');
    %[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname',[setName], 'overwrite','on', 'gui','off');
    %eeglab redraw
    
    %% STANDARD 0.01Hz HP + 30Hz LP FILTERING %%
    EEG = pop_eegfiltnew(EEG, 'locutoff',0.01,'hicutoff',30);
    setName = [pID '_f'];
    EEG.setname = [setName];
    EEG = pop_saveset( EEG, 'filename', [setName '.set'],'filepath',[pDir '/']);
    %[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname',[setName], 'overwrite','on', 'gui','off');
    %eeglab redraw
    
    %% RE-REFERENCE WITH AVERAGE REFERENCE %%
    %%% EEG = pop_reref( EEG, []);
    %%% EEG = pop_saveset( EEG, 'savemode','resave');
    
    %% CREATE EVENT LIST %%
    EEG  = pop_creabasiceventlist( EEG , 'AlphanumericCleaning','on', 'BoundaryNumeric',{ -99 }, 'BoundaryString',{ 'boundary' }, 'Eventlist',[pDir '/' pID '_EventList.txt']);
    setName = [pID '_f_elist'];
    EEG.setname = [setName];
    EEG = pop_saveset( EEG, 'filename', [setName '.set'],'filepath',[pDir '/']);
    %[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname',[setName], 'overwrite','on', 'gui','off');
    %eeglab redraw
    
    %% BINLISTER %%
    EEG  = pop_binlister( EEG , 'BDF', [studyDir '/BDF.txt'], 'IndexEL',  1, 'SendEL2', 'EEG', 'Voutput', 'EEG' );
    setName = [pID '_f_elist_bins'];
    EEG.setname = [setName];
    EEG = pop_saveset( EEG, 'filename', [setName '.set'],'filepath',[pDir '/']);
    %[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname',[setName], 'overwrite','on', 'gui','off');
    %eeglab redraw
    
    %% EXTRACT EPOCHS FROM BINS %%
    EEG = pop_epochbin( EEG , [-200.0  800.0],  'pre');
    setName = [pID '_f_elist_bins_be'];
    EEG.setname = [setName];
    EEG = pop_saveset( EEG, 'filename', [setName '.set'],'filepath',[pDir '/']);
    %[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname',[setName], 'overwrite','on', 'gui','off');
    %eeglab redraw
    
    %% BASIC ARTIFACT DETECTION/REJECTION %%
    %%% EEG  = pop_artmwppth( EEG , 'Channel',  1:64, 'Flag', 1, 'LowPass', 30, 'Threshold', 100, 'Twindow',[ -200 799], 'Windowsize',200, 'Windowstep',100 );
    
    %% ERP AVERAGING %%
    ERP = pop_averager( EEG , 'Criterion', 'good', 'DQ_custom_wins', 0, 'DQ_flag', 0, 'DQ_preavg_txt', 0, 'ExcludeBoundary', 'on' );
    ERP = pop_savemyerp( ERP, 'erpname',[pID], 'filename',[pID '.erp'], 'filepath', [pDir], 'Warning','on');
    erplab redraw
    %EEG = pop_saveset( EEG, 'savemode','resave');
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname',[setName], 'overwrite','on', 'gui','off');
    %eeglab redraw

    %% CLEARS WHOLE STUDY (ALL SETS) %%
    STUDY = []; CURRENTSTUDY = 0; ALLEEG = []; EEG=[]; CURRENTSET=[];
    eeglab redraw
    ALLERP = []; ERP=[];
    erplab redraw

end

disp(['SECTION END: vasic pre-processing complete.'])


%% SINGLE ERP MEASUREMENT PER PARTICIPANT %%

mkdir([studyDir '/_measurements']);

measureName = 'N2_meanAmplitude';

electrodeIndex = input('Enter electrode index... (integer) ')

baseline = 200;
windowStart = 200;
windowEnd = 400;

binFirst = 1;
binLast = 4;


for pN=1:pTotal
    
    pID = '';
	pDir = '';

    pID = pList{pN};
	pDir = [studyDir '/_participants/' pID];
    
    %% LOAD ERPLAB ERP FILE %%
    disp(['pID erpset to import =' pID])
    ERP = pop_loaderp( 'filename',[pID '.erp'], 'filepath',[pDir '/'], 'overwrite','off', 'Warning','off', 'UpdateMainGui','on' );

    %% OUTPUT ERP MEASUREMENTS %%
    electrodeName = convertStringsToChars(string(electrodeNames(1,electrodeIndex)));

    ALLERP = pop_geterpvalues( ERP, [windowStart windowEnd],  binFirst:binLast,  electrodeIndex , 'Baseline', 'pre', 'Binlabel', 'on', 'FileFormat', 'wide', 'Filename',[studyDir '/_measurements/' pID '_' measureName '_' electrodeName '.txt'], 'Fracreplace', 'NaN', 'InterpFactor',  1, 'Measure', 'meanbl', 'Mlabel',[measureName '_' electrodeName], 'PeakOnset',  1,'Resolution',  3 );
    %ERP = pop_savemyerp( ERP, 'erpname', [pID], 'filename', [pID '.erp'], 'filepath', [pDir], 'Warning','on');
    %EEG = pop_saveset( EEG, 'savemode','resave');
    %erplab redraw
    %eeglab redraw


end



%% MULTIPLE ERP MEASUREMENTS PER PARTICIPANT %%

mkdir([studyDir '/_measurements']);

measureName = 'N2_meanAmplitude';

electrodes2measure = {["2Z"],'1LC','1RC'};

baseline = 200;
windowStart = 200;
windowEnd = 400;

binFirst = 1;
binLast = 4;


for pN=1:pTotal
    
    pID = '';
	pDir = '';

    pID = pList{pN};
	pDir = [studyDir '/_participants/' pID];
    
    %% LOAD ERPLAB ERP FILE %%
    disp(['pID erpset to import =' pID])
    ERP = pop_loaderp( 'filename',[pID '.erp'], 'filepath',[pDir '/'], 'overwrite','off', 'Warning','off', 'UpdateMainGui','on' );

    %% OUTPUT ERP MEASUREMENTS %%
    for erpM=1:length(electrodes2measure)

        electrodeIndex = find(strcmp([electrodeNames], electrodes2measure{erpM}));
        electrodeName = convertStringsToChars(string(electrodeNames(1,electrodeIndex)));

        ALLERP = pop_geterpvalues( ERP, [windowStart windowEnd],  binFirst:binLast,  electrodeIndex , 'Baseline', 'pre', 'Binlabel', 'on', 'FileFormat', 'wide', 'Filename',[studyDir '/_measurements/' pID '_' measureName '_' electrodeName '.txt'], 'Fracreplace', 'NaN', 'InterpFactor',  1, 'Measure', 'meanbl', 'Mlabel',[measureName '_' electrodeName], 'PeakOnset',  1,'Resolution',  3 );
        %ERP = pop_savemyerp( ERP, 'erpname', [pID], 'filename', [pID '.erp'], 'filepath', [pDir], 'Warning','on');
        %EEG = pop_saveset( EEG, 'savemode','resave');
        %erplab redraw
        %eeglab redraw
    end

end



%% GLOBAL ERP MEASUREMENTS %%

while CURRENTERP > 0
    ALLERP = pop_deleterpset( ALLERP , 'Erpsets',1, 'Saveas', 'on' );
end

erplab amnesia


measureName = 'N2_meanAmplitude';

electrodeIndex = input('Enter electrode index... (integer) ')

electrodeName = convertStringsToChars(string(electrodeNames(1,electrodeIndex)));

baseline = 200;
windowStart = 200;
windowEnd = 400;

binFirst = 1;
binLast = 4;


for pN=1:pTotal
    
    pID = '';
	pDir = '';

    pID = pList{pN};
	pDir = [studyDir '/_participants/' pID];
    
    %% LOAD ERPLAB ERP FILE %%
    disp(['pID erpset to import =' pID])
    ERP = pop_loaderp( 'filename',[pID '.erp'], 'filepath',[pDir '/'], 'overwrite','off', 'Warning','off', 'UpdateMainGui','on' );
end


ALLERP = pop_geterpvalues(ALLERP, [windowStart windowEnd],  binFirst:binLast,  electrodeIndex , 'Baseline', 'pre', 'Binlabel', 'on', 'Erpsets',  1:pTotal, 'FileFormat', 'wide', 'Filename',[studyDir '/_measurements/' measureName '_' electrodeName '.txt'], 'Fracreplace','NaN', 'InterpFactor', 1, 'Measure','meanbl', 'Mlabel',[measureName '_' electrodeName], 'PeakOnset', 1, 'Resolution', 3);


% CREATE JACKKNIFED DATASETS %
ALLERP = pop_jkgaverager(ALLERP , 'Criterion',100, 'DQ_flag',0, 'Erpname', 'jacked', 'Erpsets',1:pTotal, 'Weighted', 'on' );
ALLERP = pop_geterpvalues(ALLERP, [windowStart windowEnd],  binFirst:binLast,  electrodeIndex , 'Baseline', 'pre', 'Binlabel', 'on', 'Erpsets',  pTotal+1:(pTotal+1)+pTotal, 'FileFormat', 'wide', 'Filename',[studyDir '/_measurements/' measureName '_' electrodeName '_jacked.txt'], 'Fracreplace','NaN', 'InterpFactor', 1, 'Measure','meanbl', 'Mlabel',[measureName '_' electrodeName '_jacked'], 'PeakOnset', 1, 'Resolution', 3);



%% CLEAR ALL ERPSETS %%

while CURRENTERP > 0
    ALLERP = pop_deleterpset( ALLERP , 'Erpsets',1, 'Saveas', 'on' );
end

erplab amnesia



