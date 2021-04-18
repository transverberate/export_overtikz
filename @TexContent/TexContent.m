classdef TexContent < handle
    properties
        texStr = '';
        originalInput = '';
        isMath = false;
        isNegative = false;
        isNegativePhantom = false;
        isSubSuper = false;
        subscript = '';
        superscript = '';
        requiresNegativePhantom = false;
    end
    methods
        function obj = TexContent(varargin)
            p = inputParser;
            p.addRequired('texStr');
            p.addOptional('originalInput', '');
            p.addOptional('isMath', false, @islogical);
            p.addOptional('isNegative', false, @islogical);
            p.addOptional('isNegativePhantom', false, @islogical);
            p.addOptional('isSubSuper', false, @islogical);
            p.addOptional('subscript', '', @ischar);
            p.addOptional('superscript', '', @ischar);
            p.addOptional('requiresNegativePhantom', false, @islogical);
            p.parse(varargin{:});
            
            texStr = p.Results.texStr;
            originalInput = p.Results.originalInput;
            isMath = p.Results.isMath;
            isNegative = p.Results.isNegative;
            isNegativePhantom = p.Results.isNegativePhantom;
            isSubSuper = p.Results.isSubSuper;
            subscript = p.Results.subscript;
            superscript = p.Results.superscript;
            requiresNegativePhantom = p.Results.requiresNegativePhantom;
            
            obj.texStr = texStr;
            obj.originalInput = originalInput;
            obj.isMath = isMath;
            obj.isNegative = isNegative;
            obj.isNegativePhantom = isNegativePhantom;
            obj.isSubSuper = isSubSuper;
            obj.subscript = subscript;
            obj.superscript = superscript;
            obj.requiresNegativePhantom = requiresNegativePhantom;
        end
        function resStr = toTexStr(obj)
            resStr = obj.texStr;
            phantomSpace = '';
            if obj.isSubSuper
                subSuper = addSubSuper(resStr, ...
                    obj.subscript, obj.superscript);
                phantomSpace = [
                    '\negphantom{' resStr '}' ...
                    '\phantom{' subSuper '}' ...
                ];
                resStr = subSuper;
            end
            if obj.isNegative
                resStr = ['-' resStr];
            end
            if obj.requiresNegativePhantom && obj.isNegative
                phantomSpace = ['\negphantom{-}' phantomSpace];
            end
            resStr = [phantomSpace resStr];
            if obj.isMath
                resStr = ['$' resStr '$'];
            end
        end
    end
    methods(Access = public, Static)
        function obj = fromStr(varargin)
            import tex_export.*
            
            p = inputParser;
            p.addRequired('inputStr');
            p.addOptional('ensureMath', false, @islogical);
            p.addOptional('horizontalCorrection', false, @islogical);
            p.parse(varargin{:});
            
            inputStr = char(p.Results.inputStr);
            ensureMath = p.Results.ensureMath;
            horizontalCorrection = p.Results.horizontalCorrection;
            isNegative = false;
            isNegativePhantom = false;
            isSubSuper = false;
            subscript = '';
            superscript = '';
            requiresNegativePhantom = false;
            
            [isMath, texStr] = removeMath(inputStr);
            
            if isMath || ensureMath
                [isNegative, texStr] = removeNegative(texStr);
                isNegativePhantom = isNegative && horizontalCorrection;
            
                if horizontalCorrection
                    [isSubSuper, subscript, superscript, texStr] = ...
                    removeSubSuper(texStr);
                end
            
                requiresNegativePhantom = isNegativePhantom | isSubSuper;
            end
            
            obj = TexContent(texStr, ...
                'originalInput', inputStr, ...
                'isMath', ensureMath | isMath, ...
                'isNegative', isNegative, ...
                'isNegativePhantom', isNegativePhantom, ...
                'isSubSuper', isSubSuper, ...
                'subscript', subscript, ...
                'superscript', superscript, ...
                'requiresNegativePhantom', requiresNegativePhantom ...
            );
        end
        function res = getNegativePhantomImplementation()
            res = { ...
                	'% Negative Phantom Function',  ...
                    '% Taken from answer provided by "egreg" at https://tex.stackexchange.com/questions/316426/negative-phantom-inside-equations', ...
                    '% Under the Creative Commons Attribution-ShareAlike 2.5 Generic (CC BY-SA 2.5) license', ...
                    '\makeatletter', ...
                    '\@ifundefined{negph@wd}{', ...
                    '  \newlength{\negph@wd}', ...
                    '}{}', ...
                    '\DeclareRobustCommand{\negphantom}[1]{%', ...
                    '  \ifmmode', ...
                    '  \mathpalette\negph@math{#1}%', ...
                    '  \else', ...
                    '  \negph@do{#1}%', ...
                    '  \fi', ...
                    '}', ...
                    '\newcommand{\negph@math}[2]{\negph@do{$\m@th#1#2$}}', ...
                    '\newcommand{\negph@do}[1]{%', ...
                    '  \settowidth{\negph@wd}{#1}%', ...
                    '  \hspace*{-\negph@wd}%', ...
                    '}', ...
                    '\makeatother' ...
            };
        end
    end
end

function [isNegative, resStr] = removeNegative(inStr)
    negativeExp = '^\s*-(.+)$';
    tokens = regexp(inStr, negativeExp, 'tokens');
    resStr = inStr;
    isNegative = false;
    if ~isempty(tokens)
        resStr = tokens{1}{1};
        isNegative = true;
    end
end

function [isMath, resStr] = removeMath(inStr)
    mathExp = '(?<!\\)\$(.*?)(?<!\\)\$';
    tokens = regexp(inStr, mathExp, 'tokens');
    resStr = inStr;
    isMath = false;
    if ~isempty(tokens)
        resStr = tokens{1}{1};
        isMath = true;
    end
end

function [isSubSuper, subscript, superscript, base] = removeSubSuper(inStr)
    subSuperExp = ['^\s*(?<base>.*?)(?<type1>[\^_])'...
        '(?<arg1>(\\[A-z]+)?\{(.*?)\}|.)' ...
        '(?<remain>(?<type2>[\^_])(?<arg2>(\\[A-z]+)?\{(.*?)\}|.))?\s*$'];
    remainderExp = '^(?<type2>[\^_])(?<arg2>(\\[A-z]+)?\{(.*?)\}|.)$';
    
    isSubSuper = false;
    subscript = '';
    superscript = '';
    base = inStr;
    
    tokens = regexp(inStr, subSuperExp, 'names');
    if ~isempty(tokens)
        isSubSuper = true;
        firstType = tokens.type1;
        firstArg = tokens.arg1;
        base = tokens.base;
        % second set?
        remainder = tokens.remain;
        secondType = [];
        secondArg = [];
        
        secondTokens = regexp(remainder, remainderExp, 'names');
        if ~isempty(secondTokens)
            secondType = secondTokens.type2;
            secondArg = secondTokens.arg2;
        end
        scrTypes = { firstType; secondType};
        scrArgs = { firstArg; secondArg};
        for i=1:2
            scrType = scrTypes{i};
            scrArg = scrArgs{i};
            if ~isempty(scrType)
                if strcmp(scrType, '_')
                    subscript = scrArg;
                elseif strcmp(scrType, '^')
                    superscript = scrArg;
                end
            end
        end
    end
end

function resStr = addSubSuper(base, subscript, superscript)
    subStr = '';
    superStr = '';
    if ~isempty(subscript)
        subStr = ['_' subscript];
    end
    if ~isempty(superscript)
        superStr = ['^' superscript];
    end
    resStr = [base, subStr, superStr];
end