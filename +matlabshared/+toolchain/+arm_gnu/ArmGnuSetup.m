function ArmGnuSetup()
%ARMGNUSETUP Add Arm GNU GCC compiler path to an environment variable named
%"MW_ARM_GNU_TOOLS_PATH"

%   Copyright 2016 The MathWorks, Inc.

rootDir = matlabshared.toolchain.gnu_gcc_arm.getGnuArmToolsDir();
createToolchainPathMakefile('MW_ARM_GNU_TOOLS_PATH', rootDir);

end

function createToolchainPathMakefile(makefileTokenName, rootDir)
% Do not change order of the following functions
fileName = 'mw_arm_gnu_tools_path.mk';
buildDir = pwd;
[fid,errMsg] = fopen(fullfile(buildDir,fileName), 'w');
if (isequal(fid, -1))
    error(message('codertarget:build:AssemblyFlagsFileError',fileName,errMsg));
end
fidCleanup = onCleanup(@() fclose(fid));
rootDir = fullfile(rootDir,'bin');
if ispc
    rootDir = strrep(rootDir, '\', '/');
end
fprintf(fid,'%s = %s',makefileTokenName,rootDir);
end
