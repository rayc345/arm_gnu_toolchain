function rtwTargetInfo(tr)
%RTWTARGETINFO Registration file for GNU Arm toolchain

% Copyright 2013-2022 The MathWorks, Inc.

% Register GNU Tools for Arm Embedded Processors toolchain
tr.registerTargetInfo(@loc_createToolchain);

end

% -------------------------------------------------------------------------
% Create the ToolchainInfoRegistry entries
% -------------------------------------------------------------------------
function config = loc_createToolchain
sys_arch = computer('arch');
rootDir = fileparts(mfilename('fullpath'));
tcFileName = fullfile(rootDir, ['arm_gnu_embedded_gmake_' sys_arch '_v12.2.1.mat']);
config = coder.make.ToolchainInfoRegistry.empty;
if isfile(tcFileName)
    config = coder.make.ToolchainInfoRegistry; % Initialize
    config(end).Name           = 'Arm GNU Toolchain';
    config(end).Alias          = ['ARM_GNU_' upper(sys_arch)]; % internal use only
    config(end).FileName       = tcFileName;
    config(end).TargetHWDeviceType = {'*'};
    config(end).Platform           = {sys_arch};
end

end

% LocalWords:  gmake
