function [path_idx, num_edges] = bfs_path(adj, start_idx, goal_idx)
%BFS_PATH  Shortest path in an unweighted graph using BFS (fewest edges).
%
% Inputs:
%   adj       : adjacency list (cell array), adj{i} is a row vector of neighbour indices
%   start_idx : start node index (1..N)
%   goal_idx  : goal node index (1..N)
%
% Outputs:
%   path_idx  : row vector of node indices along the path (start -> goal)
%               empty if no path exists
%   num_edges : number of edges in the path (Inf if no path)

N = numel(adj);

visited = false(N,1);
parent  = zeros(N,1);     % parent(v)=u used to reconstruct path
queue   = zeros(N,1);     % simple array queue
qh = 1; qt = 0;           % head/tail pointers

% Initialise
visited(start_idx) = true;
qt = qt + 1;
queue(qt) = start_idx;

% BFS loop
while qh <= qt
    u = queue(qh);
    qh = qh + 1;

    if u == goal_idx
        break;
    end

    neigh = adj{u};
    for t = 1:numel(neigh)
        v = neigh(t);
        if ~visited(v)
            visited(v) = true;
            parent(v) = u;
            qt = qt + 1;
            queue(qt) = v;
        end
    end
end

% Reconstruct path
if ~visited(goal_idx)
    path_idx = [];
    num_edges = Inf;
    return;
end

path_idx = goal_idx;
while path_idx(1) ~= start_idx
    path_idx = [parent(path_idx(1)), path_idx]; %#ok<AGROW>
end

num_edges = numel(path_idx) - 1;

end