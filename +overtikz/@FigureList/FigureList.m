classdef FigureList < handle
    
    properties
        entryList
        auxList
        fName
    end
    methods
        function obj = FigureList(filename)
            obj.fName = 'figs.sty';
            if nargin > 0
                obj.fName = filename;
            end
            obj.entryList = {};
            obj.auxList = {};
            if isfile(obj.fName)
                obj = obj.loadList(obj.fName);
            else
                obj = obj.createList();
            end
        end
        
        function obj = loadList(obj, fName)
            import overtikz.FigureListEntry
            figFindExp = ['\\newcommand\{(?:.|[\n\r])*?\\begin' ...
                '\{\s*figure\s*\}(?:.|[\n\r])*?\\end\{\s*figure\s*\}' ...
                '(?:.|[\n\r])*?\}'];
            
            filecontent = fileread(fName);
            [matches, noMatch] = regexp( ...
                filecontent, figFindExp, 'match', 'split');
            obj.entryList = FigureListEntry.empty(0, length(matches));
            obj.auxList = arrayfun(@escapeStr, noMatch);
            i=1;
            for match=matches
                fList = FigureListEntry.fromTex(match{1});
                obj.entryList(i) = fList;
                i = i+1;
            end
        end
        
        function obj = addEntry(obj, entry)
            tf=sum(arrayfun(@(x) x == entry, obj.entryList)) > 0;
            if tf == false
                obj.entryList = [obj.entryList(:)' entry];
                obj.auxList = [obj.auxList(:)' {'\n\n'}];
            end
        end
        
        function obj = saveList(obj)
            texEntries = arrayfun(@(x) x.toTex(), ...
                obj.entryList, 'UniformOutput', false);
            
            resStr = strjoin(obj.auxList, texEntries);
            fid = fopen(obj.fName,'w');
            fprintf(fid, resStr);
            fclose(fid);
        end
        
        function obj = createList(obj)
            [packageDir, packageName, ~] = fileparts(obj.fName);
            packageRef = fullfile(packageDir, packageName);
            listHeadStr = [ '%% \\usepackage{' packageRef '}\n' ... 
                            '\\usepackage{float}\n' ...
                            '\\usepackage[subpreambles=true]{standalone}'...
                            '  %% REQUIRE\n\n'];
            
            obj.auxList = {listHeadStr};
        end
    end
end

function outStr = escapeStr(inStr)
    outStr = strrep(strrep(inStr, '\', '\\'), '%', '%%');
end