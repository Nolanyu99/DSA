clear
clc
close all

% Robust path setup
thisFile = mfilename('fullpath');
repoRoot = fileparts(thisFile);
addpath(genpath(fullfile(repoRoot, 'src')));

% Load standardised data
[~, ~, all_points] = load_points_from_task1();

% Restore the original plotting variables/style
names = all_points.name;
type  = all_points.type_code;
x     = all_points.x;
y     = all_points.y;

figure
scatter(x, y, 120, type, 'filled')
text(x + 5, y, names)

title("Real Map of QEOP Landmarks & Signal Points")
xlabel("X (meters)")
ylabel("Y (meters)")

grid on
axis equal
