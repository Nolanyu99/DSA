clear;
clc;

%% Load data
load('dsa.mat');

% Position
if exist('Position', 'var')
    pos = Position;
else
    error('Position timetable not found in dsa.mat');
end

% Angular velocity
if exist('AngularVelocity', 'var')
    angVel = AngularVelocity;
else
    error('AngularVelocity timetable not found in dsa.mat');
end

%% Parameters (you can tune these)
speed_th = 0.55;          % m/s, below this is "slow / near stop"
min_stop_sec = 5;         % minimum duration for a candidate stop
expand_sec = 2;           % expand window a bit when checking angular velocity
max_radius_m = 10;         % max spatial spread during a landmark event
min_turns =2.3;          % at least this many turns to count as landmark marking

%% Extract Position data
tPos = pos.Properties.RowTimes;
lat = double(pos.latitude(:));
lon = double(pos.longitude(:));
spd = double(pos.speed(:));

% Use first point as local origin for movement-radius calculation
lat_ref = lat(1);
lon_ref = lon(1);

x = (lon - lon_ref) * 111320 * cosd(lat_ref);
y = (lat - lat_ref) * 111320;

%% Extract AngularVelocity data
tW = angVel.Properties.RowTimes;
wx = double(angVel.X(:));
wy = double(angVel.Y(:));
wz = double(angVel.Z(:));

%% Find low-speed segments
isSlow = spd < speed_th;

d = diff([false; isSlow; false]);
segStart = find(d == 1);
segEnd   = find(d == -1) - 1;

fprintf('Found %d low-speed candidate segments.\n\n', numel(segStart));

eventCount = 0;

for k = 1:numel(segStart)
    i1 = segStart(k);
    i2 = segEnd(k);

    t1 = tPos(i1);
    t2 = tPos(i2);
    dur = seconds(t2 - t1);

    if dur < min_stop_sec
        continue;
    end

    % Spatial spread during low-speed segment
    xSeg = x(i1:i2);
    ySeg = y(i1:i2);
    xc = mean(xSeg);
    yc = mean(ySeg);
    radius = max(sqrt((xSeg - xc).^2 + (ySeg - yc).^2));

    if radius > max_radius_m
        continue;
    end

    % Expanded time window for angular velocity check
    tw1 = t1 - seconds(expand_sec);
    tw2 = t2 + seconds(expand_sec);

    idxW = (tW >= tw1) & (tW <= tw2);

    if nnz(idxW) < 5
        continue;
    end

    tLocal = seconds(tW(idxW) - tW(find(idxW,1)));
    wxSeg = wx(idxW);
    wySeg = wy(idxW);
    wzSeg = wz(idxW);

    % Integrate absolute angular velocity to get total rotation angle
    rotX = trapz(tLocal, abs(wxSeg));
    rotY = trapz(tLocal, abs(wySeg));
    rotZ = trapz(tLocal, abs(wzSeg));

    rotAll = [rotX, rotY, rotZ];
    [rotMax, axisIdx] = max(rotAll);

    % Assume angular velocity is in rad/s
    turns = rotMax / (2*pi);

    if turns >= min_turns
        eventCount = eventCount + 1;

        axisName = ['X','Y','Z'];
        axisName = axisName(axisIdx);

        latMean = mean(lat(i1:i2));
        lonMean = mean(lon(i1:i2));

        fprintf('Event %d\n', eventCount);
        fprintf('  Time window     : %s  ->  %s\n', string(t1), string(t2));
        fprintf('  Duration        : %.1f s\n', dur);
        fprintf('  Mean speed      : %.3f m/s\n', mean(spd(i1:i2)));
        fprintf('  Position radius : %.2f m\n', radius);
        fprintf('  Dominant axis   : %s\n', axisName);
        fprintf('  Estimated turns : %.2f\n', turns);
        fprintf('  Mean lat/lon    : %.6f, %.6f\n\n', latMean, lonMean);
    end
end

if eventCount == 0
    fprintf('No landmark-like turning events found with the current thresholds.\n');
    fprintf('Try adjusting speed_th, min_stop_sec, max_radius_m, or min_turns.\n');
end