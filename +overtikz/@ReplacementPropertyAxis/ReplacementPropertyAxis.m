classdef ReplacementPropertyAxis < overtikz.ReplacementPropertyCell
    properties
        tickLabelMode
        tickLabelModeProperty
    end
    methods
        function obj = ReplacementPropertyAxis(varargin)
            import overtikz.*

            p = inputParser();
            p.addRequired('axisHandle')
            p.addRequired('tickProperty')
            p.parse(varargin{:});

            axisHandle = p.Results.axisHandle;
            tickProperty = p.Results.tickProperty;
            
            xmatches = regexp(tickProperty, '[xX]', 'match');
            ymatches = regexp(tickProperty, '[yY]', 'match');
            if ~isempty(xmatches)
                x_tix_labels = get(axisHandle, tickProperty);
                x_tix = getXtickPositions(axisHandle);
                dim = axisHandle.Position;
                xxlim = cumsum([dim(1), dim(3)]);

                if isempty(x_tix)
                    x_tix = double.empty(0, 2);
                    x_tix_labels = {};
                end

                M = size(x_tix, 1);
                if M ~= numel(x_tix_labels)
                    error( ...
                        [...
                        'overtikz:' ...
                        'ReplacementPropertyAxis:xTickLabelMismatch'...
                        ], ...
                        [ ...
                            'Number of xTicks: %d, not equal to ' ...
                            'number of xTickLabels: %d.' ...
                        ], ...
                        M, ...
                        numel(x_tix_labels) ...
                    )
                end
                if M > 1 
                    x_tix = sort(x_tix( ....
                        x_tix(:, 1) >= xxlim(1) & ...
                        x_tix(:, 1) <= xxlim(2),  ...
                        : ...
                    ));
                end
                
                % these are usually placed too high move down
                M = size(x_tix, 1);
                xOrientation = axisHandle.XAxisLocation;
                if strcmpi(xOrientation, 'bottom')
                    sgn = -1;
                    anchor = ReplacementTextNodeAnchor.North;
                else
                    sgn = 1;
                    anchor = ReplacementTextNodeAnchor.South;
                end
                amnt = unitToNorm([0, 0.1], axisHandle, 'centimeters');
                if M > 0
                    x_tix(:, 2) = x_tix(:, 2) + sgn*amnt(2)*ones(M, 1);
                end
                
                tickLabelNodes = arrayfun( ...
                    @(ii) ReplacementTextNode.fromHandless(...
                        x_tix(ii, :), x_tix_labels{ii}, ...
                        anchor, ...
                        'scale', 0.8, ...
                        'horizontalCorrection', true ...
                    ), ...
                    1:M ...
                );

                tickLabelMode = axisHandle.XTickLabelMode;
                tickLabelModeProperty = 'XTickLabelMode';

                % add the exponent multiplier if needed
                if isprop(axisHandle, 'XAxis') && ...
                            isprop(axisHandle.XAxis, 'Exponent') && ...
                            axisHandle.XAxis.Exponent ~= 0
                    xExponentAmount = axisHandle.XAxis.Exponent;
                    
                    xEponentTxt = sprintf('$\\times 10^{%d}$', xExponentAmount);
                    xRight = max(axisHandle.XLim);
                    if strcmpi(xOrientation, 'bottom')
                        yLoc = min(axisHandle.YLim);
                        sgn = -1;
                        anchor = ReplacementTextNodeAnchor.NorthEast;
                    else
                        yLoc = max(axisHandle.YLim);
                        sgn = 1;
                        anchor = ReplacementTextNodeAnchor.SouthEast;
                    end
                    xExponentPos = dataToNorm([xRight, yLoc], axisHandle);
                    % pad space at the bottom
                    xOffset = 4; 
                    xExponentPos = xExponentPos + unitToNorm([xOffset, sgn*12], axisHandle, 'points');
                    xExponentNode = ReplacementTextNode.fromHandless(...
                        xExponentPos, ...
                        xEponentTxt, ...
                        anchor, ...
                        'scale', 0.8 ...
                    );
                    % add node to the list
                    tickLabelNodes = [tickLabelNodes(:); xExponentNode];
                end
                
            elseif ~isempty(ymatches)
                y_tix_labels = get(axisHandle, tickProperty);
                y_tix = getYtickPositions(axisHandle);
                dim = axisHandle.Position;
                yylim = cumsum([dim(2), dim(4)]);

                if isempty(y_tix)
                    y_tix = double.empty(0, 2);
                    y_tix_labels = {};
                end

                M = size(y_tix, 1);
                if M ~= numel(y_tix_labels)
                    error( ...
                        [...
                        'overtikz:' ...
                        'ReplacementPropertyAxis:yTickLabelMismatch'...
                        ], ...
                        [ ...
                            'Number of yTicks: %d, not equal to ' ...
                            'number of yTickLabels: %d.' ...
                        ], ...
                        M, ...
                        numel(y_tix_labels) ...
                    )
                end
                if M > 1
                    y_tix = sort(y_tix( ....
                        y_tix(:, 2) >= yylim(1) & ...
                        y_tix(:, 2) <= yylim(2),  ...
                        : ...
                    ));
                end
                
                % these are usually placed too rightward move left
                M = size(y_tix, 1);
                yOrientation = axisHandle.YAxisLocation;
                if strcmpi(yOrientation, 'left')
                    sgn = -1;
                    anchor = ReplacementTextNodeAnchor.East;
                else
                    sgn = 1;
                    anchor = ReplacementTextNodeAnchor.West;
                end
                amnt = unitToNorm([0.05, 0], axisHandle, 'centimeters');
                if M > 0
                    y_tix(:, 1) = y_tix(:, 1) + sgn*amnt(1)*ones(M, 1);
                end
                
                tickLabelNodes = arrayfun( ...
                    @(ii) ReplacementTextNode.fromHandless(...
                        y_tix(ii, :), y_tix_labels{ii}, ...
                        anchor, ...
                        'scale', 0.8 ...
                        ), ...
                    1:M ...
                );

                tickLabelMode = axisHandle.YTickLabelMode;
                tickLabelModeProperty = 'YTickLabelMode';

                % add the exponent multiplier if needed
                if isprop(axisHandle, 'YAxis') && ...
                            isprop(axisHandle.YAxis, 'Exponent') && ...
                            axisHandle.YAxis.Exponent ~= 0
                    yExponentAmount = axisHandle.YAxis.Exponent;
                    yEponentTxt = sprintf('$\\times 10^{%d}$', yExponentAmount);
                    
                    if strcmpi(yOrientation, 'left')
                        xLoc = min(axisHandle.XLim);
                    else
                        xLoc = max(axisHandle.XLim);
                    end

                    xOrientation = axisHandle.XAxisLocation;
                    if strcmpi(xOrientation, 'bottom')
                        yLoc = max(axisHandle.YLim);
                        anchor = ReplacementTextNodeAnchor.SouthWest;
                        sgn = 1;
                    else
                        yLoc = min(axisHandle.YLim); 
                        anchor = ReplacementTextNodeAnchor.NorthWest;
                        sgn = -1;
                    end

                    yExponentPos = dataToNorm([xLoc, yLoc], axisHandle);
                    % remove space left
                    yExponentPos = yExponentPos + unitToNorm([-4, 0], axisHandle, 'points');
                    amnt = unitToNorm([0, 0.1], axisHandle, 'centimeters');
                    yExponentPos = yExponentPos + sgn*amnt;
                    yExponentNode = ReplacementTextNode.fromHandless(...
                        yExponentPos, ...
                        yEponentTxt, ...
                        anchor, ...
                        'scale', 0.8 ...
                    );
                    % add node to the list
                    tickLabelNodes = [tickLabelNodes(:); yExponentNode];
                end

            else
                MSGID = ['overtikz:' ...
                    'ReplacementPropertyAxis:invalidProperty'];
                error(MSGID, 'No Axis X/Y Tick Label Property %s.\n', ...
                    tickProperty)
            end
            
            obj = obj@overtikz.ReplacementPropertyCell(...
                axisHandle, ...
                tickProperty, ...
                tickLabelNodes ...
            );
            obj.tickLabelMode = tickLabelMode;
            obj.tickLabelModeProperty = tickLabelModeProperty;
        end
        
        function resStr = restoreNode(obj)
            resStr = restoreNode@overtikz.ReplacementPropertyCell(obj);
            if strcmpi('auto', obj.tickLabelMode)
                set(obj.objectHandle, obj.tickLabelModeProperty, obj.tickLabelMode);
            end
        end
        
    end
