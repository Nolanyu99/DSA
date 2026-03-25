function plot_path(points, path_idx, titleStr)
%PLOT_PATH  Plot all points and overlay a path (by node indices).
%
% Inputs:
%   points   : table with columns {name, x, y}
%   path_idx : row vector of node indices (1..N), can be empty
%   titleStr : figure title (string/char)

figure;
hold on;
grid on;

% Plot all points
scatter(points.x, points.y, 60, 'filled');

% Label each point (small offset to avoid overlap)
for i = 1:height(points)
    text(points.x(i) + 5, points.y(i) + 5, points.name(i), 'FontSize', 9);
end

% Overlay path
if ~isempty(path_idx)
    px = points.x(path_idx);
    py = points.y(path_idx);
    plot(px, py, '-o', 'LineWidth', 2);
end

xlabel('X (meters)');
ylabel('Y (meters)');
title(titleStr);

axis equal;
hold off;
end