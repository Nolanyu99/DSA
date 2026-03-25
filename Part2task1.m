clc; clear; close all;

%% =========================
% 1. Load data
% =========================
load('dsa.mat');

time = seconds(Position.Properties.RowTimes - Position.Properties.RowTimes(1));

lat = Position.latitude;
lon = Position.longitude;
z   = Position.altitude;   % Z 軸

gps_speed = Position.speed; % 用來對比

%% =========================
% 2. GPS → Cartesian
% =========================
R = 6371000;

lat0 = lat(1);
lon0 = lon(1);

x = R * cosd(lat0) .* (lon - lon0) * pi/180;
y = R * (lat - lat0) * pi/180;

%% =========================
% 3. Velocity (vx, vy, vz)
% =========================
dt = diff(time);

vx = diff(x) ./ dt;
vy = diff(y) ./ dt;
vz = diff(z) ./ dt;

v_total = sqrt(vx.^2 + vy.^2 + vz.^2);

t_v = time(2:end);

%% =========================
% 4. Filtering
% =========================
window = 5;

vx_f = movmean(vx, window);
vy_f = movmean(vy, window);
vz_f = movmean(vz, window);

v_total_f = sqrt(vx_f.^2 + vy_f.^2 + vz_f.^2);

%% =========================
% 5. Plot（4個subplot！！）
% =========================
figure;

subplot(4,1,1)
plot(t_v, vx, 'b'); hold on;
plot(t_v, vx_f, 'r','LineWidth',1.5);
title('vx');
legend('raw','filtered');

subplot(4,1,2)
plot(t_v, vy, 'b'); hold on;
plot(t_v, vy_f, 'r','LineWidth',1.5);
title('vy');
legend('raw','filtered');

subplot(4,1,3)
plot(t_v, vz, 'b'); hold on;
plot(t_v, vz_f, 'r','LineWidth',1.5);
title('vz');
legend('raw','filtered');

subplot(4,1,4)
plot(t_v, v_total, 'b'); hold on;
plot(t_v, v_total_f, 'r','LineWidth',1.5);
title('Total velocity');
legend('raw','filtered');

%% =========================
% 6. Compare with GPS speed（加分）
% =========================
figure;
plot(t_v, v_total, 'b'); hold on;
plot(time, gps_speed, 'g');
title('Computed vs GPS speed');
legend('Computed','GPS');

%% =========================
% 7. Trajectory
% =========================
figure;
plot(x,y); hold on;
plot(x(1),y(1),'go','LineWidth',2);
plot(x(end),y(end),'ro','LineWidth',2);
title('Trajectory');
xlabel('X (m)');
ylabel('Y (m)');
grid on;