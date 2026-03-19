function tree = kdtree_build(points)
%KDTREE_BUILD  Build a simple 2D KD-tree from a points table.
%
% The KD-tree recursively partitions 2D space by alternating split axes:
% depth 0 -> split by x, depth 1 -> split by y, depth 2 -> split by x, ...
% At each node we select the median point along the current axis.
%
% Input:
%   points : table with at least columns {id, x, y}
%
% Output:
%   tree : struct representing the KD-tree, with fields:
%       id    : point id stored at this node
%       x, y  : point coordinates
%       axis  : split axis at this node (1 = x, 2 = y)
%       left  : left subtree (points with smaller coordinate on 'axis')
%       right : right subtree (points with larger coordinate on 'axis')

% Convert table to numeric array for sorting:
% columns: [id, x, y]
P = [double(points.id), double(points.x), double(points.y)];

% Build recursively, starting at depth=0 (split by x)
tree = build_node(P, 0);

end

function node = build_node(P, depth)
%BUILD_NODE  Recursive helper to build KD-tree nodes.
%
% P is an N-by-3 array: [id, x, y]

if isempty(P)
    node = [];
    return;
end

% axis: 1 for x, 2 for y
axis = mod(depth, 2) + 1;

% In P: x is column 2, y is column 3
coord_col = axis + 1;

% Sort points along the chosen axis and pick the median
[~, order] = sort(P(:, coord_col));
P = P(order, :);

mid = floor(size(P, 1) / 2) + 1;

% Create node
node.id   = P(mid, 1);
node.x    = P(mid, 2);
node.y    = P(mid, 3);
node.axis = axis;

% Recurse on left/right subsets
node.left  = build_node(P(1:mid-1, :), depth + 1);
node.right = build_node(P(mid+1:end, :), depth + 1);

end