end

function coordArr = getXtickPositions(axisHandle)
    import overtikz.*
    orientation = axisHandle.XAxisLocation;
    if strcmpi(orientation, 'bottom')
        y_d = min(axisHandle.YLim);
    else
        y_d = max(axisHandle.YLim);
    end
    x_tix = axisHandle.XTick;
    C = arrayfun(@(x_d) dataToNorm([x_d, y_d], axisHandle), ...
        x_tix.', 'UniformOutput', false);
    coordArr = cell2mat(C);
end

function coordArr = getYtickPositions(axisHandle)
    import overtikz.*
    orientation = axisHandle.YAxisLocation;
    if strcmpi(orientation, 'left')
        x_d = min(axisHandle.XLim);
    else
        x_d = max(axisHandle.XLim);
    end
    y_tix = axisHandle.YTick;
    C = arrayfun(@(y_d) dataToNorm([x_d, y_d], axisHandle), ...
        y_tix.', 'UniformOutput', false);
    coordArr = cell2mat(C);
end

function resPos = unitToNorm(pos, axisHandle, unitName)
    oldUnits = axisHandle.Units;
    axisHandle.Units = unitName;
    inUnits = axisHandle.Position(1:2);
    axisHandle.Units = 'normalized';
    normUnits = axisHandle.Position(1:2);
    axisHandle.Units = oldUnits;
    
    coeff = normUnits./inUnits;
    resPos = pos.*coeff;
end

