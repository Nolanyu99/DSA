function [tour_idx, tour_cost, visit_order_idx] = tourist_mode_nn(points, G, start_name)
%TOURIST_MODE_NN  "Full tourist-guide mode" (TSP-related) using a simple heuristic.
%
% This is a TSP-related heuristic (not guaranteed optimal):
%   - Start from a waiting point (specified by start_name)
%   - Visit all KEY points (type_code == 2) exactly once (order chosen by
%     nearest-neighbour heuristic using Euclidean distance in XY)
%   - Between consecutive stops, use Dijkstra (weighted) on the graph to get
%     the shortest path segment, then concatenate segments into one full tour.
%
% Inputs:
%   points     : table with columns {name, type_code, x, y}
%   G          : graph struct from build_graph_knn (uses G.adj and G.w_dist)
%   start_name : string, starting point name (e.g., "Marshgate")
%
% Outputs:
%   tour_idx        : concatenated path indices (1..N) for the full tour
%   tour_cost       : total distance (sum of Dijkstra segment costs)
%   visit_order_idx : the sequence of "stops" (start + key points in visit order)

% --- find start index ---
start_idx = find(points.name == string(start_name), 1);
if isempty(start_idx)
    error("Start point '%s' not found in points table.", start_name);
end

% --- collect key points (type_code == 2) ---
key_idx = find(points.type_code == 2);

% Ensure start is included as the first stop (even if it is not a key point)
unvisited = setdiff(key_idx, start_idx);

% Nearest-neighbour heuristic order (based on straight-line distance)
visit_order_idx = start_idx;
current = start_idx;

while ~isempty(unvisited)
    % Choose the next key point with minimum Euclidean distance in XY
    dx = points.x(unvisited) - points.x(current);
    dy = points.y(unvisited) - points.y(current);
    d  = hypot(dx, dy);

    [~, m] = min(d);
    next = unvisited(m);

    visit_order_idx(end+1) = next; %#ok<AGROW>
    current = next;

    unvisited(m) = [];
end

% --- build full tour by concatenating Dijkstra shortest paths between stops ---
tour_idx = [];
tour_cost = 0;

for s = 1:(numel(visit_order_idx)-1)
    a = visit_order_idx(s);
    b = visit_order_idx(s+1);

    [seg_idx, seg_cost] = dijkstra_pq(G.adj, G.w_dist, a, b);

    if isempty(seg_idx)
        error("No path found between '%s' and '%s'. Graph may be disconnected.", ...
            points.name(a), points.name(b));
    end

    % Concatenate segments (avoid duplicating the connecting node)
    if isempty(tour_idx)
        tour_idx = seg_idx;
    else
        tour_idx = [tour_idx, seg_idx(2:end)]; %#ok<AGROW>
    end

    tour_cost = tour_cost + seg_cost;
end

end