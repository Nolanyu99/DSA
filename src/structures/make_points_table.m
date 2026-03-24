function [all_points, points, obstacles] = make_points_table()
%MAKE_POINTS_TABLE Build standardised QEOP map tables.
%   all_points : all entities (key points + signal points + obstacles)
%   points     : navigable points only (key + signal)
%   obstacles  : obstacle points only
%
%   Output columns:
%       id, name, type_code, type_label, lat, lon, x, y

    % Origin
    lat0 = 51.537758;
    lon0 = -0.011595;

    lat = [
        51.537758
        51.538559
        51.540135
        51.541436
        51.541705
        51.544739
        51.539375
        51.538155
        51.538448
        51.540971
        51.541118
        51.540071
        51.542018
        51.542883
        51.541214
        51.540413
        51.539566
        51.538739
    ];

    lon = [
        -0.011595
        -0.010013
        -0.011382
        -0.013236
        -0.015492
        -0.019684
        -0.014644
        -0.011495
        -0.010295
        -0.012778
        -0.014240
        -0.015001
        -0.016213
        -0.017918
        -0.019824
        -0.016427
        -0.012644
        -0.012138
    ];

    names = string({
        'Marshgate'
        'OPS'
        'Aquatics Centre'
        'UAL'
        'Climbing Wall'
        'Handball Club'
        'London Stadium'
        'Nine Pillar Bridge Sign'
        'Nine Pillar Bridge Obstacle'
        'Ginger Mint Eastbank'
        'Tallow Bridge'
        'Taverna in the Park'
        'Carpenters Road Lock'
        'Marshgate Lane North'
        'Monier Bridge'
        'Olympic Bell'
        'Potato Dog'
        'ArcelorMittal Orbit'
    });

    % 1 = obstacle, 2 = key point, 3 = signal point
    type_code = [
        2
        2
        2
        2
        2
        2
        2
        3
        1
        3
        3
        3
        3
        3
        3
        3
        3
        3
    ];

    n = numel(lat);
    id = (1:n)';

    % Convert lat/lon to local XY (meters)
    x = zeros(n, 1);
    y = zeros(n, 1);

    for i = 1:n
        x(i) = (lon(i) - lon0) * 111320 * cosd(lat0);
        y(i) = (lat(i) - lat0) * 111320;
    end

    % Type labels
    type_label = strings(n, 1);
    type_label(type_code == 1) = "obstacle";
    type_label(type_code == 2) = "key";
    type_label(type_code == 3) = "signal";

    % Unified master table
    all_points = table( ...
        id, ...
        names(:), ...
        type_code(:), ...
        type_label(:), ...
        lat(:), ...
        lon(:), ...
        x(:), ...
        y(:), ...
        'VariableNames', {'id', 'name', 'type_code', 'type_label', 'lat', 'lon', 'x', 'y'} ...
    );

    % Split tables
    points = all_points(all_points.type_code ~= 1, :);   % key + signal
    obstacles = all_points(all_points.type_code == 1, :);
end
