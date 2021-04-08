classdef ReplacementTextNode < handle
    properties
        scale = 1;
        nodeContent = '';
        anchor = tex_export.ReplacementTextNodeAnchor.Base;
        alignment = 'center';
        position = [0, 0];
        rotate = 0;
    end
    methods
        function obj = ReplacementTextNode(varargin)
            import tex_export.*
            p = inputParser;
            p.addRequired('position');
            p.addRequired('content');
            p.addOptional('anchor', ReplacementTextNodeAnchor.Base);
            p.addOptional('alignment', 'center');
            p.addOptional('scale', 1);
            p.addOptional('rotate', 0);
            p.parse(varargin{:});
            
            obj.position = p.Results.position;
            obj.nodeContent = char(p.Results.content);
            obj.anchor = p.Results.anchor;
            obj.alignment = p.Results.alignment;
            obj.scale = p.Results.scale;
            obj.rotate = p.Results.rotate;
        end
        function strRes = toTikzNode(obj)
            x = obj.position(1);
            y = obj.position(2);
            strRes = sprintf([ ...
                '\\node[anchor=%s, align=%s, scale=%f, rotate=%f]' ...
                ' at (% 9.8f, % 9.8f) {%s};'],        ...
                obj.anchor.toTikz(),     ...
                obj.alignment,  ...
                obj.scale,      ...
                obj.rotate,     ...
                x,              ...
                y,              ...
                obj.nodeContent ...
            );
        end
    end
    methods(Access = public, Static)
        function obj = fromTextObj(varargin)
            import tex_export.*
            
            p = inputParser;
            p.addRequired('textHandle');
            p.addOptional('normalize', []);
            p.addOptional('isMath', false);
            p.parse(varargin{:});
            textHandle = p.Results.textHandle;
            axesNormalize = p.Results.normalize;
            isMath = p.Results.isMath;
            
            if ~isempty(axesNormalize)
                position = dataCoord2Norm(textHandle, axesNormalize);
            else
                position = textHandle.Position(1:2);
            end
            
            if isMath
                nodeContent = makeTexMath(char(textHandle.String));
            else
                nodeContent = char(textHandle.String);
            end

            anchor = ReplacementTextNodeAnchor.fromTextProp(...
                textHandle.HorizontalAlignment, ...
                textHandle.VerticalAlignment ...
            );
            
            if isprop(textHandle, 'Rotation')
                rotation = textHandle.Rotation;
            elseif isprop(textHandle, 'TextRotation')
                rotation = textHandle.TextRotation;
            else
                rotation = 0;
            end
            
            obj = ReplacementTextNode(position, nodeContent, ...
                'anchor', anchor, 'rotate', rotation);
        end
    end
end

function normalizedPosition = dataCoord2Norm(elementHandle, axesHandle)
    origUnits = elementHandle.Units;
    elementHandle.Units = "normalized";
    elementPosition = elementHandle.Position;
    x = elementPosition(1);
    y = elementPosition(2);

    axesPosition = axesHandle.Position;
    x_a = axesPosition(1);
    y_a = axesPosition(2);
    w_a = axesPosition(3);
    h_a = axesPosition(4);

    xn = x*w_a + x_a;
    yn = y*h_a + y_a;

    normalizedPosition = [xn, yn];
    elementHandle.Units = origUnits;
end