classdef ReplacementTextNodeAnchor < uint32
    enumeration
        North           (1)
        NorthEast       (2) 
        East            (3) 
        SouthEast       (4)
        South           (5)
        SouthWest       (6)
        West            (7) 
        NorthWest       (8)
        Base            (9)
        Center          (10)
        Mid             (11)
    end
    methods 
        function strRes = toTikz(obj)
            vals = { 
                'north'
                'north east'
                'east'
                'south east'
                'south'
                'south west'
                'west'
                'north west'
                'base'
                'center'
                'mid'
            };
            strRes = vals{obj};
        end
    end
    methods(Access = public, Static)
        function obj = fromTextProp(hStr, vStr, doInvert)
            arguments
                hStr char
                vStr char
                doInvert logical = false
            end
            import overtikz.*
            vertIdx = containers.Map({ ...
                'bottom', ...
                'top', ...
                'middle', ...
                'baseline', ...
                }, ...
                { ...
                    1
                    -1
                    0
                    0
                } ...
            );
            horizIdx = containers.Map({ ...
                'left', ...
                'center', ...
                'right', ...
                }, ...
                { ...
                    -1
                    0
                    1
                } ...
            );
            if strcmp(hStr, 'center') && (strcmp(vStr, 'middle') || strcmp(vStr, 'baseline') )
                vertSel = containers.Map({ ...
                    'bottom', ...
                    'top', ...
                    'middle', ...
                    'baseline', ...
                    }, ...
                    { ...
                        ReplacementTextNodeAnchor.South, ...
                        ReplacementTextNodeAnchor.North, ...
                        ReplacementTextNodeAnchor.Mid, ...
                        ReplacementTextNodeAnchor.Base ...
                    } ...
                );
                obj = vertSel(vStr);
            else
                x = horizIdx(hStr);
                y = vertIdx(vStr);
                if doInvert
                    x = -x;
                    y = -y;
                end
                x = x + 2;
                y = y + 2;
                vertSel = {
                    ReplacementTextNodeAnchor.NorthWest, ReplacementTextNodeAnchor.North, ReplacementTextNodeAnchor.NorthEast
                    ReplacementTextNodeAnchor.West, ReplacementTextNodeAnchor.Mid, ReplacementTextNodeAnchor.East
                    ReplacementTextNodeAnchor.SouthWest, ReplacementTextNodeAnchor.South, ReplacementTextNodeAnchor.SouthEast
                };
                obj = vertSel{y, x};
            end
        end
    end
end