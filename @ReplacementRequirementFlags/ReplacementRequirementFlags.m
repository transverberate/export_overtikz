classdef ReplacementRequirementFlags < handle
    properties
        requireNegativePhantom logical = false
    end
    methods 
        function obj = ReplacementRequirementFlags()
            obj.requireNegativePhantom = false;
        end
        function res = getTikzRequirements(obj)
            import tex_export.*
            
            res = {};
            if obj.requireNegativePhantom
                impl = TexContent.getNegativePhantomImplementation();
                res = [res, impl{:}];
            end
        end
    end
    methods(Access = public, Static)
        function obj = fromFlagArray(reqArr)
            import tex_export.*
            
            obj = ReplacementRequirementFlags();
            for req=[reqArr{:}]
                obj.requireNegativePhantom = ...
                    obj.requireNegativePhantom | req.requireNegativePhantom;
            end
        end
    end
end