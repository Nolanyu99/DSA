function G = build_graph_knn(points, k)
%BUILD_GRAPH_KNN  Build an undirected graph (adjacency list) using k-nearest neighbours.
%
% This function connects each node to its k nearest neighbours based on
% Euclidean distance in local XY. The result is returned as an adjacency
% list with two weight options:
%   - G.w_equal: all edges weight = 1 (unweighted case for BFS comparison)
%   - G.w_dist : edge weights = Euclidean distance (weighted case for Dijkstra)
%
% Inputs:
%   points : table with columns {id, name, x, y} (navigable points only)
%   k      : number of nearest neighbours per node (suggest 3 or 4)
%
% Output (struct G):
%   G.n         : number of nodes
%   G.ids       : node ids (points.id)
%   G.names     : node names (points.name)
%   G.xy        : N-by-2 coordinates [x y]
%   G.adj{i}    : neighbour indices (1..N) for node i
%   G.w_equal{i}: weights aligned with adj{i}, all ones
%   G.w_dist{i} : weights aligned with adj{i}, Euclidean distances

N = height(points);
XY = [points.x, points.y];

% Preallocate adjacency as cell arrays
adj = cell(N,1);
w_dist = cell(N,1);

% Compute pairwise distances (N is small here, so O(N^2) is fine)
D = zeros(N,N);
for i = 1:N
    dx = XY(:,1) - XY(i,1);
    dy = XY(:,2) - XY(i,2);
    D(:,i) = hypot(dx, dy);
end

% For each node, pick k nearest neighbours (excluding itself)
for i = 1:N
    [~, order] = sort(D(:,i), 'ascend');
    order(order == i) = [];              % remove self
    nn = order(1:min(k, N-1));           % neighbour indices (1..N)

    adj{i} = nn(:)';                     % row vector
    w_dist{i} = D(nn, i)';               % row vector of distances
end

% Make the graph undirected by symmetrising edges
[adj, w_dist] = make_undirected(adj, w_dist, N);

% Equal weights version
w_equal = cell(N,1);
for i = 1:N
    w_equal{i} = ones(1, numel(adj{i}));
end

% Pack output
G.n = N;
G.ids = points.id;
G.names = points.name;
G.xy = XY;
G.adj = adj;
G.w_equal = w_equal;
G.w_dist = w_dist;

end

function [adj2, w2] = make_undirected(adj, w, N)
%MAKE_UNDIRECTED  Ensure edges are symmetric: if i->j exists, add j->i.

adj2 = adj;
w2 = w;

for i = 1:N
    neigh = adj{i};
    weights = w{i};
    for t = 1:numel(neigh)
        j = neigh(t);
        wij = weights(t);

        % Check if j already has i as neighbour
        if ~any(adj2{j} == i)
            adj2{j} = [adj2{j}, i];
            w2{j} = [w2{j}, wij];
        end
    end
end
end