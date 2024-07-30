% Convert .vmkr file to use PsychoPy markers

PsychoPyFile= 'D:\Data\testLibet\Jun26\ND\ND_testLibet4_2024-06-26_12h19.50.643.csv';
MkrFileOrig = 'D:\Data\testLibet\Jun26\ND\ND_test_2024-06-26_12-19-56.vmrk';
MkrFileNew  = strrep(MkrFileOrig,'.vmrk',' - ORIGINAL.vmrk');
MkrFileTemp = strrep(MkrFileOrig,'.vmrk',' - TEMP.vmrk');

T = readtable(PsychoPyFile);
K = T.keypress;
k=2; % skip first line


% Rename original marker file
copyfile(MkrFileOrig,MkrFileNew)


% open marker file and read data
fidIN = fopen(MkrFileOrig);
fidOUT= fopen(MkrFileTemp,'w');
tline = fgetl(fidIN);
while ischar(tline)
    fprintf(fidOUT,'%s\n',tline);
    tline = fgetl(fidIN);
    if(strfind(tline,'Mk'))
        if(strfind(tline,',s0'))
            %tline = strrep(tline,',s0',',XXX');
            kkk = K{k};
            if strcmp(kkk,'L')
                m = '101';
            else
                m = '102';
            end
            tline = strrep(tline,',s0',strcat(',',m));
            k = k+1;
        end
    end
    disp(tline)
    %fprintf(fidOUT,'%s\n',tline);
end
fclose(fidIN);
fclose(fidOUT);


