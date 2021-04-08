function replacementTextNodes = extractLabels(elements)
    import tex_export.*
    results = cell(length(elements), 1);
    i = 1;
    for element=elements.'
        if isgraphics(element, 'figure')
            ax = findall(element, 'Tag', 'scribeOverlay');
            results{i} = extractLabels([element.Children; ax]);
        elseif isgraphics(element, 'axes')
            results{i} = extractLabelsAxes(element);
        elseif isgraphics(element, 'AnnotationPane')
            results{i} = extractLabels(element.Children);
        elseif isgraphics(element, 'textarrowshape') || isgraphics(element, 'textboxshape')
            results{i} = extractIfNotEmpty(element);
        else
            results{i} = [];
        end
        i = i + 1;
    end
    replacementTextNodes = [results{:}];
end

function replacementTextNodes = extractLabelsAxes(axesHandle)
    import tex_export.*
    
    rplNodeTitle = extractIfNotEmpty(axesHandle.Title, 'normalize', axesHandle);
    rplXLabel = extractIfNotEmpty(axesHandle.XLabel, 'normalize', axesHandle);
    rplYLabel = extractIfNotEmpty(axesHandle.YLabel, 'normalize', axesHandle);
    
    x_tix = getXtickPositions(axesHandle);
    x_tix_labels = axesHandle.XTickLabels;
    rplXTix = arrayfun( ...
        @(x,y,txt) ReplacementTextNode(...
            [x, y], makeTexMath(txt{:}), 'scale', 0.8, ...
            'anchor', ReplacementTextNodeAnchor.North), ...
        x_tix(:,1), x_tix(:,2), x_tix_labels ...
    );

    y_tix = getYtickPositions(axesHandle);
    y_tix_labels = axesHandle.YTickLabels;
    rplYTix = arrayfun( ...
        @(x,y,txt) ReplacementTextNode(...
            [x, y], makeTexMath(txt{:}), 'scale', 0.8, ...
            'anchor', ReplacementTextNodeAnchor.East), ...
        y_tix(:,1), y_tix(:,2), y_tix_labels ...
    );
    
    replacementTextNodes = [
        rplNodeTitle 
        rplXLabel 
        rplYLabel 
        rplXTix
        rplYTix
    ].';
end

function rplNode = extractIfNotEmpty(varargin)
    import tex_export.*
    p = inputParser;
    p.addRequired('textElement');
    p.addOptional('normalize', []);
    p.parse(varargin{:})
    textElement = p.Results.textElement;
    axesHandle = p.Results.normalize;
    rplNode = [];
    if ~isempty(textElement.String)
        rplNode = ReplacementTextNode.fromTextObj( ...
            textElement, 'normalize', axesHandle);
    end
end

function coordArr = getXtickPositions(axesHandle)
    import tex_export.*
    y_d = min(axesHandle.YLim);
    x_tix = axesHandle.XTick;
    C = arrayfun(@(x_d) dataToNorm([x_d, y_d], axesHandle), ...
        x_tix.', 'UniformOutput', false);
    coordArr = cell2mat(C);
end

function coordArr = getYtickPositions(axesHandle)
    import tex_export.*
    x_d = min(axesHandle.XLim);
    y_tix = axesHandle.YTick;
    C = arrayfun(@(y_d) dataToNorm([x_d, y_d], axesHandle), ...
        y_tix.', 'UniformOutput', false);
    coordArr = cell2mat(C);
end