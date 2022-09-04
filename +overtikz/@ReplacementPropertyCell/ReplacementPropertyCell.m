classdef ReplacementPropertyCell < overtikz.ReplacementInterface
    properties
        objectHandle
        objectProperty
        subNodes
        requirements = overtikz.ReplacementRequirementFlags;
    end
    methods
        function obj = ReplacementPropertyCell(varargin)
            p = inputParser();
            p.addRequired('objectHandle')
            p.addRequired('objectProperty')
            p.addRequired('subNodes')
            p.parse(varargin{:});
            
            obj.objectHandle = p.Results.objectHandle;
            obj.objectProperty = p.Results.objectProperty;
            obj.subNodes = p.Results.subNodes;
        end
        function strRes = toTikzNode(obj)
            childStrRes = arrayfun(...
                @(tickLabelNode) tickLabelNode.toTikzNode(), ...
                obj.subNodes, 'UniformOutput', false ...
            );
            
            strRes = childStrRes;
        end
        function clearNode(obj)
            xtix = get(obj.objectHandle, obj.objectProperty);
            emptyObj = arrayfun(@(x) blanks(0),...
                1:length(xtix), ...
                'UniformOutput', false);
            set(obj.objectHandle, ...
                obj.objectProperty, emptyObj);
        end
        function resStr = restoreNode(obj)
            labels = arrayfun(@(child) child.restoreNode(), ...
                obj.subNodes, 'UniformOutput', false);
            set(obj.objectHandle, obj.objectProperty, labels);
            resStr = labels;
        end
        function requirements = getRequirements(obj)
            import overtikz.* 
            
            requirements = obj.requirements;
            if ~isempty(obj.subNodes)
                reqArr = getRequirementsArr(obj.subNodes);
                requirements = ReplacementRequirementFlags.fromFlagArray(...
                     reqArr ...
                );
            end
        end
    end
    methods(Access = public, Static)
        function obj = fromAxisProperty(axisHandle, tickProperty)
            import overtikz.*
            
            xmatches = regexp(tickProperty, '[xX]', 'match');
            ymatches = regexp(tickProperty, '[yY]', 'match');
            if ~isempty(xmatches)
                x_tix_labels = get(axisHandle, tickProperty);
                x_tix = getXtickPositions(axisHandle);
                dim = axisHandle.Position;
                xxlim = cumsum([dim(1), dim(3)]);
                x_tix = sort(x_tix( ....
                    x_tix(:, 1) >= xxlim(1) & ...
                    x_tix(:, 1) <= xxlim(2),  ...
                    : ...
                ));
                [M,~] = size(x_tix);
                if M ~= numel(x_tix_labels)
                    error( ...
                        [...
                        'overtikz:ReplacementPropertyCell:' ...
                        'fromAxisProperty:xTickLabelMismatch'...
                        ], ...
                        [ ...
                            'Number of xTicks: %d, not equal to ' ...
                            'number of xTickLabels: %d.' ...
                        ], ...
                        M, ...
                        numel(x_tix_labels) ...
                    )
                end
                
                if isempty(x_tix)
                    obj = [];
                    return
                end
                
                % these are usually placed too high move down
                [M,~] = size(x_tix);
                orientation = axisHandle.XAxisLocation;
                if strcmpi(orientation, 'bottom')
                    sgn = -1;
                    anchor = ReplacementTextNodeAnchor.North;
                else
                    sgn = 1;
                    anchor = ReplacementTextNodeAnchor.South;
                end
                amnt = unitToNorm([0, 0.1], axisHandle, 'centimeters');
                x_tix(:, 2) = x_tix(:, 2) + sgn*amnt(2)*ones(M, 1);
                
                
                N = numel(x_tix_labels);
                
                tickLabelNodes = arrayfun( ...
                    @(x,y,txt) ReplacementTextNode.fromHandless(...
                        [x, y], txt{:}, ...
                        anchor, ...
                        'scale', 0.8, ...
                        'horizontalCorrection', true ...
                    ), ...
                    x_tix(1:N,1), x_tix(1:N,2), x_tix_labels ...
                );
                
            elseif ~isempty(ymatches)
                y_tix_labels = get(axisHandle, tickProperty);
                y_tix = getYtickPositions(axisHandle);
                dim = axisHandle.Position;
                yylim = cumsum([dim(2), dim(4)]);
                y_tix = sort(y_tix( ....
                    y_tix(:, 2) >= yylim(1) & ...
                    y_tix(:, 2) <= yylim(2),  ...
                    : ...
                ));
                [M,~] = size(y_tix);
                if M ~= numel(y_tix_labels)
                    error( ...
                        [...
                        'overtikz:ReplacementPropertyCell:' ...
                        'fromAxisProperty:yTickLabelMismatch'...
                        ], ...
                        [ ...
                            'Number of yTicks: %d, not equal to ' ...
                            'number of yTickLabels: %d.' ...
                        ], ...
                        M, ...
                        numel(y_tix_labels) ...
                    )
                end
                
                if isempty(y_tix)
                    obj = [];
                    return
                end
                
                % these are usually placed too rightward move left
                orientation = axisHandle.YAxisLocation;
                if strcmpi(orientation, 'left')
                    sgn = -1;
                    anchor = ReplacementTextNodeAnchor.East;
                else
                    sgn = 1;
                    anchor = ReplacementTextNodeAnchor.West;
                end
                amnt = unitToNorm([0.05, 0], axisHandle, 'centimeters');
                y_tix(:, 1) = y_tix(:, 1) + sgn*amnt(1)*ones(M, 1);
                
                tickLabelNodes = arrayfun( ...
                    @(x,y,txt) ReplacementTextNode.fromHandless(...
                        [x, y], txt{:}, ...
                        anchor), ...
                    y_tix(:,1), y_tix(:,2), y_tix_labels ...
                );
            else
                MSGID = ['overtikz:ReplacementPropertyCell:' ...
                    'fromAxisProperty:invalidProperty'];
                error(MSGID, 'No Axis X/Y Tick Label Property %s.\n', ...
                    tickProperty)
            end
            
            obj = ReplacementPropertyCell(axisHandle, ...
                                tickProperty, tickLabelNodes);
        end
        function obj = fromGraphPlot(graphHandle, graphProperty)
            import overtikz.*
            
            axisHandle = graphHandle.Parent;
            
            oldUnits = axisHandle.Units;
            axisHandle.Units = 'Pixels';
            dim = axisHandle.Position;
            wPx = dim(3); hPx = dim(4);
            axisHandle.Units = oldUnits;
            x0 = axisHandle.XLim(1); y0 = axisHandle.YLim(1);
            w = diff(axisHandle.XLim); h = diff(axisHandle.YLim);
            toPx = @(x) diag([wPx/w, hPx/h])*(x-[x0; y0]);
            toAx = @(x) (diag([w/wPx, h/hPx])*x)+[x0; y0];
            
            if contains(graphProperty, 'edge', 'IgnoreCase', true)
                labels = get(graphHandle, 'edgeLabel');
                
                % Undocumented Property 'BasicGraph_'
                wStrct = warning('query', 'MATLAB:structOnObject');
                wErs = warning('query', 'MATLAB:hg:EraseModeIgnored');
                warning('off','MATLAB:structOnObject')
                warning('off','MATLAB:hg:EraseModeIgnored')
                edges = struct(graphHandle).BasicGraph_.Edges;
                edgeCoord = struct(graphHandle).EdgeCoords_(:, 1:2);
                edgeCoordIndex = struct(graphHandle).EdgeCoordsIndex_;
                warning(wStrct.state, 'MATLAB:structOnObject')
                warning(wErs.state, 'MATLAB:hg:EraseModeIgnored')
                
                [N,~] = size(edges);
                
                xx = get(graphHandle, 'xData');
                yy = get(graphHandle, 'yData');
                
                xRaw = zeros(1, N);
                yRaw = zeros(1, N);
                
                for ii=1:N
                    anchor = ReplacementTextNodeAnchor.Center;
                    path = edgeCoord(edgeCoordIndex==ii, :);
                    
                    [midPointPx, dVectPx] = midAlongPath(toPx(path.').');
                    
                    perpVectPx = [-dVectPx(2); dVectPx(1)];
                    if perpVectPx(2) < 0
                        perpVectPx = -1*perpVectPx;
                    end
                    perpVectPx = perpVectPx/norm(perpVectPx);
                    
                    pnt = toAx(8 * perpVectPx + midPointPx);
                    
                    xRaw(ii) = pnt(1); yRaw(ii) = pnt(2);
                end
            else
                anchor = ReplacementTextNodeAnchor.West;
                labels = get(graphHandle, 'nodeLabel');
                offset = toAx([3; 0])-[x0; y0];
                xRaw = get(graphHandle, 'xData') + offset(1);
                yRaw = get(graphHandle, 'yData');
            end
            if isempty(labels)
                obj = [];
                return
            end
            
            C = arrayfun(@(x, y) dataToNorm([x, y], axisHandle), ...
                xRaw.' , yRaw.', 'UniformOutput', false);
            pos = cell2mat(C);

            subNodes = arrayfun( ...
                @(x,y,txt) ReplacementTextNode.fromHandless(...
                    [x, y], txt{:}, ...
                    anchor, ...
                    'scale', 0.8, ...
                    'horizontalCorrection', true ...
                ), ...
                pos(:,1), pos(:,2), labels(:) ...
            );

            obj = ReplacementPropertyCell(graphHandle, ...
                                graphProperty, subNodes);
        end
    end
end

function coordArr = getXtickPositions(axisHandle)
    import overtikz.*
    orientation = axisHandle.XAxisLocation;
    if strcmpi(orientation, 'bottom')
        y_d = min(axisHandle.YLim);
    else
        y_d = max(axisHandle.YLim);
    end
    x_tix = axisHandle.XTick;
    C = arrayfun(@(x_d) dataToNorm([x_d, y_d], axisHandle), ...
        x_tix.', 'UniformOutput', false);
    coordArr = cell2mat(C);
end

function coordArr = getYtickPositions(axisHandle)
    import overtikz.*
    orientation = axisHandle.YAxisLocation;
    if strcmpi(orientation, 'left')
        x_d = min(axisHandle.XLim);
    else
        x_d = max(axisHandle.XLim);
    end
    y_tix = axisHandle.YTick;
    C = arrayfun(@(y_d) dataToNorm([x_d, y_d], axisHandle), ...
        y_tix.', 'UniformOutput', false);
    coordArr = cell2mat(C);
end

function resPos = unitToNorm(pos, axisHandle, unitName)
    oldUnits = axisHandle.Units;
    axisHandle.Units = unitName;
    inUnits = axisHandle.Position(1:2);
    axisHandle.Units = 'normalized';
    normUnits = axisHandle.Position(1:2);
    axisHandle.Units = oldUnits;
    
    coeff = normUnits./inUnits;
    resPos = pos.*coeff;
end


function [midpoint, dVect] = midAlongPath(u)
    [M, ~] = size(u);
    du = diff(u);
    dists = arrayfun(@(ii) norm(du(ii,:),2), 1:M-1).';
    cumDists = cumsum(dists);
    totalDist = cumDists(end);
    midDist = totalDist*0.5;
    ii = find(cumDists >= midDist, 1);
    
    x1 = u(ii,     1); y1 = u(ii,     2);
    x2 = u(ii + 1, 1); y2 = u(ii + 1, 2);
    
    midpoint = [x1+x2; y1+y2]/2;
    
    dVect = [x2-x1; y2-y1];
end