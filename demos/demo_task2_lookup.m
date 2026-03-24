clear;
clc;

% Robust path setup
thisFile = mfilename('fullpath');
repoRoot = fileparts(fileparts(thisFile));   % demos -> repo root
addpath(genpath(fullfile(repoRoot, 'src')));

% DEMO_TASK2_LOOKUP
% Benchmark nearest-neighbour lookup using:
%   (1) linear scan baseline (list_nearest)
%   (2) a KD-tree (kdtree_build + kdtree_nearest)

rng(1);

% Load navigable points only (key + signal)
[points, ~] = load_points_from_task1();

% Sanity checks
assert(istable(points), 'load_points_from_task1() must return a table.');
assert(all(ismember({'id', 'name', 'x', 'y'}, points.Properties.VariableNames)), ...
    'Returned table must contain id, name, x, y columns.');

% Build KD-tree
tree = kdtree_build(points);

% Generate random query points in the bounding box
N = 5000;
xmin = min(points.x);
xmax = max(points.x);
ymin = min(points.y);
ymax = max(points.y);

qx = xmin + (xmax - xmin) * rand(N, 1);
qy = ymin + (ymax - ymin) * rand(N, 1);

% --- Baseline: linear scan ---
t1 = tic;
for i = 1:N
    list_nearest(points, qx(i), qy(i));
end
t_list = toc(t1);

% --- KD-tree ---
t2 = tic;
for i = 1:N
    kdtree_nearest(tree, qx(i), qy(i));
end
t_kd = toc(t2);

% Print timing results
fprintf('=== Task 2 Lookup Benchmark ===\n');
fprintf('Points (key + signal): %d\n', height(points));
fprintf('Queries              : %d\n', N);
fprintf('List scan: total %.6f s | avg %.6e s/query\n', t_list, t_list / N);
fprintf('KD-tree  : total %.6f s | avg %.6e s/query\n', t_kd, t_kd / N);
fprintf('Speedup  : %.2fx\n', t_list / t_kd);
