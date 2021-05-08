classdef ReplacementTicks < tex_export.ReplacementInterface
    properties
        axisHandle
        tickProperty
        tickLabelNodes
        requirements = tex_export.ReplacementRequirementFlags;
    end
    methods
        function obj = ReplacementTicks(varargin)
            p = inputParser();
            p.addRequired('axisHandle')
            p.addRequired('tickProperty')
            p.addRequired('tickLabelNodes')
            p.parse(varargin{:});
            
            obj.axisHandle = p.Results.axisHandle;
            obj.tickProperty = p.Results.tickProperty;
            obj.tickLabelNodes = p.Results.tickLabelNodes;
        end
        function strRes = toTikzNode(obj)
            childStrRes = arrayfun(...
                @(tickLabelNode) tickLabelNode.toTikzNode(), ...
                obj.tickLabelNodes, 'UniformOutput', false);
%                 strRes = [{sprintf('%% Axis\n')}; childStrRes];
                strRes = childStrRes;
        end
        function clearNode(obj)
            xtix = get(obj.axisHandle, ...
                obj.tickProperty);
            set(obj.axisHandle, ...
                obj.tickProperty, cell(1, length(xtix)));
        end
        function resStr = restoreNode(obj)
            labels = arrayfun(@(child) child.restoreNode(), ...
                obj.tickLabelNodes, 'UniformOutput', false);
            set(obj.axisHandle, obj.tickProperty, labels);
            resStr = labels;
        end
        function requirements = getRequirements(obj)
            import tex_export.* 
            
            requirements = obj.requirements;
            if ~isempty(obj.tickLabelNodes)
                reqArr = getRequirementsArr(obj.tickLabelNodes);
                requirements = ReplacementRequirementFlags.fromFlagArray(...
                     reqArr ...
                );
            end
        end
    end
    methods(Access = public, Static)
        function obj = fromAxisProperty(axisHandle, tickProperty)
            import tex_export.*
            
            xmatches = regexp(tickProperty, '[xX]', 'match');
            ymatches = regexp(tickProperty, '[yY]', 'match');
            if ~isempty(xmatches)
                x_tix_labels = get(axisHandle, tickProperty);
                x_tix = getXtickPositions(axisHandle);
                
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
                
                tickLabelNodes = arrayfun( ...
                    @(x,y,txt) ReplacementTextNode.fromTicks(...
                        [x, y], txt{:}, ...
                        anchor, ...
                        'horizontalCorrection', true ...
                    ), ...
                    x_tix(:,1), x_tix(:,2), x_tix_labels ...
                );
                
            elseif ~isempty(ymatches)
                y_tix_labels = get(axisHandle, tickProperty);
                y_tix = getYtickPositions(axisHandle);
                
                if isempty(y_tix)
                    obj = [];
                    return
                end
                
                % these are usually placed too rightward move left
                [M,~] = size(y_tix);
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
                    @(x,y,txt) ReplacementTextNode.fromTicks(...
                        [x, y], txt{:}, ...
                        anchor), ...
                    y_tix(:,1), y_tix(:,2), y_tix_labels ...
                );
            else
                MSGID = ['tex_export::ReplacementTicks::' ...
                    'fromAxisProperty::invalidProperty'];
                error(MSGID, 'No Axis X/Y Tick Label Property %s.\n', ...
                    tickProperty)
            end
            
            obj = ReplacementTicks(axisHandle, ...
                                tickProperty, tickLabelNodes);
        end
    end
end

function coordArr = getXtickPositions(axisHandle)
    import tex_export.*
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
    import tex_export.*
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