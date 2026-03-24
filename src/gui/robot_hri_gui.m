function robot_hri_gui()
%ROBOT_HRI_GUI Human-Robot Interaction GUI for lookup and scheduling queries.
%   This GUI demonstrates:
%   - Query handling for navigation/key-point questions
%   - Lookup using linear scan (linked-list baseline) and KD-tree
%   - Timing comparison between methods
%   - Speculative dialogue simulation with coherent timestamps

    [~, ~, all_points] = load_points_from_task1();
    key_points = all_points(all_points.type_code == 2, :);
    nav_points = all_points(all_points.type_code ~= 1, :); % key + signal

    kd_tree = kdtree_build(nav_points(:, {'id','x','y'}));

    fig = uifigure('Name', 'Robot HRI Query Console', 'Position', [100 100 1250 700]);
    g = uigridlayout(fig, [3, 3]);
    g.RowHeight = {50, '1x', 180};
    g.ColumnWidth = {320, '1x', 360};

    % Header
    titleLbl = uilabel(g, 'Text', 'Human-Robot Interaction GUI (Linked-List vs KD-Tree)', ...
        'FontWeight', 'bold', 'FontSize', 16, 'HorizontalAlignment', 'center');
    titleLbl.Layout.Row = 1;
    titleLbl.Layout.Column = [1 3];

    %% Left panel: controls
    left = uipanel(g, 'Title', 'Query Controls');
    left.Layout.Row = 2;
    left.Layout.Column = 1;
    lg = uigridlayout(left, [12,2]);
    lg.RowHeight = repmat({26}, 1, 12);
    lg.ColumnWidth = {120, '1x'};

    queryList = {
        '1) Route: A -> B', ...
        '2) Distance to point D', ...
        '3) k closest to point P', ...
        '4) k closest to waiting area 1', ...
        '5) Points within radius r of P', ...
        '6) Farthest key point from P', ...
        '7) Reachable from A to B under max distance', ...
        '8) Suggested visit order (nearest-first)', ...
        '9) Closest pair among key points', ...
        '10) Compare linked-list vs KD-tree'
    };

    uilabel(lg, 'Text', 'Question');
    ddQuery = uidropdown(lg, 'Items', queryList, 'Value', queryList{1});

    uilabel(lg, 'Text', 'From / P');
    ddFrom = uidropdown(lg, 'Items', cellstr(nav_points.name));

    uilabel(lg, 'Text', 'To / D / B');
    ddTo = uidropdown(lg, 'Items', cellstr(nav_points.name), 'Value', cellstr(nav_points.name(2)));

    uilabel(lg, 'Text', 'k');
    efK = uieditfield(lg, 'numeric', 'Limits', [1 10], 'RoundFractionalValues', true, 'Value', 3);

    uilabel(lg, 'Text', 'Radius (m)');
    efR = uieditfield(lg, 'numeric', 'Limits', [1 10000], 'Value', 400);

    uilabel(lg, 'Text', 'Max dist (m)');
    efMax = uieditfield(lg, 'numeric', 'Limits', [1 100000], 'Value', 1200);

    uilabel(lg, 'Text', 'Method');
    ddMethod = uidropdown(lg, 'Items', {'Linked-List (linear scan)', 'KD-Tree'}, 'Value', 'KD-Tree');

    btnRun = uibutton(lg, 'Text', 'Run Query', 'ButtonPushedFcn', @runQuery);
    btnRun.Layout.Column = [1 2];

    btnReset = uibutton(lg, 'Text', 'Reset View', 'ButtonPushedFcn', @(~,~) redrawMap());
    btnReset.Layout.Column = [1 2];

    btnSpec = uibutton(lg, 'Text', 'Run Speculative Dialogue', 'ButtonPushedFcn', @runSpeculativeDialogue);
    btnSpec.Layout.Column = [1 2];

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
    rg.RowHeight = {'1x', 120};

    txtOutput = uitextarea(rg, 'Value', {'Ready.'});
    tblOutput = uitable(rg, 'ColumnName', {'ID','Name','Distance(m)'}, 'Data', cell(0,3));

    %% Bottom: dialogue feed + timings
    bottom = uipanel(g, 'Title', 'Dialogue Feed & Performance');
    bottom.Layout.Row = 3;
    bottom.Layout.Column = [1 3];
    bg = uigridlayout(bottom, [1 3]);
    bg.ColumnWidth = {'1x', 300, 300};

    lbDialogue = uilistbox(bg, 'Items', {'(No dialogue yet)'});
    txtPerf = uitextarea(bg, 'Value', {'Last query time: N/A'});
    txtComplexity = uitextarea(bg, 'Value', {
        'Complexity summary:'
        '- Linked-list (linear scan): nearest query O(n)'
        '- KD-tree build: O(n log n), nearest avg O(log n), worst O(n)'
    });

    redrawMap();

    function redrawMap()
        cla(ax);
        hold(ax, 'on');
        scatter(ax, nav_points.x, nav_points.y, 36, [0.3 0.3 0.9], 'filled');
        text(ax, nav_points.x + 5, nav_points.y + 5, nav_points.name, 'FontSize', 8);

        obs = all_points(all_points.type_code == 1, :);
        if ~isempty(obs)
            scatter(ax, obs.x, obs.y, 90, [0.85 0.2 0.2], 'x', 'LineWidth', 1.4);
        end

        title(ax, 'QEOP local XY map (meters)');
        xlabel(ax, 'X'); ylabel(ax, 'Y');
        grid(ax, 'on'); axis(ax, 'equal');
        hold(ax, 'off');
    end

    function runQuery(~,~)
        q = ddQuery.Value;
        fromName = string(ddFrom.Value);
        toName = string(ddTo.Value);
        k = efK.Value;
        r = efR.Value;
        maxDist = efMax.Value;
        method = ddMethod.Value;

        pFrom = nav_points(nav_points.name == fromName, :);
        pTo = nav_points(nav_points.name == toName, :);

        redrawMap();
        out = {};
        tbl = cell(0,3);

        tStart = tic;
        if strcmp(q, '1) Route: A -> B')
            d = hypot(pFrom.x - pTo.x, pFrom.y - pTo.y);
            out = {
                sprintf('Route guidance (straight-line proxy):')
                sprintf('Start: %s', pFrom.name)
                sprintf('Goal : %s', pTo.name)
                sprintf('Distance: %.2f m', d)
                sprintf('Direction: move from [%.1f, %.1f] to [%.1f, %.1f]', pFrom.x, pFrom.y, pTo.x, pTo.y)
            };
            hold(ax,'on');
            plot(ax, [pFrom.x pTo.x], [pFrom.y pTo.y], 'g-', 'LineWidth', 2);
            scatter(ax, [pFrom.x pTo.x], [pFrom.y pTo.y], 90, 'g', 'filled');
            hold(ax,'off');

        elseif strcmp(q, '2) Distance to point D')
            d = hypot(pFrom.x - pTo.x, pFrom.y - pTo.y);
            out = {sprintf('Distance from %s to %s = %.2f m', pFrom.name, pTo.name, d)};
            hold(ax,'on');
            plot(ax, [pFrom.x pTo.x], [pFrom.y pTo.y], 'm--', 'LineWidth', 1.8);
            hold(ax,'off');

        elseif strcmp(q, '3) k closest to point P')
            [tbl, out] = kClosestToPoint(pFrom, k);
            highlightRows(tbl);

        elseif strcmp(q, '4) k closest to waiting area 1')
            [tbl, out] = kClosestToPoint(pFrom, k);
            highlightRows(tbl);

        elseif strcmp(q, '5) Points within radius r of P')
            [tbl, out] = pointsWithinRadius(pFrom, r);
            hold(ax,'on');
            th = linspace(0, 2*pi, 200);
            plot(ax, pFrom.x + r*cos(th), pFrom.y + r*sin(th), '--', 'Color', [0.9 0.5 0.1], 'LineWidth', 1.2);
            hold(ax,'off');
            highlightRows(tbl);

        elseif strcmp(q, '6) Farthest key point from P')
            kp = key_points;
            d = hypot(kp.x - pFrom.x, kp.y - pFrom.y);
            [mx, idx] = max(d);
            out = {sprintf('Farthest key point from %s: %s (%.2f m)', pFrom.name, kp.name(idx), mx)};
            tbl = {kp.id(idx), char(kp.name(idx)), mx};
            highlightRows(tbl);

        elseif strcmp(q, '7) Reachable from A to B under max distance')
            d = hypot(pFrom.x - pTo.x, pFrom.y - pTo.y);
            canReach = d <= maxDist;
            out = {
                sprintf('A=%s, B=%s, distance=%.2f m, max=%.2f m', pFrom.name, pTo.name, d, maxDist)
                sprintf('Reachable = %s', string(canReach))
            };

        elseif strcmp(q, '8) Suggested visit order (nearest-first)')
            [tbl, out] = nearestFirstOrder(pFrom, min(6, height(key_points)));
            highlightRows(tbl);

        elseif strcmp(q, '9) Closest pair among key points')
            [a, b, dmin] = closestPairBruteforce(key_points);
            out = {sprintf('Closest key-point pair: %s <-> %s (%.2f m)', a.name, b.name, dmin)};
            tbl = {
                a.id, char(a.name), 0;
                b.id, char(b.name), dmin
            };
            hold(ax, 'on');
            plot(ax, [a.x b.x], [a.y b.y], 'c-', 'LineWidth', 2);
            hold(ax, 'off');

        else % 10) compare
            [out, tbl] = compareMethods(pFrom, k);
        end
        elapsed = toc(tStart);

        out = [out; {sprintf('Selected lookup mode: %s', method)}];
        txtOutput.Value = out;
        tblOutput.Data = tbl;
        txtPerf.Value = [txtPerf.Value; {sprintf('Query: %s | Time: %.6f s', q, elapsed)}];
    end

    function [tbl, out] = kClosestToPoint(pFrom, k)
        candidates = nav_points(nav_points.id ~= pFrom.id, :);
        d = hypot(candidates.x - pFrom.x, candidates.y - pFrom.y);
        [ds, idx] = sort(d, 'ascend');
        kk = min(k, numel(idx));
        idx = idx(1:kk);
        tbl = [num2cell(candidates.id(idx)), cellstr(candidates.name(idx)), num2cell(ds(1:kk))];
        out = {sprintf('%d closest points to %s:', kk, pFrom.name)};
        for ii = 1:kk
            out{end+1} = sprintf('%s (%.2f m)', candidates.name(idx(ii)), ds(ii)); %#ok<AGROW>
        end
    end

    function [tbl, out] = pointsWithinRadius(pFrom, r)
        candidates = nav_points(nav_points.id ~= pFrom.id, :);
        d = hypot(candidates.x - pFrom.x, candidates.y - pFrom.y);
        idx = find(d <= r);
        [ds, ord] = sort(d(idx), 'ascend');
        idx = idx(ord);
        tbl = [num2cell(candidates.id(idx)), cellstr(candidates.name(idx)), num2cell(ds)];
        out = {sprintf('Points within %.2f m of %s: %d', r, pFrom.name, numel(idx))};
    end

    function [tbl, out] = nearestFirstOrder(startP, maxN)
        pool = key_points(key_points.id ~= startP.id, :);
        cur = [startP.x, startP.y];
        tbl = cell(0,3);
        out = {sprintf('Nearest-first visit order from %s', startP.name)};

        n = min(maxN, height(pool));
        for i = 1:n
            d = hypot(pool.x - cur(1), pool.y - cur(2));
            [m, idm] = min(d);
            tbl(end+1,:) = {pool.id(idm), char(pool.name(idm)), m}; %#ok<AGROW>
            out{end+1} = sprintf('%d) %s (%.2f m)', i, pool.name(idm), m); %#ok<AGROW>
            cur = [pool.x(idm), pool.y(idm)];
            pool(idm,:) = [];
            if isempty(pool), break; end
        end
    end

    function [a,b,dmin] = closestPairBruteforce(pts)
        dmin = inf; ia = 1; ib = 2;
        for i = 1:height(pts)-1
            for j = i+1:height(pts)
                d = hypot(pts.x(i)-pts.x(j), pts.y(i)-pts.y(j));
                if d < dmin
                    dmin = d; ia = i; ib = j;
                end
            end
        end
        a = pts(ia,:); b = pts(ib,:);
    end

    function [out, tbl] = compareMethods(pFrom, k)
        t1 = tic;
        [idLL, nameLL, distLL] = list_nearest(nav_points, pFrom.x + 30, pFrom.y + 20);
        llTime = toc(t1);

        t2 = tic;
        [idKD, distKD] = kdtree_nearest(kd_tree, pFrom.x + 30, pFrom.y + 20);
        kdTime = toc(t2);

        target = nav_points(nav_points.id == idKD, :);
        if isempty(target)
            kdName = "N/A";
        else
            kdName = target.name(1);
        end

        [tblClosest, ~] = kClosestToPoint(pFrom, k);
        tbl = tblClosest;

        out = {
            sprintf('Comparison query near [%.1f, %.1f]', pFrom.x + 30, pFrom.y + 20)
            sprintf('Linked-list nearest: id=%d name=%s dist=%.2f m time=%.6fs', idLL, string(nameLL), distLL, llTime)
            sprintf('KD-tree nearest   : id=%d name=%s dist=%.2f m time=%.6fs', idKD, string(kdName), distKD, kdTime)
            sprintf('Speedup (LL/KD): %.2fx', llTime / max(kdTime, eps))
        };
    end

    function highlightRows(tbl)
        if isempty(tbl), return; end
        hold(ax,'on');
        ids = cell2mat(tbl(:,1));
        sel = nav_points(ismember(nav_points.id, ids), :);
        scatter(ax, sel.x, sel.y, 90, [0.1 0.7 0.2], 'filled');
        hold(ax,'off');
    end

    function runSpeculativeDialogue(~,~)
        events = [ ...
            struct('t',0.5,'speaker','Person 1','text','Maybe we start at Marshgate then go to UAL'), ...
            struct('t',1.5,'speaker','Person 2','text','I prefer OPS then Aquatics Centre'), ...
            struct('t',2.7,'speaker','Person 1','text','Actually let us finish at London Stadium') ...
        ];

        lbDialogue.Items = {'Listening...'};
        planNames = strings(0,1);
        t0 = tic;
        redrawMap();

        for i = 1:numel(events)
            while toc(t0) < events(i).t
                pause(0.02);
            end
            item = sprintf('[t=%.1fs] %s: %s', events(i).t, events(i).speaker, events(i).text);
            if numel(lbDialogue.Items) == 1 && strcmp(lbDialogue.Items{1}, 'Listening...')
                lbDialogue.Items = {item};
            else
                lbDialogue.Items{end+1} = item; %#ok<AGROW>
            end

            mentioned = extractMentionedPoints(string(events(i).text), nav_points.name);
            for m = 1:numel(mentioned)
                if ~any(planNames == mentioned(m))
                    planNames(end+1,1) = mentioned(m); %#ok<AGROW>
                end
            end

            if numel(planNames) >= 2
                pA = nav_points(nav_points.name == planNames(end-1), :);
                pB = nav_points(nav_points.name == planNames(end), :);
                hold(ax,'on');
                plot(ax, [pA.x pB.x], [pA.y pB.y], 'r-', 'LineWidth', 2);
                scatter(ax, [pA.x pB.x], [pA.y pB.y], 80, 'r', 'filled');
                hold(ax,'off');
            end
        end

        txtOutput.Value = {
            'Speculative dialogue complete.'
            sprintf('Predicted stop order: %s', strjoin(cellstr(planNames), ' -> '))
            'System replanned incrementally at each timestamped utterance.'
        };
    end

    function namesOut = extractMentionedPoints(sentence, allNames)
        namesOut = strings(0,1);
        low = lower(sentence);
        for ii = 1:numel(allNames)
            nm = string(allNames(ii));
            if contains(low, lower(nm))
                namesOut(end+1,1) = nm; %#ok<AGROW>
            end
        end
    end
end
