function [tc, results] = arm_gnu_embedded()
%ARM_GNU_EMBEDDED

% Copyright 2013-2022 The MathWorks, Inc.

toolchain.Platforms  = {computer('arch')};
toolchain.Versions   = {'12.2.1'};
toolchain.Artifacts  = {'gmake'};
toolchain.FuncHandle = str2func('getToolchainInfoFor');
toolchain.ExtraFuncArgs = {};
[tc, results] = coder.make.internal.generateToolchainInfoObjects(mfilename, toolchain);
end

function tc = getToolchainInfoFor(platform, version, artifact, varargin)
% Tool-chain Information
tc = coder.make.ToolchainInfo('BuildArtifact', 'gmake makefile', 'SupportedLanguages', {'Asm/C/C++'});
tc.Name = coder.make.internal.formToolchainName('Arm GNU Toolchain', ...
    platform, version, artifact);
tc.Platform = platform;
tc.setBuilderApplication(platform);

% MATLAB setup
tc.MATLABSetup = 'matlabshared.toolchain.arm_gnu.ArmGnuSetup();';

% Toolchain's attribute
tc.addAttribute('TransformPathsWithSpaces');
tc.addAttribute('RequiresCommandFile');
if any(ismember(platform, {'win64','win32'}))
    tc.addAttribute('RequiresBatchFile');
end

tc.addAttribute('SupportsUNCPaths',     false);
tc.addAttribute('SupportsDoubleQuotes', true);
tc.addAttribute('DoNotUseChecksums', true);

% Add macros
tc.addIntrinsicMacros({'TARGET_LOAD_CMD_ARGS'});
tc.addIntrinsicMacros({'TARGET_LOAD_CMD'});
tc.addIntrinsicMacros({'MW_ARM_GNU_TOOLS_PATH'});
tc.addIntrinsicMacros({'FDATASECTIONS_FLG'});
tc.addMacro('LIBGCC', '${shell $(MW_ARM_GNU_TOOLS_PATH)/arm-none-eabi-gcc ${CFLAGS} -print-libgcc-file-name}');
tc.addMacro('LIBC',   '${shell $(MW_ARM_GNU_TOOLS_PATH)/arm-none-eabi-gcc ${CFLAGS} -print-file-name=libc.a}');
tc.addMacro('LIBM',   '${shell $(MW_ARM_GNU_TOOLS_PATH)/arm-none-eabi-gcc ${CFLAGS} -print-file-name=libm.a}');
tc.addMacro('PRODUCT_NAME_WITHOUT_EXTN','$(basename $(PRODUCT))');
tc.addMacro('PRODUCT_BIN', '$(PRODUCT_NAME_WITHOUT_EXTN).bin');
tc.addMacro('PRODUCT_HEX', '$(PRODUCT_NAME_WITHOUT_EXTN).hex');
tc.addMacro('CPFLAGS', '-O binary');

if any(ismember(platform, {'win64','win32'}))
    % Work around for cygwin, override SHELL variable
    % http://www.gnu.org/software/make/manual/make.html#Choosing-the-Shell
    tc.addMacro('SHELL', '%SystemRoot%/system32/cmd.exe');
end

% Add inline commands
objectExtension = '.o';
depfileExtension = '.dep';

tc.InlinedCommands{1} = ['ALL_DEPS:=$(patsubst %', objectExtension, ',%', depfileExtension, ',$(ALL_OBJS))'];
tc.InlinedCommands{2} = 'all:';
tc.InlinedCommands{3} = '';
tc.InlinedCommands{4} = ['ifndef DISABLE_GCC_FUNCTION_DATA_SECTIONS', 10, 'FDATASECTIONS_FLG := -ffunction-sections -fdata-sections', 10, 'endif'];

% Makefile includes
make = tc.BuilderApplication();
make.IncludeFiles = {'codertarget_assembly_flags.mk', '../codertarget_assembly_flags.mk', '../../codertarget_assembly_flags.mk', 'mw_arm_gnu_tools_path.mk', '../mw_arm_gnu_tools_path.mk', '../../mw_arm_gnu_tools_path.mk','$(ALL_DEPS)'};

