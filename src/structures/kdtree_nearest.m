function [nearest_id, dist] = kdtree_nearest(tree, qx, qy)
%KDTREE_NEAREST  Nearest-neighbour search in a 2D KD-tree.
%
% This performs a standard branch-and-bound KD-tree query:
%   1) Visit the subtree that is on the same side of the split as the query.
%   2) Keep track of the best (smallest) distance found so far.
%   3) Only visit the "far" subtree if the split boundary could contain a
%      closer point (pruning condition).
%
% Inputs:
%   tree  : KD-tree struct created by kdtree_build
%   qx,qy : query location (meters, local XY)
%
% Outputs:
%   nearest_id : id of the nearest point
%   dist       : distance to the nearest point (meters)

best.id = NaN;
best.d2 = inf;  % store squared distance for efficiency

best = search_node(tree, qx, qy, best);

nearest_id = best.id;
dist = sqrt(best.d2);

end

function best = search_node(node, qx, qy, best)
%SEARCH_NODE  Recursive KD-tree nearest-neighbour search.

if isempty(node)
    return;
end

% Update best using the current node point
dx = node.x - qx;
dy = node.y - qy;
d2 = dx*dx + dy*dy;

if d2 < best.d2
    best.d2 = d2;
    best.id = node.id;
end

% Determine which subtree is "near" vs "far" relative to the split axis
if node.axis == 1
    diff = qx - node.x;  % split by x
else
    diff = qy - node.y;  % split by y
end

if diff <= 0
    near = node.left;
    far  = node.right;
else
    near = node.right;
    far  = node.left;
end

% Always search the near subtree first
best = search_node(near, qx, qy, best);

% Pruning rule:
% The distance from the query to the split boundary is |diff|.
% If diff^2 >= best.d2, then even the closest point on the far side cannot
% beat the current best, so we can skip searching the far subtree.
if diff*diff < best.d2
    best = search_node(far, qx, qy, best);
end

end