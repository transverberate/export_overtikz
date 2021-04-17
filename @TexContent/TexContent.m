classdef TexContent < handle
    properties
        texStr = '';
        originalInput = '';
        isMath = false;
        isNegative = false;
        requiresNegativePhantom = false;
    end
    methods
        function obj = TexContent(varargin)
            p = inputParser;
            p.addRequired('texStr');
            p.addOptional('originalInput', '');
            p.addOptional('isMath', false, @islogical);
            p.addOptional('isNegative', false, @islogical);
            p.addOptional('requiresNegativePhantom', false, @islogical);
            p.parse(varargin{:});
            
            texStr = p.Results.texStr;
            originalInput = p.Results.originalInput;
            isMath = p.Results.isMath;
            isNegative = p.Results.isNegative;
            requiresNegativePhantom = p.Results.requiresNegativePhantom;
            
            obj.texStr = texStr;
            obj.originalInput = originalInput;
            obj.isMath = isMath;
            obj.isNegative = isNegative;
            obj.requiresNegativePhantom = requiresNegativePhantom;
        end
        function resStr = toTexStr(obj)
            resStr = obj.texStr;
            if obj.isNegative
                resStr = ['-' resStr];
            end
            if obj.requiresNegativePhantom
                resStr = ['\negphantom{-}' resStr];
            end
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
            [isMath, texStr] = removeMath(inputStr);
            [isNegative, texStr] = removeNegative(texStr);
            
            obj = TexContent(texStr, ...
                'originalInput', inputStr, ...
                'isMath', ensureMath | isMath, ...
                'isNegative', isNegative, ...
                'requiresNegativePhantom', ...
                    isNegative & horizontalCorrection ...
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