% Assembler
assembler = tc.getBuildTool('Assembler');
assembler.setName('GNU ARM Assembler');
assembler.setPath('$(MW_ARM_GNU_TOOLS_PATH)');
% arm-none-eabi-as doesn't process preprocessor directives.
% So using gcc compiler with '-x assembler-with-cpp' option to compile assembly files.
assembler.setCommand('arm-none-eabi-gcc');
assembler.setDirective('IncludeSearchPath', '-I');
assembler.setDirective('PreprocessorDefine', '-D');
assembler.setDirective('OutputFlag', '-o');
assembler.setDirective('Debug', '-g');
assembler.setFileExtension('Source','.s');
assembler.addFileExtension( 'ASMType1Source', coder.make.BuildItem('ASM_Type1_Ext', '.S'));
assembler.setFileExtension('Object', '.o');
assembler.addFileExtension( 'DependencyFile', coder.make.BuildItem('DEP_EXT', depfileExtension));
assembler.DerivedFileExtensions = {depfileExtension};
assembler.InputFileExtensions = {'Source', 'ASMType1Source'};

% Compiler
compiler = tc.getBuildTool('C Compiler');
compiler.setName('GNU ARM C Compiler');
compiler.setPath('$(MW_ARM_GNU_TOOLS_PATH)');
compiler.setCommand('arm-none-eabi-gcc');
compiler.setDirective('CompileFlag', '-c');
compiler.setDirective('PreprocessFile', '-E');
compiler.setDirective('IncludeSearchPath', '-I');
compiler.setDirective('PreprocessorDefine', '-D');
compiler.setDirective('OutputFlag', '-o');
compiler.setDirective('Debug', '-g');
compiler.setFileExtension('Source', '.c');
compiler.setFileExtension('Header', '.h');
compiler.addFileExtension( 'DependencyFile', coder.make.BuildItem('DEP_EXT', depfileExtension));
compiler.DerivedFileExtensions = {depfileExtension};
compiler.setFileExtension('Object', objectExtension);

% C++ compiler
cppompiler = tc.getBuildTool('C++ Compiler');
cppompiler.setName('GNU ARM C++ Compiler');
cppompiler.setPath('$(MW_ARM_GNU_TOOLS_PATH)');
cppompiler.setCommand('arm-none-eabi-g++');
cppompiler.setDirective('CompileFlag', '-c');
cppompiler.setDirective('PreprocessFile', '-E');
cppompiler.setDirective('IncludeSearchPath', '-I');
cppompiler.setDirective('PreprocessorDefine', '-D');
cppompiler.setDirective('OutputFlag', '-o');
cppompiler.setDirective('Debug', '-g');
cppompiler.setFileExtension('Source', '.cpp');
cppompiler.setFileExtension('Header', '.hpp');
cppompiler.setFileExtension('Object', objectExtension);
cppompiler.addFileExtension( 'UnixType1Source', coder.make.BuildItem('UNIX_TYPE1_EXT', '.cc'));
cppompiler.addFileExtension( 'UnixType2Source', coder.make.BuildItem('UNIX_TYPE2_EXT', '.C'));
cppompiler.addFileExtension( 'CPPMiscSource', coder.make.BuildItem('CXX_EXT', '.cxx'));
cppompiler.addFileExtension( 'DependencyFile', coder.make.BuildItem('DEP_EXT', depfileExtension));
cppompiler.DerivedFileExtensions = {depfileExtension};
cppompiler.InputFileExtensions = {'Source', 'UnixType1Source', 'UnixType2Source', 'CPPMiscSource'};

% Linker
linker = tc.getBuildTool('Linker');
linker.setName('GNU ARM Linker');
linker.setPath('$(MW_ARM_GNU_TOOLS_PATH)');
linker.setCommand('arm-none-eabi-g++');
linker.setDirective('Library', '-l');
linker.setDirective('LibrarySearchPath', '-L');
linker.addDirective('LinkerFile', {''});
linker.setDirective('LinkerFile', '-T');
linker.setDirective('OutputFlag', '-o');
linker.setDirective('Debug', '-g');
linker.setFileExtension('Executable', '.elf');
linker.setFileExtension('Shared Library', '.so');
linker.Libraries = {'-lm'};

