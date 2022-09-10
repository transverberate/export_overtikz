classdef ReplacementPropertyCell < overtikz.ReplacementInterface
    properties
        objectHandle
        objectProperty
        subNodes
        customClearBlanks
        requirements = overtikz.ReplacementRequirementFlags;
    end
    methods
        function obj = ReplacementPropertyCell(varargin)
            p = inputParser();
            p.addRequired('objectHandle')
            p.addRequired('objectProperty')
            p.addRequired('subNodes')
            p.addParameter('customClearBlanks', []);
            p.parse(varargin{:});
            
            obj.objectHandle = p.Results.objectHandle;
            obj.objectProperty = p.Results.objectProperty;
            obj.subNodes = p.Results.subNodes;
            obj.customClearBlanks = p.Results.customClearBlanks;
        end
        function strRes = toTikzNode(obj)
            childStrRes = arrayfun(...
                @(tickLabelNode) tickLabelNode.toTikzNode(), ...
                obj.subNodes, 'UniformOutput', false ...
            );
            
            strRes = childStrRes;
        end
        function clearNode(obj)
            objectPrevValue = get(obj.objectHandle, obj.objectProperty);
            if ~isempty(obj.customClearBlanks)
                emptyObj = obj.customClearBlanks;
            else
                emptyObj = arrayfun(@(x) blanks(0),...
                    1:length(objectPrevValue), ...
                    'UniformOutput', false);
            end
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

