function [nearest_id, dist] = kdtree_nearest(tree, qx, qy)
%KDTREE_NEAREST Nearest-neighbour search in a 2D KD-tree.
%
% Inputs:
%   tree : KD-tree struct created by kdtree_build
%   qx, qy : query location (meters, local XY)
%
% Outputs:
%   nearest_id : id of the nearest point
%   dist       : distance to the nearest point (meters)

    if isempty(tree)
        nearest_id = NaN;
        dist = Inf;
        return;
    end

    best.id = NaN;
    best.d2 = Inf;   % squared distance

    best = search_node(tree, qx, qy, best);

    nearest_id = best.id;
    dist = sqrt(best.d2);
end

function best = search_node(node, qx, qy, best)
    if isempty(node)
        return;
    end

    % Update best using current node
    dx = node.x - qx;
    dy = node.y - qy;
    d2 = dx * dx + dy * dy;

    if d2 < best.d2
        best.d2 = d2;
        best.id = node.id;
    end

    % Decide near/far subtree according to split axis
    if node.axis == 1
        diff = qx - node.x;   % split by x
    else
        diff = qy - node.y;   % split by y
    end

    if diff <= 0
        near = node.left;
        far  = node.right;
    else
        near = node.right;
        far  = node.left;
    end

    % Search near subtree first
    best = search_node(near, qx, qy, best);

    % Only search far subtree if necessary
    if diff * diff < best.d2
        best = search_node(far, qx, qy, best);
    end
end