% C++ Linker
cpplinker = tc.getBuildTool('C++ Linker');
cpplinker.setName('GNU ARM C++ Linker');
cpplinker.setPath('$(MW_ARM_GNU_TOOLS_PATH)');
cpplinker.setCommand('arm-none-eabi-g++');
cpplinker.setDirective('Library', '-l');
cpplinker.setDirective('LibrarySearchPath', '-L');
cpplinker.addDirective('LinkerFile', {''});
cpplinker.setDirective('LinkerFile', '-T');
cpplinker.setDirective('OutputFlag', '-o');
cpplinker.setDirective('Debug', '-g');
cpplinker.setFileExtension('Executable', '.elf');
cpplinker.setFileExtension('Shared Library', '.so');

% Archiver
archiver = tc.getBuildTool('Archiver');
archiver.setName('GNU ARM Archiver');
archiver.setPath('$(MW_ARM_GNU_TOOLS_PATH)');
archiver.setCommand('arm-none-eabi-ar');
archiver.setDirective('OutputFlag', '');
archiver.setFileExtension('Static Library', '.lib');

% ELF to binary converter
postbuildToolName = 'Binary Converter';
postbuild = tc.addPostbuildTool(postbuildToolName);
postbuild.setCommand('OBJCOPY', 'arm-none-eabi-objcopy');     % Command macro & value
postbuild.setPath('OBJCOPYPATH','$(MW_ARM_GNU_TOOLS_PATH)');
postbuild.OptionsRegistry = {postbuildToolName, 'OBJCOPYFLAGS_BIN'}; % Tool options
postbuild.SupportedOutputs = {coder.make.enum.BuildOutput.EXECUTABLE}; % Output type from tool
tc.addBuildConfigurationOption(postbuildToolName, postbuild);
tc.setBuildConfigurationOption('all', postbuildToolName, '-O binary $(PRODUCT) $(PRODUCT_BIN)');

% ELF to hex converter
postbuildToolName = 'Hex Converter';
postbuild = tc.addPostbuildTool(postbuildToolName);
postbuild.setCommand('OBJCOPY', 'arm-none-eabi-objcopy');     % Command macro & value
postbuild.setPath('OBJCOPYPATH','$(MW_ARM_GNU_TOOLS_PATH)');
postbuild.OptionsRegistry = {postbuildToolName, 'OBJCOPYFLAGS_HEX'}; % Tool options
postbuild.SupportedOutputs = {coder.make.enum.BuildOutput.EXECUTABLE}; % Output type from tool
tc.addBuildConfigurationOption(postbuildToolName, postbuild);
tc.setBuildConfigurationOption('all', postbuildToolName, '-O ihex $(PRODUCT) $(PRODUCT_HEX)');

% Size of ELF
postbuildToolName = 'Executable Size';
postbuild = tc.addPostbuildTool(postbuildToolName);
postbuild.setCommand('EXESIZE', 'arm-none-eabi-size');     % Command macro & value
postbuild.setPath('EXESIZEPATH','$(MW_ARM_GNU_TOOLS_PATH)');
postbuild.OptionsRegistry = {postbuildToolName, 'EXESIZE_FLAGS'}; % Tool options
postbuild.SupportedOutputs = {coder.make.enum.BuildOutput.EXECUTABLE}; % Output type from tool
tc.addBuildConfigurationOption(postbuildToolName, postbuild);
tc.setBuildConfigurationOption('all', postbuildToolName, '$(PRODUCT)');

%% Build Configurations
optimsOffOpts = {'-O0'};
optimsOnOpts = {'-O3'};
cCompilerOpts = {};%{'-std=c99'};
cppCompilerOpts = {...
    '-std=gnu++14', ...								% ANSI standard
    '-fno-rtti', ...								% Disable generation of information about every class with virtual functions for use by the C++ run-time type identification features
    '-fno-exceptions', ...							% Stops generating extra code needed to propagate exceptions, which can produce significant data size overhead
    };
