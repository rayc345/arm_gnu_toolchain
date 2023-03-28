function addr = getSymbolAddress(application, symbols)
%getSymbolAddress Return addresses of given symbols from application (ELF file)
% Use objdump utility to get the addresses of the symbols from the
% application file in ELF format. 
% 

% Copyright 2015-2017 The MathWorks, Inc.

[applicationPath, applicationName] = fileparts(application);
rootDir = matlabshared.toolchain.gnu_gcc_arm.getGnuArmToolsDir();
objDump = fullfile(rootDir, 'bin', 'arm-none-eabi-objdump.exe');
symbolTable = fullfile(applicationPath, [applicationName, '.tbl']);
cmd = ['"' objDump '" -t "' application '" > "' symbolTable '"'];
[status, msg] = system(cmd);
if (status ~= 0)
    error('a:b', 'Error creating symbol table: %s', msg);
end
fid = fopen(symbolTable, 'r');
if (fid < 0)
    error('a:b', 'Error opening symbol table: %s', symbolTable);
end
cFclose = onCleanup(@()fclose(fid));

% Find symbols we are looking for
if ischar(symbols)
    symbols = {symbols};
end
% Remove trailing and leading white spaces
symbols = strtrim(symbols);

done = false;
addr = cell(size(symbols));
while (~done)
    tline = fgetl(fid);
    if ~ischar(tline)
        break;
    end
    
    splitstr = regexp(strtrim(tline), '\s+', 'split');
    matches = cellfun(@(x)strcmp(splitstr,x), symbols,'UniformOutput',false);
    tmp = cellfun(@(x)any(x),matches);
    if any(tmp)
        thisAddr = regexp(tline, '^([\dabcdef]+)\s+', 'tokens', 'once');
        addr{tmp} = thisAddr{1};
    end
end

end

