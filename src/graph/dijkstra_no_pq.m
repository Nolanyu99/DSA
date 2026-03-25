function [path_idx, total_cost, dist] = dijkstra_no_pq(adj, w, start_idx, goal_idx)
%DIJKSTRA_NO_PQ  Dijkstra's shortest path without a priority queue.
%
% Inputs:
%   adj       : adjacency list (cell array), adj{i} are neighbour indices
%   w         : weight list (cell array), w{i} aligned with adj{i}
%   start_idx : start node index (1..N)
%   goal_idx  : goal node index (1..N)
%
% Outputs:
%   path_idx   : row vector of node indices along the shortest path
%               empty if no path exists
%   total_cost : total path cost (sum of weights) to reach goal
%   dist       : N-by-1 distance array (dist to all nodes)

N = numel(adj);

dist = inf(N,1);
visited = false(N,1);
parent = zeros(N,1);

dist(start_idx) = 0;

for iter = 1:N
    % Pick the unvisited node with minimum dist
    u = -1;
    best = inf;
    for i = 1:N
        if ~visited(i) && dist(i) < best
            best = dist(i);
            u = i;
        end
    end

    if u == -1
        break; % remaining nodes are unreachable
    end

    visited(u) = true;

    if u == goal_idx
        break; % early exit
    end

    neigh = adj{u};
    weights = w{u};

    for t = 1:numel(neigh)
        v = neigh(t);
        alt = dist(u) + weights(t);
        if alt < dist(v)
            dist(v) = alt;
            parent(v) = u;
        end
    end
end

% Reconstruct path
if isinf(dist(goal_idx))
    path_idx = [];
    total_cost = inf;
    return;
end

path_idx = goal_idx;
while path_idx(1) ~= start_idx
    path_idx = [parent(path_idx(1)), path_idx]; %#ok<AGROW>
end

total_cost = dist(goal_idx);

end