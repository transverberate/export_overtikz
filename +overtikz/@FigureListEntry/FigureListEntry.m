classdef FigureListEntry < handle
    properties
        includeFile
        includeDirectory
        commandName
        includeCmd
        includeArgs
        figFloat
        figCaption
        figLabel
    end
    methods(Access = public)
        function obj = FigureListEntry( ...
            includeFile, ...
            includeDirectory, ...
            commandName, ...
            includeCmd, ...
            includeArgs, ...
            figFloat, ...
            figCaption, ...
            figLabel ...
        )
            obj.includeFile = includeFile;
            obj.includeDirectory = includeDirectory;
            obj.commandName = commandName;
            obj.includeCmd = includeCmd;
            obj.includeArgs = includeArgs;
            obj.figFloat = figFloat;
            obj.figCaption = figCaption;
            obj.figLabel = figLabel;
        end
        
        function outstr = toTex(figEntry)

            commandHeadStr = ['\\newcommand{\\' ...
                escapeStr(figEntry.commandName) '}{'];
            figureHeadStr = ['\\begin{figure}' ...
                escapeStr(figEntry.figFloat)];
            centeringHeadStr = '\\centering{';
            
            if ~isempty(figEntry.includeDirectory)
                includePath = [figEntry.includeDirectory, '/', figEntry.includeFile];
            else
                includePath = figEntry.includeFile;
            end
            includeStr = ['\\' escapeStr(figEntry.includeCmd) ...
                escapeStr(figEntry.includeArgs) '{' ...
                escapeStr(includePath) '}'];
            
            centeringFootStr = '}';
            captionStr = [...
                '\t\t\\caption{%%\n' ...
                makeOptionalCommand(figEntry.figCaption, 3) ...
                '\t\t}%%\n' ...
            ];   
            labelStr = ['\\label{' escapeStr(figEntry.figLabel) '}'];    
            figureFootStr = '\\end{figure}';
            commandFootStr = '}';

            outstr = [ ...
                commandHeadStr '%%\n', ...
                '\t' figureHeadStr '%%\n' ...
                '\t\t' centeringHeadStr '%%\n' ...
                '\t\t\t' includeStr '%%\n' ...
                '\t\t' centeringFootStr '%%\n' ...
            	captionStr ...
            	'\t\t' labelStr '%%\n' ...
            	'\t' figureFootStr '%%\n' ...
            	commandFootStr ...
            ];
        end
        function tf = eq(obj1, obj2)
            tf = all([isprop(obj2, 'includeFile'), isprop(obj2, 'includeDirectory')]);
            if tf==true
                tf = all([ ...
                    strcmp(obj1.includeFile(:), obj2.includeFile(:)), ...
                    strcmp(obj1.includeDirectory(:), obj2.includeDirectory(:)) ...
                ]);
            end
        end
    end
    methods(Access = public, Static)
        function obj = fromBaseName(baseName, options)
            arguments
                baseName (1,:) char 
                options.includeDirectory (1,:) char = ''
                options.includeArgs (1,:) char = 'mode=buildmissing'
            end
            
            import overtikz.FigureListEntry
            
            includeFile = baseName;
            includeDirectory = options.includeDirectory;

            commandName = santizeCmdName( ...
                ['fig' sm_capitalize(baseName)]);

            includeCmd = 'includestandalone';
            includeArgsStr = ['[' options.includeArgs ']'];
            figFloat = '[H]';
            figCaption = santizeCmdName( ...
                ['\cpt' sm_capitalize(baseName)]);
            figLabel = ['fig:' baseName];

            obj = FigureListEntry( ...
                includeFile, ...
                includeDirectory, ...
                commandName, ...
                includeCmd, ...
                includeArgsStr, ...
                figFloat, ...
                figCaption, ...
                figLabel ...
            );
        end
        
        function obj = fromTex(texString)
            import overtikz.FigureListEntry
            
            valsStruct = parseTex(texString);
            
            obj = FigureListEntry( ...
                valsStruct.includeFile, ...
                valsStruct.includeDirectory, ...
                valsStruct.commandName, ...
                valsStruct.includeCmd, ...
                valsStruct.includeArgs, ...
                valsStruct.figFloat, ...
                valsStruct.figCaption, ...
                valsStruct.figLabel ...
            );
        end
    end
end

