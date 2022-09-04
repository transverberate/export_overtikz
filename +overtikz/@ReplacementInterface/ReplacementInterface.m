classdef ReplacementInterface < matlab.mixin.Heterogeneous
    methods (Abstract)
        toTikzNode(obj)
        clearNode(obj)
        restoreNode(obj)
        getRequirements(obj)
    end
    methods (Static, Sealed, Access = protected)
      function defaultObject = getDefaultScalarElement
         defaultObject = overtikz.ReplacementTextNode([0,0], '');
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
        function reqArr = getRequirementsArr(obj)
             n = numel(obj);
             reqArr = cell(n,1);
             for k=1:n
                reqArr{k,1} = getRequirements(obj(k));
             end
        end
    end
end