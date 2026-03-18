clear; clc;
addpath(genpath("src"));

% DEMO_TASK2_LOOKUP
% This script benchmarks nearest-neighbour lookup using:
%   (1) a linear scan baseline (list_nearest)
%   (2) a KD-tree (kdtree_build + kdtree_nearest)
%
% The dataset is loaded from task1.m via load_points_from_task1().

% Load navigable points (key + signal). Obstacles are not used here.
[points, ~] = load_points_from_task1();

% Build KD-tree once (build cost is not included in per-query timing here)
tree = kdtree_build(points);

% Generate random query points within the bounding box of the dataset
N = 5000;
xmin = min(points.x); xmax = max(points.x);
ymin = min(points.y); ymax = max(points.y);

qx = xmin + (xmax - xmin) * rand(N,1);
qy = ymin + (ymax - ymin) * rand(N,1);

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
fprintf("Points (key+signal): %d\n", height(points));
fprintf("Queries: %d\n", N);
fprintf("List scan: total %.6f s | avg %.6e s/query\n", t_list, t_list/N);
fprintf("KD-tree  : total %.6f s | avg %.6e s/query\n", t_kd, t_kd/N);
fprintf("Speedup  : %.2fx\n", t_list / t_kd);