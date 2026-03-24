function [nearest_id, nearest_name, dist] = list_nearest(points, qx, qy)
%LIST_NEAREST  Baseline nearest-neighbour lookup by linear scan.
%
% This function computes the Euclidean distance from the query location
% (qx, qy) to every point in the input table and returns the closest one.
%
% Inputs:
%   points : table with at least columns {id, name, x, y}
%   qx, qy : query location in the same coordinate system as points.x/points.y
%            (typically local XY in meters)
%
% Outputs:
%   nearest_id   : id of the nearest point
%   nearest_name : name (string) of the nearest point
%   dist         : Euclidean distance to the nearest point (meters)

dx = points.x - qx;
dy = points.y - qy;

% hypot(dx,dy) computes sqrt(dx.^2 + dy.^2) with good numerical stability
d = hypot(dx, dy);

[dist, idx] = min(d);
nearest_id = points.id(idx);
nearest_name = points.name(idx);

end
