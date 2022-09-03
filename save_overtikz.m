function save_overtikz(baseName)
    
    import tex_export.extractLabels tex_export.FigureListEntry;
    import tex_export.FigureList;
    fig = gcf;
    
    % This pause hopefully prevents a race condition between the 
    % extractLabels function and the annotations plane 
    pause(0.01);
    
    % extract labels
    [lbls, req] = extractLabels(fig);
    % store ax sizes
    annotationAx = findall(fig, 'Tag', 'scribeOverlay');
    axCollection = [fig.Children; annotationAx];
    N = 0;
    for ax=axCollection.'
        if isgraphics(ax, 'axes')
            N = N + 1;
        end
    end
    oldSizes = cell(N,2);
    i = 1;
    for ax=axCollection.'
        if isgraphics(ax, 'axes')
            oldSizes(i,:) = {ax, ax.Position};
        end
        i = i + 1;
    end
    if ~isempty(lbls)
        clearNodes(lbls)
    end
    % Restore Axes Sizes
    for pair=oldSizes.'
        ax = pair{1};
        pos = pair{2};
        ax.Position = pos;
        pause(0.01);
    end

    pos = fig.Position;
    figSize = pos(3:4);
    fig.PaperSize = figSize;
    print(gcf, [baseName 'raw.pdf'], '-r900', '-dpdf');
    writeStandAlone(baseName, lbls, req)
    
    % restor old figure
    if ~isempty(lbls)
        restoreNodes(lbls)
    end
    % manage figure entries
    figEntry = FigureListEntry.fromBaseName(baseName, ...
        'includeArgs', 'mode=tex');
    fList = FigureList();
    fList.addEntry(figEntry);
    fList.saveList();
end

function writeStandAlone(baseName, labels, requirements)
    fid = fopen([baseName '.tex'], 'w');
    fprintf(fid, '%%Generated\n');
    fprintf(fid, '\\documentclass[tikz]{standalone}\n');
    fprintf(fid, '\\usepackage{pgfplots}\n');
    fprintf(fid, '\\usepackage{graphicx}\n');
    fprintf(fid, '\\begin{document}\n');
    fprintf(fid, '\\begin{tikzpicture}\n');
    reqs = requirements.getTikzRequirements();
    for req=reqs
        res = req;
        if iscell(res)
            cellfun(@(line) fprintf(fid,'\t%s\n', char(line)), res);
        else
            fprintf(fid,'\t%s\n', res);
        end
    end
    fprintf(fid, ['\t\\node[anchor=south west,inner sep=0] (image) ' ...
        'at (0,0,0) {\\includegraphics{%s}};\n'], [baseName 'raw']);
    fprintf(fid, ['\t\\begin{scope}[x={(image.south east)}' ...
        ',y={(image.north west)}]\n']);
    for lbl=labels
        res = lbl(:).toTikzNode();
        if iscell(res)
            cellfun(@(line) fprintf(fid,'\t\t%s', char(line)), res);
        else
            fprintf(fid,'\t\t%s', res);
        end
    end
    fprintf(fid, '\t\\end{scope}\n');
    fprintf(fid, '\\end{tikzpicture}%%\n');
    fprintf(fid, '\\end{document}\n');
    fclose(fid);
end
