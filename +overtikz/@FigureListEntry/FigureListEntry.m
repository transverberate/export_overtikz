classdef FigureListEntry < handle
    properties
        includeFile
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
            commandName, ...
            includeCmd, ...
            includeArgs, ...
            figFloat, ...
            figCaption, ...
            figLabel ...
        )
            obj.includeFile = includeFile;
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
            includeStr = ['\\' escapeStr(figEntry.includeCmd) ...
                escapeStr(figEntry.includeArgs) '{' ...
                escapeStr(figEntry.includeFile) '}'];
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
            tf = isprop(obj2, 'includeFile');
            if tf==true
                tf = strcmp(obj1.includeFile, obj2.includeFile);
            end
        end
    end
    methods(Access = public, Static)
        function obj = fromBaseName(varargin)
            
            import overtikz.FigureListEntry
            
            p = inputParser;
            p.addRequired('baseName');
            p.addOptional('includeArgs', 'mode=buildmissing');
            p.parse(varargin{:});
            
            baseName = p.Results.baseName;
            includeArgs = p.Results.includeArgs;
            
            includeFile = baseName;

            commandName = santizeCmdName( ...
                ['fig' sm_capitalize(baseName)]);

            includeCmd = 'includestandalone';
            includeArgsStr = ['[' includeArgs ']'];
            figFloat = '[H]';
            figCaption = santizeCmdName( ...
                ['\cpt' sm_capitalize(baseName)]);
            figLabel = ['fig:' baseName];

            obj = FigureListEntry( ...
                includeFile, ...
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
        '\{(?<includeFile>[\sA-z\._\d\\\/]+)\}\s*(%.*?\n)?\s*\}'...
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
    if ~isempty(tokens.includeFile)
        valsStruct.includeFile = tokens.includeFile;
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

