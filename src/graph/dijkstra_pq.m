function [path_idx, total_cost, dist] = dijkstra_pq(adj, w, start_idx, goal_idx)
%DIJKSTRA_PQ  Dijkstra's shortest path using a min-heap priority queue.
%
% This implementation uses a "lazy" heap: we allow multiple entries for the
% same node in the heap. When popping, we discard entries that are not the
% current best distance (lazy deletion). This avoids needing decrease-key.
%
% Inputs/Outputs are the same as dijkstra_no_pq.

N = numel(adj);

dist = inf(N,1);
parent = zeros(N,1);
visited = false(N,1);

dist(start_idx) = 0;

% Heap stores rows: [keyDistance, nodeIndex]
heapKeys = zeros(0,1);
heapVals = zeros(0,1);

% Push start
[heapKeys, heapVals] = heap_push(heapKeys, heapVals, 0, start_idx);

while ~isempty(heapKeys)
    % Pop minimum
    [heapKeys, heapVals, d_u, u] = heap_pop(heapKeys, heapVals);

    % Lazy deletion: skip if this is outdated
    if d_u ~= dist(u)
        continue;
    end

    if visited(u)
        continue;
    end
    visited(u) = true;

    if u == goal_idx
        break;
    end

    neigh = adj{u};
    weights = w{u};

    for t = 1:numel(neigh)
        v = neigh(t);
        alt = dist(u) + weights(t);
        if alt < dist(v)
            dist(v) = alt;
            parent(v) = u;
            [heapKeys, heapVals] = heap_push(heapKeys, heapVals, alt, v);
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

% ---------------- Min-heap helper functions ----------------

function [keys, vals] = heap_push(keys, vals, key, val)
%HEAP_PUSH  Insert (key,val) into min-heap.
keys(end+1,1) = key;
vals(end+1,1) = val;
i = numel(keys);

while i > 1
    p = floor(i/2);
    if keys(p) <= keys(i)
        break;
    end
    [keys(p), keys(i)] = swap(keys(p), keys(i));
    [vals(p), vals(i)] = swap(vals(p), vals(i));
    i = p;
end
end

function [keys, vals, key, val] = heap_pop(keys, vals)
%HEAP_POP  Remove and return minimum (key,val) from min-heap.
key = keys(1);
val = vals(1);

last = numel(keys);
if last == 1
    keys = zeros(0,1);
    vals = zeros(0,1);
    return;
end

% Move last to root
keys(1) = keys(last);
vals(1) = vals(last);
keys(last) = [];
vals(last) = [];

% Heapify down
i = 1;
n = numel(keys);
while true
    l = 2*i;
    r = 2*i + 1;
    smallest = i;

    if l <= n && keys(l) < keys(smallest)
        smallest = l;
    end
    if r <= n && keys(r) < keys(smallest)
        smallest = r;
    end
    if smallest == i
        break;
    end
    [keys(i), keys(smallest)] = swap(keys(i), keys(smallest));
    [vals(i), vals(smallest)] = swap(vals(i), vals(smallest));
    i = smallest;
end
end

function [b, a] = swap(a, b)
%SWAP  Utility swap.
end