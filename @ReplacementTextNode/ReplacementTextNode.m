classdef ReplacementTextNode < tex_export.ReplacementInterface
    properties
        scale = 1;
        nodeContent = tex_export.TexContent('');
        anchor = tex_export.ReplacementTextNodeAnchor.Base;
        alignment = 'center';
        position = [0, 0];
        rotate = 0;
        eHandle = 0;
        origContent = '';
        requirements = tex_export.ReplacementRequirementFlags();
    end
    methods
        function obj = ReplacementTextNode(varargin)
            import tex_export.*
            p = inputParser;
            p.addRequired('position');
            p.addRequired('content');
            p.addOptional('handle', gobjects(0));
            p.addOptional('anchor', ReplacementTextNodeAnchor.Base);
            p.addOptional('alignment', 'center');
            p.addOptional('scale', 1);
            p.addOptional('rotate', 0);
            p.addOptional('origContent', 0);
            p.parse(varargin{:});
            
            obj.position = p.Results.position;
            obj.nodeContent = p.Results.content;
            obj.anchor = p.Results.anchor;
            obj.alignment = p.Results.alignment;
            obj.scale = p.Results.scale;
            obj.rotate = p.Results.rotate;
            obj.eHandle = p.Results.handle;
            obj.requirements = tex_export.ReplacementRequirementFlags();
            if ~isempty(p.Results.origContent)
                obj.origContent = p.Results.origContent;
            else
                obj.origContent = obj.nodeContent.originalInput;
            end
        end
        function strRes = toTikzNode(obj)
            x = obj.position(1);
            y = obj.position(2);
            texStr = obj.nodeContent.toTexStr();
            strRes = sprintf([ ...
                '\\node[anchor=%s, align=%s, scale=%f, rotate=%f]' ...
                ' at (% 9.8f, % 9.8f) {%s};\n'],        ...
                obj.anchor.toTikz(),     ...
                obj.alignment,  ...
                obj.scale,      ...
                obj.rotate,     ...
                x,              ...
                y,              ...
                texStr          ...
            );
        end
        function clearNode(obj)
            h = obj.eHandle;
            if isvalid(h)
                if isprop(h, 'String')
                    h.String = '';
                end
            end
        end
        function resStr = restoreNode(obj)
            h = obj.eHandle;
            resStr = obj.nodeContent.originalInput;
            if isvalid(h)
                if isprop(h, 'String')
                    h.String = resStr;
                end
            end
        end
        function requirements = getRequirements(obj)
            requirements = obj.requirements;
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
                position = dataToNorm(textHandle.Position, axesNormalize);
            else
                position = textHandle.Position(1:2);
            end
            
            origContent = textHandle.String;
            
            nodeContent = TexContent.fromStr(textHandle.String, ...
                'ensureMath', isMath ...
            );
 

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
                'anchor', anchor, 'rotate', rotation, ...
                'handle', textHandle, ...
                'origContent', origContent);
        end
        function obj = fromTicks(varargin)
            import tex_export.*
            
            p = inputParser;
            p.addRequired('pos');
            p.addRequired('txt');
            p.addOptional('anchor', ReplacementTextNodeAnchor.Base);
            p.addOptional('horizontalCorrection', false);
            p.parse(varargin{:});
            
            pos = p.Results.pos;
            txt = p.Results.txt;
            anchor = p.Results.anchor;
            horizontalCorrection = p.Results.horizontalCorrection;
            
            nodeContent = TexContent.fromStr(txt, ...
                'ensureMath', true, ...
                'horizontalCorrection', horizontalCorrection ...
            );
            
            obj = ReplacementTextNode(...
                pos, nodeContent, 'scale', 0.8, ...
                'anchor', anchor, ...
                'origContent', txt);
            
            if nodeContent.requiresNegativePhantom
                obj.requirements.requireNegativePhantom = ...
                    nodeContent.requiresNegativePhantom;
            end
        end
    end
end
