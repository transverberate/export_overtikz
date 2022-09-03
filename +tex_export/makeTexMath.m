function resStr = makeTexMath(inStr)
    mathAlready = '(?<!\\)\$';
    matches = regexp(inStr, mathAlready, 'match');
    if isempty(matches)
        resStr = ['$' inStr '$'];
    else
        resStr = inStr;
    end
end