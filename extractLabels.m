function [replacementTextNodes, requirements] = extractLabels(elements)
    import tex_export.*
    results = cell(length(elements), 1);
    requirements = ReplacementRequirementFlags();
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
    
    if ~isempty(replacementTextNodes)
        reqArr = getRequirementsArr(replacementTextNodes);
        requirements = ReplacementRequirementFlags.fromFlagArray(...
             reqArr ...
        );
    end
end

function replacementTextNodes = extractLabelsAxes(axisHandle)
    import tex_export.*
    
    rplNodeTitle = extractIfNotEmpty(axisHandle.Title, 'normalize', axisHandle);
    rplXLabel = extractIfNotEmpty(axisHandle.XLabel, 'normalize', axisHandle);
    rplYLabel = extractIfNotEmpty(axisHandle.YLabel, 'normalize', axisHandle);
    
    rplXTix = ReplacementTicks.fromAxisProperty(axisHandle, 'XTickLabels');
    rplYTix = ReplacementTicks.fromAxisProperty(axisHandle, 'YTickLabels');
    
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
    axisHandle = p.Results.normalize;
    rplNode = [];
    if ~isempty(textElement.String)
        rplNode = ReplacementTextNode.fromTextObj( ...
            textElement, 'normalize', axisHandle);
    end
end
