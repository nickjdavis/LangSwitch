
% Edit these lines - they are specific for my computer!
PsychoPyFile= 'D:\Data\testLibet\Jun26\ND\ND_testLibet4_2024-06-26_12h19.50.643.csv';
DataFolder = 'D:\Data\testLibet\Jun26\ND\';
HeaderFile = 'ND_test_2024-06-26_12-19-56.vhdr';
ChannelLocFile = 'C:\\Users\\Nick\\Documents\\MATLAB\\eeglab\\sample_locs\\standard_waveguard64_duke.elc';


EEG.etc.eeglabvers = 'dev'; % this tracks which version of EEGLAB is being used, you may ignore it
EEG = pop_loadbv(DataFolder, HeaderFile, [1 632796], [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64]);
EEG.setname='ND';
EEG=pop_chanedit(EEG, 'lookup',ChannelLocFile);
EEG = pop_reref( EEG, []);
EEG.setname='ND_rr';
EEG = pop_eegfiltnew(EEG, 'locutoff',0.1,'hicutoff',45);
EEG.setname='ND_rr_f';
EEG = pop_reref( EEG, []);
EEG.setname='ND_rr_f_rr';
eeglab redraw


% update events - experimental!
T = readtable(PsychoPyFile);
K = T.keypress;
% k=2; % skip first line
for i=2:201
    k = K{i};
    EEG.event(i).type = k;
end
EEG.setname='ND_rr_f_rr_mkr';
eeglab redraw


figure; pop_erpimage(EEG,1, [14],[[]],'4L - Right presses',10,1,{ 'R'},[],'type' ,'yerplabel','\muV','erp','on','limits',[NaN NaN -100 250 NaN NaN NaN NaN] ,'cbar','on','topo', { [14] EEG.chanlocs EEG.chaninfo } );
figure; pop_erpimage(EEG,1, [14],[[]],'4L - Left presses',10,1,{ 'L'},[],'type' ,'yerplabel','\muV','erp','on','limits',[NaN NaN -100 250 NaN NaN NaN NaN] ,'cbar','on','topo', { [14] EEG.chanlocs EEG.chaninfo } );
