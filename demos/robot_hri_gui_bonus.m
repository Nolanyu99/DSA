function robot_hri_gui_bonus()
%ROBOT_HRI_GUI_BONUS Safe parallel Bonus GUI (does NOT modify main GUI)
% Demonstrates obstacle-aware route planning on top of the existing project.
%
% Reuses:
%   - load_points_from_task1
%   - build_graph_knn
%   - dijkstra_pq
%   - bfs_path
%
% Main idea:
%   Build a kNN graph over navigable points.
%   If obstacle-aware mode is ON, remove graph edges that pass too close
%   to the obstacle safety region, then replan the route.

    %% Load map data
    [~, ~, all_points] = load_points_from_task1();

    nav_points = all_points(all_points.type_code ~= 1, :); % key + signal
    obs_points = all_points(all_points.type_code == 1, :); % obstacles

    if isempty(obs_points)
        error('No obstacle point found in all_points.');
    end

    % Use the first mapped obstacle as the blocking region centre
    obs0 = obs_points(1, :);

    %% Build UI
    fig = uifigure( ...
        'Name', 'Robot HRI Bonus: Obstacle-Aware Routing', ...
        'Position', [120 80 1300 760]);

    g = uigridlayout(fig, [3 3]);
    g.RowHeight = {50, '1x', 150};
    g.ColumnWidth = {340, '1x', 360};

    % Header
    titleLbl = uilabel(g, ...
        'Text', 'Bonus GUI: Obstacle-Aware Route Planning (Safe Parallel Version)', ...
        'FontWeight', 'bold', ...
        'FontSize', 16, ...
        'HorizontalAlignment', 'center');
    titleLbl.Layout.Row = 1;
    titleLbl.Layout.Column = [1 3];

    %% Left panel: controls
    left = uipanel(g, 'Title', 'Controls');
    left.Layout.Row = 2;
    left.Layout.Column = 1;

    lg = uigridlayout(left, [12 2]);
    lg.RowHeight = repmat({28}, 1, 12);
    lg.ColumnWidth = {140, '1x'};

    uilabel(lg, 'Text', 'Start');
    ddStart = uidropdown(lg, 'Items', cellstr(nav_points.name), ...
        'Value', cellstr(nav_points.name(1)));

    uilabel(lg, 'Text', 'Goal');
    ddGoal = uidropdown(lg, 'Items', cellstr(nav_points.name), ...
        'Value', cellstr(nav_points.name(min(2,height(nav_points)))));

    uilabel(lg, 'Text', 'Algorithm');
    ddAlg = uidropdown(lg, 'Items', {'Dijkstra (distance)', 'BFS (fewest hops)'}, ...
        'Value', 'Dijkstra (distance)');

    uilabel(lg, 'Text', 'k for kNN graph');
    efK = uieditfield(lg, 'numeric', ...
        'Limits', [1 8], ...
        'RoundFractionalValues', true, ...
        'Value', 3);

    uilabel(lg, 'Text', 'Obstacle-aware');
    cbObstacle = uicheckbox(lg, 'Value', true, 'Text', '');

    uilabel(lg, 'Text', 'Safety radius (m)');
    efRadius = uieditfield(lg, 'numeric', ...
        'Limits', [1 200], ...
        'Value', 25);

    uilabel(lg, 'Text', 'Obstacle centre');
    txtObs = uilabel(lg, ...
        'Text', sprintf('%s  [%.1f, %.1f]', string(obs0.name), obs0.x, obs0.y), ...
        'WordWrap', 'on');

    btnPlan = uibutton(lg, 'Text', 'Plan Route', ...
        'ButtonPushedFcn', @planRoute);
    btnPlan.Layout.Column = [1 2];

    btnCompare = uibutton(lg, 'Text', 'Compare ON vs OFF', ...
        'ButtonPushedFcn', @compareObstacleModes);
    btnCompare.Layout.Column = [1 2];

    btnReset = uibutton(lg, 'Text', 'Reset View', ...
        'ButtonPushedFcn', @(~,~) redrawBase());
    btnReset.Layout.Column = [1 2];

    btnAnimate = uibutton(lg, 'Text', 'Animate Moving Obstacle', ...
        'ButtonPushedFcn', @animateMovingObstacle);
    btnAnimate.Layout.Column = [1 2];

    %% Center: map
    center = uipanel(g, 'Title', 'Map View');
    center.Layout.Row = 2;
    center.Layout.Column = 2;

    cg = uigridlayout(center, [1 1]);
    ax = uiaxes(cg);

    %% Right: output
    right = uipanel(g, 'Title', 'Results');
    right.Layout.Row = 2;
    right.Layout.Column = 3;

    rg = uigridlayout(right, [2 1]);
    rg.RowHeight = {'1x', 180};

    txtOutput = uitextarea(rg, 'Value', {'Ready.'});
    tblOutput = uitable(rg, ...
        'ColumnName', {'Order','Node','X','Y'}, ...
        'Data', cell(0,4));

    %% Bottom panel
    bottom = uipanel(g, 'Title', 'Notes');
    bottom.Layout.Row = 3;
    bottom.Layout.Column = [1 3];

    bg = uigridlayout(bottom, [1 2]);
    bg.ColumnWidth = {'1x', '1x'};

    txtPerf = uitextarea(bg, 'Value', {'Last route time: N/A'});
    txtExplain = uitextarea(bg, 'Value', {
        'How it works:'
        '- Build a k-nearest-neighbour graph over navigable points.'
        '- If obstacle-aware mode is ON, remove graph edges passing too close to the obstacle.'
        '- Replan route using Dijkstra or BFS.'
        '- This file is parallel to the main GUI and does not modify robot_hri_gui.m.'
        });

    redrawBase();

    %% ================= Callbacks =================

    function redrawBase(obsXY, rObs, blockedEdges)
        if nargin < 1
            obsXY = [obs0.x, obs0.y];
        end
        if nargin < 2
            rObs = efRadius.Value;
        end
        if nargin < 3
            blockedEdges = zeros(0,2);
        end

        cla(ax);
        hold(ax, 'on');

        % Plot navigable points
        scatter(ax, nav_points.x, nav_points.y, 36, [0.25 0.35 0.85], 'filled');
        text(ax, nav_points.x + 5, nav_points.y + 5, nav_points.name, 'FontSize', 8);

        % Plot obstacle centre
        scatter(ax, obsXY(1), obsXY(2), 110, [0.85 0.2 0.2], 'x', 'LineWidth', 1.8);

        % Safety circle
        th = linspace(0, 2*pi, 300);
        plot(ax, obsXY(1) + rObs*cos(th), obsXY(2) + rObs*sin(th), ...
            '--', 'Color', [0.85 0.2 0.2], 'LineWidth', 1.4);

        % Blocked edges
        for ii = 1:size(blockedEdges,1)
            i = blockedEdges(ii,1);
            j = blockedEdges(ii,2);
            plot(ax, [nav_points.x(i), nav_points.x(j)], ...
                     [nav_points.y(i), nav_points.y(j)], ...
                     ':', 'Color', [0.85 0.35 0.35], 'LineWidth', 1.2);
        end

        title(ax, 'QEOP map with obstacle-aware routing');
        xlabel(ax, 'X (meters)');
        ylabel(ax, 'Y (meters)');
        grid(ax, 'on');
        axis(ax, 'equal');
        hold(ax, 'off');
    end

    function planRoute(~,~)
        startName = string(ddStart.Value);
        goalName  = string(ddGoal.Value);
        algName   = string(ddAlg.Value);
        k         = max(1, round(efK.Value));
        rObs      = efRadius.Value;
        useObs    = cbObstacle.Value;

        if startName == goalName
            txtOutput.Value = {'Start and goal must be different.'};
            return;
        end

        % Build base graph
        G0 = build_graph_knn(nav_points(:, {'id','name','x','y'}), k);

        blockedEdges = zeros(0,2);

        if useObs
            [Guse, blockedEdges] = apply_obstacle_to_graph(G0, [obs0.x, obs0.y], rObs);
        else
            Guse = G0;
        end

        start_idx = find(nav_points.name == startName, 1);
        goal_idx  = find(nav_points.name == goalName, 1);

        tStart = tic;
        if algName == "Dijkstra (distance)"
            [path_idx, total_cost, ~] = dijkstra_pq(Guse.adj, Guse.w_dist, start_idx, goal_idx);
            elapsed = toc(tStart);

            redrawBase([obs0.x, obs0.y], rObs, blockedEdges);
            if isempty(path_idx)
                txtOutput.Value = {
                    'No feasible path found.'
                    sprintf('Algorithm: %s', algName)
                    sprintf('Obstacle-aware: %s', string(useObs))
                    sprintf('Blocked edges removed: %d', size(blockedEdges,1))
                    };
                tblOutput.Data = cell(0,4);
            else
                plotPathOnAxes(path_idx, [0.10 0.70 0.20]);
                tblOutput.Data = pathTable(path_idx);
                txtOutput.Value = {
                    sprintf('Route found from %s to %s', startName, goalName)
                    sprintf('Algorithm: %s', algName)
                    sprintf('Obstacle-aware: %s', string(useObs))
                    sprintf('Blocked edges removed: %d', size(blockedEdges,1))
                    sprintf('Total path cost: %.2f m', total_cost)
                    sprintf('Path nodes: %s', strjoin(cellstr(nav_points.name(path_idx)), ' -> '))
                    };
            end

        else
            [path_idx, num_edges] = bfs_path(Guse.adj, start_idx, goal_idx);
            elapsed = toc(tStart);

            redrawBase([obs0.x, obs0.y], rObs, blockedEdges);
            if isempty(path_idx)
                txtOutput.Value = {
                    'No feasible path found.'
                    sprintf('Algorithm: %s', algName)
                    sprintf('Obstacle-aware: %s', string(useObs))
                    sprintf('Blocked edges removed: %d', size(blockedEdges,1))
                    };
                tblOutput.Data = cell(0,4);
            else
                geomLen = polylineLength(path_idx);
                plotPathOnAxes(path_idx, [0.10 0.70 0.20]);
                tblOutput.Data = pathTable(path_idx);
                txtOutput.Value = {
                    sprintf('Route found from %s to %s', startName, goalName)
                    sprintf('Algorithm: %s', algName)
                    sprintf('Obstacle-aware: %s', string(useObs))
                    sprintf('Blocked edges removed: %d', size(blockedEdges,1))
                    sprintf('Number of edges: %d', num_edges)
                    sprintf('Geometric path length: %.2f m', geomLen)
                    sprintf('Path nodes: %s', strjoin(cellstr(nav_points.name(path_idx)), ' -> '))
                    };
            end
        end

        txtPerf.Value = [txtPerf.Value; {sprintf('PlanRoute | %s | Time: %.6f s', algName, elapsed)}];
    end

    function compareObstacleModes(~,~)
        startName = string(ddStart.Value);
        goalName  = string(ddGoal.Value);
        k         = max(1, round(efK.Value));
        rObs      = efRadius.Value;

        if startName == goalName
            txtOutput.Value = {'Start and goal must be different.'};
            return;
        end

        G0 = build_graph_knn(nav_points(:, {'id','name','x','y'}), k);
        [Gob, blockedEdges] = apply_obstacle_to_graph(G0, [obs0.x, obs0.y], rObs);

        start_idx = find(nav_points.name == startName, 1);
        goal_idx  = find(nav_points.name == goalName, 1);

        [path0, cost0] = dijkstra_pq(G0.adj, G0.w_dist, start_idx, goal_idx);
        [path1, cost1] = dijkstra_pq(Gob.adj, Gob.w_dist, start_idx, goal_idx);

        redrawBase([obs0.x, obs0.y], rObs, blockedEdges);
        hold(ax, 'on');

        if ~isempty(path0)
            plot(ax, nav_points.x(path0), nav_points.y(path0), ...
                '-', 'Color', [0.2 0.5 1], 'LineWidth', 2);
        end

        if ~isempty(path1)
            plot(ax, nav_points.x(path1), nav_points.y(path1), ...
                '-', 'Color', [0.1 0.7 0.2], 'LineWidth', 2.5);
        end

        legend(ax, {'Obstacle centre','Safety radius','Blocked edges','Original route','Obstacle-aware route'}, ...
            'Location', 'best');
        hold(ax, 'off');

        txtOutput.Value = {
            sprintf('Comparison from %s to %s', startName, goalName)
            sprintf('Obstacle radius: %.1f m', rObs)
            sprintf('Blocked edges removed: %d', size(blockedEdges,1))
            sprintf('Original route cost: %s', localNumToStr(cost0))
            sprintf('Obstacle-aware route cost: %s', localNumToStr(cost1))
            'Blue = original route, Green = obstacle-aware route'
            };
    end
    function animateMovingObstacle(~,~)
    startName = string(ddStart.Value);
    goalName  = string(ddGoal.Value);
    algName   = string(ddAlg.Value);
    k         = max(1, round(efK.Value));
    rObs      = efRadius.Value;

    if startName == goalName
        txtOutput.Value = {'Start and goal must be different.'};
        return;
    end

    G0 = build_graph_knn(nav_points(:, {'id','name','x','y'}), k);
    start_idx = find(nav_points.name == startName, 1);
    goal_idx  = find(nav_points.name == goalName, 1);

    % First compute the base route without obstacle
    if algName == "Dijkstra (distance)"
        [basePath, baseCost] = dijkstra_pq(G0.adj, G0.w_dist, start_idx, goal_idx);
        baseMetricText = sprintf('Base cost = %s m', localNumToStr(baseCost));
    else
        [basePath, baseEdges] = bfs_path(G0.adj, start_idx, goal_idx);
        baseMetricText = sprintf('Base edges = %s', localNumToStr(baseEdges));
    end

    if isempty(basePath) || numel(basePath) < 2
        txtOutput.Value = {
            'No initial path found.'
            'Cannot animate random roadside obstacle.'
            };
        return;
    end

    txtOutput.Value = {
        'Animating random roadside obstacle...'
        'One obstacle appears at a time near the current route.'
        baseMetricText
        };

    nSteps = 12;

    for s = 1:nSteps
        % Generate one random obstacle near a random segment of the current route
        obsXY = randomRoadsideObstacle(basePath, nav_points, 0.35*rObs, 0.75*rObs);

        [Guse, blockedEdges] = apply_obstacle_to_graph(G0, obsXY, rObs);

        redrawBase(obsXY, rObs, blockedEdges);

        % Draw original route as dashed blue reference
        hold(ax, 'on');
        plot(ax, nav_points.x(basePath), nav_points.y(basePath), '--', ...
            'Color', [0.2 0.5 1], 'LineWidth', 1.8);
        hold(ax, 'off');

        % Replan with obstacle
        if algName == "Dijkstra (distance)"
            [path_idx, total_cost] = dijkstra_pq(Guse.adj, Guse.w_dist, start_idx, goal_idx);
            metricText = sprintf('Replanned cost = %s m', localNumToStr(total_cost));
        else
            [path_idx, num_edges] = bfs_path(Guse.adj, start_idx, goal_idx);
            metricText = sprintf('Replanned edges = %s', localNumToStr(num_edges));
        end

        if ~isempty(path_idx)
            plotPathOnAxes(path_idx, [0.10 0.70 0.20]);
        end

        txtObs.Text = sprintf('Random roadside obstacle [%.1f, %.1f]', obsXY(1), obsXY(2));

        txtOutput.Value = {
            'Animating random roadside obstacle...'
            sprintf('Step %d / %d', s, nSteps)
            sprintf('Obstacle centre = [%.1f, %.1f]', obsXY(1), obsXY(2))
            sprintf('Blocked edges = %d', size(blockedEdges,1))
            baseMetricText
            metricText
            'Blue dashed = original route, Green = replanned route'
            };

        drawnow;
        pause(0.35);
    end
