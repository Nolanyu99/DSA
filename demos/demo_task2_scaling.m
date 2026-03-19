clear; clc;
addpath(genpath("src"));

% DEMO_TASK2_SCALING
% This script evaluates how nearest-neighbour lookup time scales with the
% number of points.
%
% Methods compared:
%   (1) Linear scan baseline (list_nearest)
%   (2) KD-tree lookup (kdtree_build + kdtree_nearest)
%
% Notes:
%   - The real dataset contains a small number of points (key + signal).
%   - To test scalability, we replicate the point set by a scale factor and
%     add a small random jitter to avoid exact duplicates.
%   - We report the MEDIAN per-query time over multiple repeats to reduce
%     timing noise, and include a short warm-up to reduce JIT/caching effects.

% Load real navigable points (key + signal)
[points, ~] = load_points_from_task1();

% Fixed query set inside the real bounding box
Q = 3000;
xmin = min(points.x); xmax = max(points.x);
ymin = min(points.y); ymax = max(points.y);
qx = xmin + (xmax - xmin) * rand(Q,1);
qy = ymin + (ymax - ymin) * rand(Q,1);

% Scale factors (replicate the point set)
scales = [1, 10, 50, 200];

% Small noise (meters) to avoid degenerate duplicates
jitter_sigma = 0.5;

% Repeat measurements and use the median to reduce noise
R = 7;

fprintf("Scaling benchmark (nearest neighbour)\n");
fprintf("Queries fixed at Q=%d | repeats per scale R=%d (median)\n\n", Q, R);
fprintf("%10s %18s %18s %10s\n", "Npoints", "List med (s)", "KD med (s)", "Speedup");

for s = scales
    % Replicate points s times with small random jitter
    P = repmat(points, s, 1);
    P.id = (1:height(P))';

    P.x = P.x + jitter_sigma * randn(height(P),1);
    P.y = P.y + jitter_sigma * randn(height(P),1);

    % Build KD-tree for this scaled set (build cost excluded from query timing)
    tree = kdtree_build(P);

    % Warm-up (reduce JIT/caching effects on the first timing)
    for i = 1:50
        list_nearest(P, qx(i), qy(i));
        kdtree_nearest(tree, qx(i), qy(i));
    end

    % Timed repeats (per-query average times)
    list_avg = zeros(R,1);
    kd_avg   = zeros(R,1);

    for r = 1:R
        t1 = tic;
        for i = 1:Q
            list_nearest(P, qx(i), qy(i));
        end
        list_avg(r) = toc(t1) / Q;

        t2 = tic;
        for i = 1:Q
            kdtree_nearest(tree, qx(i), qy(i));
        end
        kd_avg(r) = toc(t2) / Q;
    end

    list_med = median(list_avg);
    kd_med   = median(kd_avg);

    fprintf("%10d %18.6e %18.6e %10.2f\n", height(P), list_med, kd_med, list_med/kd_med);
end