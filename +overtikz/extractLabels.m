function [replacementTextNodes, requirements] = extractLabels(elements)
    import overtikz.*
    results = cell(length(elements), 1);
    requirements = ReplacementRequirementFlags();
    i = 1;
    for element=elements.'
        if isgraphics(element, 'figure')
            ax = findall(element, 'Tag', 'scribeOverlay');
            results{i} = extractLabels([element.Children; ax]);
        elseif isgraphics(element, 'axes')
            results{i} = [
                extractLabelsAxes(element), extractLabels(element.Children)
            ];
        elseif isgraphics(element, 'legend')
            results{i} = extractLegendTextNodes(element);
        elseif isgraphics(element, 'AnnotationPane')
            results{i} = extractLabels(element.Children);
        elseif isgraphics(element, 'textarrowshape') || ...
               isgraphics(element, 'textboxshape')
                            
            results{i} = extractIfNotEmpty(element);
        elseif isgraphics(element, 'GraphPlot')
            results{i} = extractGraphPlot(element);
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
    import overtikz.*
    
    rplNodeTitle = extractIfNotEmpty(axisHandle.Title, 'normalize', axisHandle);
    rplXLabel = extractIfNotEmpty(axisHandle.XLabel, 'normalize', axisHandle);
    rplYLabel = extractIfNotEmpty(axisHandle.YLabel, 'normalize', axisHandle);
    
    rplXTix = ReplacementPropertyCell.fromAxisProperty(axisHandle, 'XTickLabels');
    rplYTix = ReplacementPropertyCell.fromAxisProperty(axisHandle, 'YTickLabels');
    
    replacementTextNodes = [
        rplNodeTitle 
        rplXLabel 
        rplYLabel 
        rplXTix
        rplYTix
    ].';
end

function rplNodes = extractLegendTextNodes(legendHandle)
    import overtikz.*
    legendPosition = legendHandle.Position;
    legendTransform = diag([legendPosition(3:4), 1, 1]);
    legendTransform(1:2,4) = legendPosition(1:2).';
    nodeChildren = legendHandle.EntryContainer.NodeChildren;
    N = length(nodeChildren);
    rplNodes = cell(N, 1);
    for i=1:N
        child = nodeChildren(i);
        textHandle = child.Children(2);
        txtRaw = textHandle.String;
        A = child.Children(1).Transform.Matrix;
        iconX = A(1,4);
        iconY = A(2,4);
        iconW = A(1,1);
        iconH = A(2,2);
        yy = iconY + iconH/2;
        xx = iconW + iconX;
        p = [xx;yy;1;1];
        q = legendTransform*p;
        x = q(1);
        y = q(2);
        
        rplNodes{i} = ReplacementTextNode.fromMinimal( ...
            [x,y], txtRaw, 0.7, ...
            ReplacementTextNodeAnchor.West, ...
            textHandle ...
        );
    end
    rplNodes = [rplNodes{:}];
end

function replacementTextNodes = extractGraphPlot(graphHandle)
    import overtikz.*
    
    rplGraphNodes = ReplacementPropertyCell.fromGraphPlot( ...
        graphHandle, 'nodeLabel');
    rplGraphEdges = ReplacementPropertyCell.fromGraphPlot( ...
        graphHandle, 'edgeLabel');
    
    replacementTextNodes = [
        rplGraphNodes
        rplGraphEdges
    ].';
end

function rplNode = extractIfNotEmpty(varargin)
    import overtikz.*
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