end
    function obsXY = randomRoadsideObstacle(path_idx, nav_points, minOffset, maxOffset)
% Generate one random obstacle near a random segment of the current route.
% The obstacle is placed beside the road segment instead of far away
% in irrelevant map regions.

    if numel(path_idx) < 2
        idx = path_idx(1);
        obsXY = [nav_points.x(idx), nav_points.y(idx)];
        return;
    end

    % Pick a random segment from the current route
    s = randi(numel(path_idx)-1);
    i = path_idx(s);
    j = path_idx(s+1);

    A = [nav_points.x(i), nav_points.y(i)];
    B = [nav_points.x(j), nav_points.y(j)];
    AB = B - A;
    L = norm(AB);

    if L < eps
        obsXY = A;
        return;
    end

    % Pick a random position along the segment (avoid exact endpoints)
    t = 0.2 + 0.6 * rand;
    Q = A + t * AB;

    % Unit normal vector to place obstacle "beside" the road
    n = [-AB(2), AB(1)] / L;

    % Random left/right side
    side = 1;
    if rand < 0.5
        side = -1;
    end

    % Random offset from the road centreline
    offset = minOffset + (maxOffset - minOffset) * rand;

    obsXY = Q + side * offset * n;
end
    %% ================= Helpers =================

    function plotPathOnAxes(path_idx, colorVec)
        hold(ax, 'on');
        px = nav_points.x(path_idx);
        py = nav_points.y(path_idx);
        plot(ax, px, py, '-o', ...
            'Color', colorVec, ...
            'LineWidth', 2.5, ...
            'MarkerFaceColor', colorVec, ...
            'MarkerSize', 6);
        scatter(ax, px(1), py(1), 100, [0.2 0.8 0.2], 'filled');
        scatter(ax, px(end), py(end), 100, [0.9 0.2 0.2], 'filled');
        hold(ax, 'off');
    end

    function tbl = pathTable(path_idx)
        tbl = cell(numel(path_idx), 4);
        for ii = 1:numel(path_idx)
            idx = path_idx(ii);
            tbl{ii,1} = ii;
            tbl{ii,2} = char(nav_points.name(idx));
            tbl{ii,3} = nav_points.x(idx);
            tbl{ii,4} = nav_points.y(idx);
        end
    end

    function L = polylineLength(path_idx)
        L = 0;
        for ii = 1:numel(path_idx)-1
            a = path_idx(ii);
            b = path_idx(ii+1);
            L = L + hypot(nav_points.x(a)-nav_points.x(b), nav_points.y(a)-nav_points.y(b));
        end
    end

