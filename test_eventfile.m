function test_eventfile (eventfile)

% open files
outfile = strrep(eventfile,'.txt','_edited.txt');
fidIN = fopen(eventfile);
fidOUT= fopen(outfile,'w');

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
        % replace NaN with succeeding number
        ecodeloc = strfind(tline,'NaN');
        pre = tline(1:(ecodeloc-1));
        post = tline((ecodeloc+3):end);
        % need to parse 'post' to get new code
        comma = strfind(post,',');
        precomma = post(2:comma-1);
        if length(precomma)==1
            % just corr/incorr
            newcode = strcat(precomma,precomma,precomma);
        else
            newcode = precomma;
        end
        newline = strcat({pre},newcode,post);
        tline = newline{:};
        fprintf(fidOUT,'%s\n',tline);
    end
    disp(tline)
    tline = fgetl(fidIN);
end
fclose(fidIN);
fclose(fidOUT);

