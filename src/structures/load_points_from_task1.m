function [points, obstacles] = load_points_from_task1()
%LOAD_POINTS_FROM_TASK1  Load QEOP points from task1.m (repo root) and
% return standardised tables for downstream modules.
%
% Assumptions:
%   - task1.m is located in the repository root.
%   - task1.m defines variables: names, type, x, y
%     where:
%       type == 2  -> key points
%       type == 3  -> signal points
%       type == 1  -> obstacles
%
% Outputs:
%   points    : table containing only key+signal points (type 2/3)
%               columns: id, name, type_code, x, y
%   obstacles : table containing only obstacles (type 1)
%               columns: id, name, type_code, x, y
thisFile = mfilename("fullpath");
repoRoot = fileparts(fileparts(fileparts(thisFile))); % structures -> src -> root
run(fullfile(repoRoot, "DSAproject.m"));

% Fail fast if task1 does not define the expected variables
requiredVars = {'names','type','x','y'};
for k = 1:numel(requiredVars)
    v = requiredVars{k};
    if ~exist(v, 'var')
        error('task1.m did not define variable "%s". Please check task1.m.', v);
    end
end

% Ensure column vectors and consistent types
names = string(names(:));
type  = double(type(:));
x     = double(x(:));
y     = double(y(:));

% Build a unified table for all entities
alltbl = table((1:numel(names))', names, type, x, y, ...
    'VariableNames', {'id','name','type_code','x','y'});

% Split into navigable points (key+signal) vs obstacles
points    = alltbl(alltbl.type_code == 2 | alltbl.type_code == 3, :);
obstacles = alltbl(alltbl.type_code == 1, :);

end