function valsStruct = parseTex(texString)
    
    valsStruct = struct( ...
        'includeFile', '', ...
        'includeDirectory', '', ...
        'commandName', '', ...
        'includeCmd', 'includestandalone', ...
        'includeArgs', '[mode=buildmissing]', ...
        'figFloat', '[H]', ...
        'figCaption', '', ...
        'figLabel', '' ...
    );

    cmdNameExpr = '\\newcommand\{\s*\\(?<cmdName>[A-z]+)\s*\}';
    figFloatExpr = '\\begin\{\s*figure\s*\}(?<float>\[[A-z\!]+\])?';
    inputCmdExpr =  [...
        '\\centering\s*\{\s*(%.*?\n)?\s*\\(?<includeCmd>[A-Za-z]*' ...
        '(?:include|input)[A-Za-z]*)' ...
        '(?<includeArgs>\[[A-z=~*+-\/,;:\.\?\\\s\d]+\])?'...
        '\{(?<includePath>[\sA-z\._\d\\\/]+)\}\s*(%.*?\n)?\s*\}'...
    ];
    captionExpr = '\\caption\s*\{\s*(%.*?\n)?\s*(?<caption>(?:.|[\n\r])*?)(?<!\\)\}';
    labelExpr = '\\label\s*\{(?<label>(?:.|[\n\r])*?)(?<!\\)\}';
    
    tokens = regexp(texString, cmdNameExpr, 'names', 'once');
    if ~isempty(tokens.cmdName)
        valsStruct.commandName = tokens.cmdName;
    end
    
    tokens = regexp(texString, figFloatExpr, 'names', 'once');
    if ~isempty(tokens.float)
        valsStruct.figFloat = tokens.float;
    end
    
    tokens = regexp(texString, inputCmdExpr, 'names', 'once');
    if ~isempty(tokens.includeCmd)
        valsStruct.includeCmd = tokens.includeCmd;
    end
    if ~isempty(tokens.includeArgs)
        valsStruct.includeArgs = tokens.includeArgs;
    end
    if ~isempty(tokens.includePath)
        pathTokens = strsplit(tokens.includePath, '/');
        valsStruct.includeFile = pathTokens{end};
        valsStruct.includeDirectory = strjoin(pathTokens(1:end-1), '/');
    end
    
    tokens = regexp(texString, captionExpr, 'names');
    if ~isempty(tokens.caption)
        captionCand = tokens.caption;
        valsStruct.figCaption = captionCand;
        match = parseOptionalCommand(captionCand);
        if ~isempty(match)
            valsStruct.figCaption = match;
        end
    end
    
    tokens = regexp(texString, labelExpr, 'names');
    if ~isempty(tokens.label)
        valsStruct.figLabel = tokens.label;
    end
end

function cmdName = santizeCmdName(basename)

    expression = '(\d+)';
    [match,noMatch] = regexp(basename, expression, 'match', 'split');
    
    fixNoMatch = [noMatch{1}, ...
        cellfun(@sm_capitalize, noMatch(2:end), 'UniformOutput', false)];
    options = { ...
        'hyphen', false,...
        'white', '',...
        'case', 'title',...
        'and', false ...
    };
    fixMatch = arrayfun(...
        @(x) num2words(x,options{:}), ...
        cellfun(@str2num, match), ...
        'UniformOutput', false);
    fixMatch = cellfun(@sm_capitalize, fixMatch, 'UniformOutput', false);
    cmdName = strjoin(fixNoMatch, fixMatch);
    
    expression = '_+';
    tokens = regexp(cmdName, expression, 'split');
    
    fixTokens = [tokens{1}, ...
        cellfun(@sm_capitalize, tokens(2:end), 'UniformOutput', false)];
    cmdName = strjoin(fixTokens, '');
end

function strout = sm_capitalize(word)
    strout = word;
    if length(strout)>1
        strout = [upper(word(1)) word(2:end)];
    end
end

function outStr = escapeStr(inStr)
    outStr = strrep(strrep(inStr, '\', '\\'), '%', '%%');
end

function result = parseOptionalCommand(inStr)
    optionalCommandExp = ['\\ifdefined\s*\\[\w]*\s*(%.*?\n)?\s*'...
        '(?<command>[\w\\]*?)(?<!\\)\s*(%.*?\n)?\s*\\else(?:.|[\n\r])*?\\fi'];
    tokens = regexp(inStr, optionalCommandExp, 'names', 'once');
    if ~isempty(tokens) && ~isempty(tokens.command)
        result = tokens.command;
        return
    end
    result = [];
end

function result = makeOptionalCommand(inStr, indentAmnt)
    if nargin < 2
        indentAmnt = 0;
    end
    csNameExp = '\s*\\*(?<csname>.*)';
    csName = inStr;
    tokens = regexp(inStr, csNameExp, 'names', 'once');
    if ~isempty(tokens.csname)
        csName = tokens.csname;
    end

    indentStr = repmat('\t', [1, indentAmnt]);

    result = [...
      indentStr, '\\ifdefined\\', csName, '%%\n', ...  
      indentStr, '\t\\', csName, '%%\n', ...
      indentStr, '\\else%%\n', ...
      indentStr, '\t\\textbackslash ', csName, '%%\n', ...
      indentStr, '\\fi%%\n' ...
    ];
end

