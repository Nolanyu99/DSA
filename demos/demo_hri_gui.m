clear
clc
close all

thisFile = mfilename('fullpath');
repoRoot = fileparts(fileparts(thisFile));
addpath(genpath(fullfile(repoRoot, 'src')));

robot_hri_gui();
