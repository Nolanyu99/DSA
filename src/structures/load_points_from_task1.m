function [points, obstacles, all_points] = load_points_from_task1()
%LOAD_POINTS_FROM_TASK1 Standard data interface for downstream modules.
%   points     : navigable points only (key + signal)
%   obstacles  : obstacle points only
%   all_points : all map entities

    [all_points, points, obstacles] = make_points_table();
end