% r[ab][f][u]  - replace existing or insert new file(s) into the archive
% [v]          - be verbose
% [s]          - create an archive index (cf. ranlib)
archiverOpts = {'ruvs'};
GenMakeDependenciesString = ['-MMD -MP -MF"$(@:%', objectExtension, '=%', depfileExtension, ')" -MT"$@" '];

compilerOpts = {...
    '$(FDATASECTIONS_FLG)', ...
    '-Wall',...
    GenMakeDependenciesString,...                   % make dependency files
    tc.getBuildTool('C Compiler').getDirective('CompileFlag')...
    };

assemblerOpts = {...
    GenMakeDependenciesString, ...                  % make dependency files
    '-Wall', ...
    '-x assembler-with-cpp', ...                    % Enable preprocessing for assembly files
    '$(ASFLAGS_ADDITIONAL)', ...                    % Assembly flags from codertarget
    '$(DEFINES)', ...
    '$(INCLUDES)', ...
    tc.getBuildTool('C Compiler').getDirective('CompileFlag')...
    };

linkerOpts = { ...
    '-Wl,--gc-sections', ...
    '-Wl,-Map="$(PRODUCT_NAME).map"',... %'-nostartfiles', ... %'-nodefaultlibs',...
    };

% Get the debug flag per build tool
debugFlag.CCompiler   = '-g';
debugFlag.Linker      = '-g';
debugFlag.Archiver    = '';

cfg = tc.getBuildConfiguration('Faster Builds');
cfg.setOption('Assembler',  	horzcat(assemblerOpts));
cfg.setOption('C Compiler', 	horzcat(cCompilerOpts, compilerOpts, optimsOffOpts));
cfg.setOption('Linker',     	linkerOpts);
cfg.setOption('C++ Compiler', 	horzcat(cppCompilerOpts, compilerOpts, optimsOffOpts));
cfg.setOption('C++ Linker',     linkerOpts);
cfg.setOption('Archiver',   	archiverOpts);

cfg = tc.getBuildConfiguration('Faster Runs');
cfg.setOption('Assembler',  	horzcat(assemblerOpts));
cfg.setOption('C Compiler', 	horzcat(cCompilerOpts, compilerOpts, optimsOnOpts));
cfg.setOption('Linker',     	linkerOpts);
cfg.setOption('C++ Compiler', 	horzcat(cppCompilerOpts, compilerOpts, optimsOnOpts));
cfg.setOption('C++ Linker',     linkerOpts);
cfg.setOption('Archiver',   	archiverOpts);

cfg = tc.getBuildConfiguration('Debug');
cfg.setOption('Assembler',  	horzcat(assemblerOpts, debugFlag.CCompiler));
cfg.setOption('C Compiler', horzcat(cCompilerOpts, compilerOpts, optimsOffOpts, debugFlag.CCompiler));
cfg.setOption('Linker',     horzcat(linkerOpts, debugFlag.Linker));
cfg.setOption('C++ Compiler', 	horzcat(cppCompilerOpts, compilerOpts, optimsOffOpts, debugFlag.CCompiler));
cfg.setOption('C++ Linker',     horzcat(linkerOpts, debugFlag.Linker));
cfg.setOption('Archiver',   horzcat(archiverOpts, debugFlag.Archiver));

tc.setBuildConfigurationOption('all', 'Make Tool', '-f $(MAKEFILE)');
makeTool = tc.BuilderApplication;
makeTool.setDirective('DeleteCommand', '@del /f/q');
end

% LocalWords:  gmake Asm matlabshared toolchain Toolchain's FDATASECTIONS FLG depfileExtension
% LocalWords:  LIBGCC eabi CFLAGS libgcc LIBC libc LIBM libm CPFLAGS cygwin dep optimsOffOpts
% LocalWords:  DEPS patsubst OBJS ffunction fdata codertarget CXX cxx lm optimsOnOpts
% LocalWords:  OBJCOPYPATH OBJCOPYFLAGS ihex EXESIZE EXESIZEPATH fno rtti
% LocalWords:  ranlib ruvs MMD MF tc preprocessing ASFLAGS Wl nostartfiles
% LocalWords:  nodefaultlibs CCompiler del
