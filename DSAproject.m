%% QEOP Map Visualisation (Fused Version)
%  Display-friendly map for Task 1
%  - Keeps the improved GPS-track visual style
%  - Still uses load_points_from_task1() as the standard data interface
%  - Does NOT break Task 2 structure

clear;
clc;
close all;

%% 0. Robust path setup
thisFile = mfilename('fullpath');
repoRoot = fileparts(thisFile);
addpath(genpath(fullfile(repoRoot, 'src')));

%% 1. Load standardised landmark data from Task 1 interface
% Expected output from load_points_from_task1():
%   points     : key + signal points
%   obstacles  : obstacle points
%   all_points : all map entities
[points, obstacles, all_points] = load_points_from_task1();

% Category indices based on the standard type_code convention:
%   1 = obstacle, 2 = key point, 3 = signal point
key_idx      = find(all_points.type_code == 2);
signal_idx   = find(all_points.type_code == 3);
obstacle_idx = find(all_points.type_code == 1);

% Waiting points (keep your team's visual emphasis)
waiting_idx = find(ismember(string(all_points.name), ["Marshgate", "OPS", "One Pool Street"]));

% Use Marshgate as origin (consistent with earlier versions)
originIdx = find(string(all_points.name) == "Marshgate", 1);
if isempty(originIdx)
    error('Cannot find "Marshgate" in all_points. Please check make_points_table.m');
end

lat0 = all_points.lat(originIdx);
lon0 = all_points.lon(originIdx);

m_per_deg_lat = 111320;
m_per_deg_lon = 111320 * cosd(lat0);

% Landmark XY from standard table
lm_x = all_points.x;
lm_y = all_points.y;

%% 2. Try to load GPS track from dsa.mat
track_x = [];
track_y = [];
smooth_x = [];
smooth_y = [];
all_t = [];

candidateMatFiles = {
    fullfile(repoRoot, 'dsa.mat')
    fullfile(repoRoot, 'demos', 'dsa.mat')
};

matPath = '';
for k = 1:numel(candidateMatFiles)
    if exist(candidateMatFiles{k}, 'file')
        matPath = candidateMatFiles{k};
        break;
    end
end

if ~isempty(matPath)
    try
        S = load(matPath);
        pos = localFindPositionData(S);

        [all_lat, all_lon, all_alt, all_t] = localExtractTrackColumns(pos);

        track_x = (all_lon - lon0) * m_per_deg_lon;
        track_y = (all_lat - lat0) * m_per_deg_lat;

        % Smooth the GPS track
        if numel(track_x) >= 4 && numel(track_y) >= 4
            [t_unique, ia] = unique(all_t);
            tx = track_x(ia);
            ty = track_y(ia);

            if numel(t_unique) >= 4
                t_fine = linspace(t_unique(1), t_unique(end), numel(t_unique) * 5);
                smooth_x = interp1(t_unique, tx, t_fine, 'spline');
                smooth_y = interp1(t_unique, ty, t_fine, 'spline');
            else
                smooth_x = track_x;
                smooth_y = track_y;
            end
        else
            smooth_x = track_x;
            smooth_y = track_y;
        end

        fprintf('Loaded %d GPS points from %s\n', numel(track_x), matPath);

    catch ME
        warning('Could not use dsa.mat for GPS track overlay: %s', ME.message);
        track_x = [];
        track_y = [];
        smooth_x = [];
        smooth_y = [];
        all_t = [];
    end
else
    warning('No dsa.mat found in repo root or demos/. Plotting landmarks only.');
end

%% 3. Build a simple occupancy grid (for saving / downstream reference)
% Grid coding:
%   0 = free
%   1 = key point
%   2 = signal point
%   3 = obstacle
res = 1;      % 1 meter / cell
pad = 50;     % padding around occupied region

if isempty(track_x)
    all_x_for_grid = lm_x(:);
    all_y_for_grid = lm_y(:);
else
    all_x_for_grid = [lm_x(:); track_x(:)];
    all_y_for_grid = [lm_y(:); track_y(:)];
end

xr = [floor(min(all_x_for_grid)) - pad, ceil(max(all_x_for_grid)) + pad];
yr = [floor(min(all_y_for_grid)) - pad, ceil(max(all_y_for_grid)) + pad];

cols = ceil((xr(2) - xr(1)) / res) + 1;
rows = ceil((yr(2) - yr(1)) / res) + 1;

G = zeros(rows, cols, 'uint8');

% Write point categories into the grid
for i = key_idx(:)'
    [r, c] = localXYToRC(lm_x(i), lm_y(i), xr, yr, res, rows, cols);
    G(r, c) = uint8(1);
end

for i = signal_idx(:)'
    [r, c] = localXYToRC(lm_x(i), lm_y(i), xr, yr, res, rows, cols);
    G(r, c) = uint8(2);
end

for i = obstacle_idx(:)'
    [r, c] = localXYToRC(lm_x(i), lm_y(i), xr, yr, res, rows, cols);
    G(r, c) = uint8(3);
end

%% 4. Plot (keep teammate's improved visual style)
figure('Position', [50 50 1200 900], 'Color', 'k');
hold on;
set(gca, 'Color', 'k', 'XColor', 'w', 'YColor', 'w');

% Smooth walking path
if ~isempty(smooth_x)
    plot(smooth_x, smooth_y, '-', 'Color', [0.25 0.5 1], 'LineWidth', 2.5);
end

% Optional dashed arc: Orbit -> Marshgate
idxOrbit = find(string(all_points.name) == "ArcelorMittal Orbit", 1);
idxMarsh = find(string(all_points.name) == "Marshgate", 1);

if ~isempty(idxOrbit) && ~isempty(idxMarsh)
    arc_t = linspace(0, 1, 50);
    ox = lm_x(idxOrbit); oy = lm_y(idxOrbit);
    mx = lm_x(idxMarsh); my = lm_y(idxMarsh);

    mid_x = (ox + mx) / 2 + 20;
    mid_y = (oy + my) / 2;

    bezier_x = (1 - arc_t).^2 * ox + 2 * (1 - arc_t) .* arc_t * mid_x + arc_t.^2 * mx;
    bezier_y = (1 - arc_t).^2 * oy + 2 * (1 - arc_t) .* arc_t * mid_y + arc_t.^2 * my;

    plot(bezier_x, bezier_y, '--', 'Color', [0.25 0.5 1 0.5], 'LineWidth', 1.5);
end

% Key points (cyan)
for i = key_idx(:)'
    plot(lm_x(i), lm_y(i), 'o', ...
        'MarkerSize', 12, ...
        'MarkerFaceColor', 'c', ...
        'MarkerEdgeColor', 'w');
    text(lm_x(i) + 8, lm_y(i), string(all_points.name(i)), ...
        'FontSize', 8, ...
        'FontWeight', 'bold', ...
        'Color', 'c');
end

% Signal points (yellow)
for i = signal_idx(:)'
    plot(lm_x(i), lm_y(i), 'o', ...
        'MarkerSize', 10, ...
        'MarkerFaceColor', 'y', ...
        'MarkerEdgeColor', 'w');
    text(lm_x(i) + 8, lm_y(i), string(all_points.name(i)), ...
        'FontSize', 7, ...
        'Color', 'y');
end

% Waiting points (red square outline)
for i = waiting_idx(:)'
    plot(lm_x(i), lm_y(i), 's', ...
        'MarkerSize', 16, ...
        'MarkerEdgeColor', 'r', ...
        'LineWidth', 2);
end

% Obstacles (orange X)
for i = obstacle_idx(:)'
    plot(lm_x(i), lm_y(i), 'x', ...
        'MarkerSize', 14, ...
        'Color', [1 0.4 0], ...
        'LineWidth', 2.5);
    text(lm_x(i) + 8, lm_y(i), string(all_points.name(i)), ...
        'FontSize', 8, ...
        'FontWeight', 'bold', ...
        'Color', [1 0.4 0]);
end

% Raw GPS dots (faint)
if ~isempty(track_x)
    plot(track_x, track_y, '.', 'Color', [0.3 0.3 0.5], 'MarkerSize', 3);
end

% Legend
h1 = plot(NaN, NaN, 'o', 'MarkerSize', 10, 'MarkerFaceColor', 'c', 'MarkerEdgeColor', 'w');
h2 = plot(NaN, NaN, 'o', 'MarkerSize', 8, 'MarkerFaceColor', 'y', 'MarkerEdgeColor', 'w');
h3 = plot(NaN, NaN, 's', 'MarkerSize', 12, 'MarkerEdgeColor', 'r', 'LineWidth', 2);
h4 = plot(NaN, NaN, 'x', 'MarkerSize', 10, 'Color', [1 0.4 0], 'LineWidth', 2);
h5 = plot(NaN, NaN, '-', 'Color', [0.25 0.5 1], 'LineWidth', 2);

legend([h1 h2 h3 h4 h5], ...
    {sprintf('Key Points (%d)', numel(key_idx)), ...
     sprintf('Signal Points (%d)', numel(signal_idx)), ...
     sprintf('Waiting Points (%d)', numel(waiting_idx)), ...
     sprintf('Obstacles (%d)', numel(obstacle_idx)), ...
     'GPS Track'}, ...
    'Location', 'northwest', ...
    'TextColor', 'w', ...
    'Color', [0.15 0.15 0.15]);

title('Real Map of QEOP Landmarks & Signal Points', ...
    'FontSize', 14, ...
    'FontWeight', 'bold', ...
    'Color', 'w');

xlabel('X (meters)', 'Color', 'w');
ylabel('Y (meters)', 'Color', 'w');

axis equal tight;
grid on;
set(gca, 'GridColor', [0.25 0.25 0.25]);
hold off;

%% 5. Save merged map data
save(fullfile(repoRoot, 'qeop_map_data.mat'), ...
    'G', ...
    'points', 'obstacles', 'all_points', ...
    'lm_x', 'lm_y', ...
    'key_idx', 'signal_idx', 'waiting_idx', 'obstacle_idx', ...
    'track_x', 'track_y', 'smooth_x', 'smooth_y', ...
    'res', 'xr', 'yr', 'lat0', 'lon0');

fprintf('Done! ');
if isempty(track_x)
    fprintf('Landmark-only plot saved. Grid: %dx%d\n', rows, cols);
else
    fprintf('%d GPS points -> smooth path, Grid: %dx%d\n', numel(track_x), rows, cols);
end

%% ===== Local helper functions =====

function pos = localFindPositionData(S)
% Try common patterns first
    if isfield(S, 'Position')
        pos = S.Position;
        return;
    end

    if isfield(S, 'sensorlog') && isstruct(S.sensorlog) && isfield(S.sensorlog, 'Position')
        pos = S.sensorlog.Position;
        return;
    end

    % Search any timetable/table with latitude & longitude columns
    fns = fieldnames(S);
    for ii = 1:numel(fns)
        v = S.(fns{ii});

        if istimetable(v) || istable(v)
            names = lower(string(v.Properties.VariableNames));
            if any(names == "latitude" | names == "lat") && any(names == "longitude" | names == "lon")
                pos = v;
                return;
            end
        end

        if isstruct(v) && isfield(v, 'Position')
            pos = v.Position;
            return;
        end
    end

    error('Cannot find Position timetable/table in dsa.mat');
end

function [lat, lon, alt, tsec] = localExtractTrackColumns(pos)
% Extract latitude, longitude, altitude and time in seconds

    if ~(istimetable(pos) || istable(pos))
        error('Position data must be a timetable or table.');
    end

    varNames = string(pos.Properties.VariableNames);
    lowerNames = lower(varNames);

    latName = localPickName(varNames, lowerNames, ["latitude", "lat"]);
    lonName = localPickName(varNames, lowerNames, ["longitude", "lon"]);
    altName = localPickName(varNames, lowerNames, ["altitude", "alt"], true);
    timeName = localPickName(varNames, lowerNames, ["timestamp", "time"], true);

    lat = pos.(latName);
    lon = pos.(lonName);

    if isempty(altName)
        alt = zeros(size(lat));
    else
        alt = pos.(altName);
    end

    if istimetable(pos)
        rt = pos.Properties.RowTimes;
        if isdatetime(rt)
            tsec = seconds(rt - rt(1));
        elseif isduration(rt)
            tsec = seconds(rt - rt(1));
        else
            tsec = (0:height(pos)-1).';
        end
    elseif ~isempty(timeName)
        tv = pos.(timeName);
        if isdatetime(tv)
            tsec = seconds(tv - tv(1));
        elseif isduration(tv)
            tsec = seconds(tv - tv(1));
        elseif isnumeric(tv)
            tsec = double(tv) - double(tv(1));
        else
            tsec = (0:height(pos)-1).';
        end
    else
        tsec = (0:height(pos)-1).';
    end

    lat = double(lat(:));
    lon = double(lon(:));
    alt = double(alt(:));
    tsec = double(tsec(:));
end

function nameOut = localPickName(varNames, lowerNames, candidates, optional)
    if nargin < 4
        optional = false;
    end

    idx = find(ismember(lowerNames, lower(candidates)), 1);
    if isempty(idx)
        if optional
            nameOut = "";
            return;
        else
            error('Required variable not found. Expected one of: %s', strjoin(candidates, ', '));
        end
    end
    nameOut = varNames(idx);
end

function [r, c] = localXYToRC(x, y, xr, yr, res, rows, cols)
% Convert XY in meters to row/col index in occupancy grid
    c = floor((x - xr(1)) / res) + 1;
    r_cart = floor((y - yr(1)) / res) + 1;

    % Convert Cartesian y-up to matrix row index y-down
    r = rows - r_cart + 1;

    % Clamp
    c = max(1, min(cols, c));
    r = max(1, min(rows, r));
end
