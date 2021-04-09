classdef ReplacementInterface < matlab.mixin.Heterogeneous
    methods (Abstract)
        toTikzNode(obj)
        clearNode(obj)
        restoreNode(obj)
    end
    methods (Static, Sealed, Access = protected)
      function defaultObject = getDefaultScalarElement
         defaultObject = tex_export.ReplacementTextNode([0,0], '');
      end
    end
    methods (Sealed)
        function clearNodes(obj)
             n = numel(obj);
             for k=1:n
                clearNode(obj(k));
             end
        end
        function restoreNodes(obj)
             n = numel(obj);
             for k=1:n
                restoreNode(obj(k));
             end
        end
    end
end