function tree = kdtree_build(points)
%KDTREE_BUILD Build a simple 2D KD-tree from a points table.
%
% Input:
%   points : table with at least columns {id, x, y}
%
% Output:
%   tree : struct representing the KD-tree, with fields:
%       id    : point id stored at this node
%       x, y  : point coordinates
%       axis  : split axis at this node (1 = x, 2 = y)
%       left  : left subtree
%       right : right subtree

    if isempty(points)
        tree = [];
        return;
    end

    requiredCols = {'id', 'x', 'y'};
    if ~all(ismember(requiredCols, points.Properties.VariableNames))
        error('kdtree_build:MissingColumns', ...
            'points must contain columns: id, x, y');
    end

    % Convert table to numeric array: [id, x, y]
    P = [double(points.id), double(points.x), double(points.y)];

    % Build recursively
    tree = build_node(P, 0);
end

function node = build_node(P, depth)
    if isempty(P)
        node = [];
        return;
    end

    % axis = 1 for x, 2 for y
    axis = mod(depth, 2) + 1;

    % In P: x is col 2, y is col 3
    coord_col = axis + 1;

    % Sort by current split axis
    [~, order] = sort(P(:, coord_col));
    P = P(order, :);

    % Choose median
    mid = floor(size(P, 1) / 2) + 1;

    % Create node
    node.id = P(mid, 1);
    node.x = P(mid, 2);
    node.y = P(mid, 3);
    node.axis = axis;

    % Recursively build subtrees
    node.left = build_node(P(1:mid-1, :), depth + 1);
    node.right = build_node(P(mid+1:end, :), depth + 1);
end