end

%% ================= Local functions =================

function [G2, blockedEdges] = apply_obstacle_to_graph(G, obsXY, rObs)
% Remove any edge whose line segment passes within rObs of obsXY

    G2 = G;
    blockedEdges = zeros(0,2);

    for i = 1:G.n
        neigh = G.adj{i};

        for t = 1:numel(neigh)
            j = neigh(t);

            % process each undirected edge once
            if j <= i
                continue;
            end

            A = G.xy(i, :);
            B = G.xy(j, :);

            d = point_to_segment_distance(obsXY, A, B);

            if d <= rObs
                [G2.adj{i}, G2.w_equal{i}, G2.w_dist{i}] = remove_edge_from_node(G2.adj{i}, G2.w_equal{i}, G2.w_dist{i}, j);
                [G2.adj{j}, G2.w_equal{j}, G2.w_dist{j}] = remove_edge_from_node(G2.adj{j}, G2.w_equal{j}, G2.w_dist{j}, i);

                blockedEdges(end+1,:) = [i, j]; %#ok<AGROW>
            end
        end
    end
end

function [adjRow, wEqRow, wDistRow] = remove_edge_from_node(adjRow, wEqRow, wDistRow, target)
    keep = adjRow ~= target;
    adjRow = adjRow(keep);
    wEqRow = wEqRow(keep);
    wDistRow = wDistRow(keep);
end

function d = point_to_segment_distance(P, A, B)
% Distance from point P to line segment AB in 2D

    AB = B - A;
    AP = P - A;

    denom = dot(AB, AB);
    if denom < eps
        d = norm(P - A);
        return;
    end

    t = dot(AP, AB) / denom;
    t = max(0, min(1, t));   % clamp to segment

    Q = A + t * AB;
    d = norm(P - Q);
end

function s = localNumToStr(x)
    if isempty(x) || (isnumeric(x) && any(isinf(x)))
        s = 'Inf / no path';
    elseif isnumeric(x)
        s = sprintf('%.2f', x);
    else
        s = char(string(x));
    end
end