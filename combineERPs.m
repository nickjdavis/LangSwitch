function combineERPs (folder)

outText = [];

dirin = cd;
cd(folder);
d = dir();

gotHeader= 0;

for i=1:length(d)
    if d(i).isdir
        dirname = d(i).name;
        if strcmp(dirname(1),'.')
            % do nothing
        else
            %disp(dirname)
            ERPfile = dir(strcat(dirname,'\','*_Amps.txt'));
            if ~isempty(ERPfile)
                fid = fopen(strcat(dirname,'\',ERPfile.name));
                L = fgetl(fid);
                if gotHeader==0
                    outText = [outText, sprintf('%s\n',L)];
                    gotHeader = 1;
                end
                L = fgetl(fid);
                outText = [outText, sprintf('%s\n',L)];
                fclose(fid);
            end
        end
    end
end

disp(outText)

cd(dirin)


