function save_overtikz(baseName, options)
% SAVE_OVERTIKZ export current figure for embedding within a TeX Document
    arguments
        baseName (1,:) char 
        options.texFigureDirectory (1,:) char = ''
    end    

    import overtikz.extractLabels overtikz.FigureListEntry;
    import overtikz.FigureList;
    fig = gcf;
    texFigureDirectory = options.texFigureDirectory;
    if ~isempty(texFigureDirectory)
        % This introduces a dependency on Java
        if ~java.io.File(texFigureDirectory).isAbsolute()
            texFigureDirectoryFull = fullfile(pwd, texFigureDirectory);
        end
        % using 'exist' *requires* an absolute path, otherwise results are
        % not as expected (e.g., 'figures' exists in MATLAB directory but
        % not in the current directory)
        if ~exist(texFigureDirectoryFull, 'dir') 
            mkdir(texFigureDirectoryFull); 
        end
        basePath = fullfile(texFigureDirectoryFull, baseName);
    else
        basePath = baseName;
    end

    % Prepare the figure settings for proper export
    fig.Renderer = 'Painters';  % Forces Vector Rendering
    fig.Units = fig.PaperUnits;  % critical for proper sizing
    fig.PaperPositionMode = 'auto';
    
    % This pause hopefully prevents a race condition between the 
    % extractLabels function and the annotations plane 
    pause(0.05);
    drawnow();
    refresh();
    pause(0.05);

    % store axes sizes and legend props
    annotationAx = findall(fig, 'Tag', 'scribeOverlay');
    axCollection = [fig.Children; annotationAx];
    nAxes = 0;
    nLegends = 0;
    for ax=axCollection.'
        if isgraphics(ax, 'axes')
            nAxes = nAxes + 1;
        elseif isgraphics(ax, 'legend')
            nLegends = nLegends + 1;
        end
    end
    oldSizes = cell(nAxes, 2);
    oldLegendItrp = cell(nLegends, 2);
    iAxes = 1;
    iLegends = 1;
    for ax=axCollection.'
        if isgraphics(ax, 'axes')
            oldSizes(iAxes,:) = {ax, ax.Position};
            iAxes = iAxes + 1;
        elseif isgraphics(ax, 'legend')
            oldLegendItrp(iLegends,:) = {ax, ax.Interpreter};
            ax.Interpreter = 'latex';
            iLegends = iLegends + 1;
        end
        
    end

    % extract labels
    [lbls, req] = extractLabels(fig);

    % -- Clear Figure --
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
    print(fig, [basePath, 'Base.pdf'], '-r900', '-dpdf');
    writeStandAlone(baseName, texFigureDirectoryFull, lbls, req)
    
    % -- Restore Figure --
    % Restore Nodes
    if ~isempty(lbls)
        restoreNodes(lbls)
    end
    % Restore Legend Interpretors
    for pair=oldLegendItrp.'
        ax = pair{1};
        intrp = pair{2};
        ax.Interpreter = intrp;
        pause(0.01);
    end

    % -- Manage Figure Entries --
    figEntry = FigureListEntry.fromBaseName(baseName, ...
        includeDirectory=texFigureDirectory, ...
        includeArgs='mode=tex');
    fList = FigureList();
    fList.addEntry(figEntry);
    fList.saveList();
end

function writeStandAlone(baseName, texFigureDirectory, labels, requirements)
    if ~isempty(texFigureDirectory)
        basePath = fullfile(texFigureDirectory, baseName);
    else
        basePath = baseName;
    end
    fid = fopen([basePath '.tex'], 'w');
    fprintf(fid, '%%Generated\n');
    fprintf(fid, '\\documentclass[tikz]{standalone}\n');
    fprintf(fid, '\\usepackage{currfile}\n');
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
        'at (0,0,0) {\\includegraphics{\\currfiledir %s}};\n'], ...
        [baseName 'Base']);
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

