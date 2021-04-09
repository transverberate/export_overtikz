classdef ReplacementTicks < tex_export.ReplacementInterface
    properties
        axisHandle
        tickProperty
        tickLabelNodes
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
    end
    methods(Access = public, Static)
        function obj = fromAxisProperty(axisHandle, tickProperty)
            import tex_export.*
            
            xmatches = regexp(tickProperty, '[xX]', 'match');
            ymatches = regexp(tickProperty, '[yY]', 'match');
            if ~isempty(xmatches)
                x_tix_labels = get(axisHandle, tickProperty);
                x_tix = getXtickPositions(axisHandle);
                
                tickLabelNodes = arrayfun( ...
                    @(x,y,txt) ReplacementTextNode.fromTicks(...
                        [x, y], txt{:}, ...
                        ReplacementTextNodeAnchor.North),...
                    x_tix(:,1), x_tix(:,2), x_tix_labels ...
                );
                
            elseif ~isempty(ymatches)
                y_tix_labels = get(axisHandle, tickProperty);
                y_tix = getYtickPositions(axisHandle);
                
                tickLabelNodes = arrayfun( ...
                    @(x,y,txt) ReplacementTextNode.fromTicks(...
                        [x, y], txt{:}, ...
                        ReplacementTextNodeAnchor.East), ...
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
    y_d = min(axisHandle.YLim);
    x_tix = axisHandle.XTick;
    C = arrayfun(@(x_d) dataToNorm([x_d, y_d], axisHandle), ...
        x_tix.', 'UniformOutput', false);
    coordArr = cell2mat(C);
end

function coordArr = getYtickPositions(axisHandle)
    import tex_export.*
    x_d = min(axisHandle.XLim);
    y_tix = axisHandle.YTick;
    C = arrayfun(@(y_d) dataToNorm([x_d, y_d], axisHandle), ...
        y_tix.', 'UniformOutput', false);
    coordArr = cell2mat(C);
end