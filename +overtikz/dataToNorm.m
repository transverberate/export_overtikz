function resPos = dataToNorm(varargin)
    p = inputParser;
    p.addRequired('pos');
    p.addOptional('axesHandle', gca);
    p.parse(varargin{:});
    
    pos = p.Results.pos;
    axesHandle = p.Results.axesHandle;
    
    oldUnits = axesHandle.Units;
    axesHandle.Units = 'normalized';
    
    pos_a = axesHandle.Position;
    x_a = pos_a(1);
    y_a = pos_a(2);
    w_a = pos_a(3);
    h_a = pos_a(4);
    
    x_func = @(x) x;
    if strcmp(axesHandle.XScale, 'log')
        x_func = @(x) log10(x);
    end
    y_func = @(y) y;
    if strcmp(axesHandle.YScale, 'log')
        y_func = @(y) log10(y);
    end
    
    x_d = x_func(pos(1));
    y_d = y_func(pos(2));
    x_dlim = x_func(axesHandle.XLim);
    y_dlim = y_func(axesHandle.YLim);
    w_d = diff(x_dlim);
    h_d = diff(y_dlim);
    
    if strcmp(axesHandle.PlotBoxAspectRatioMode, 'manual')
        
        x_old = x_a;
        y_old = y_a;
        w_old = w_a;
        h_old = h_a;
        r_old = h_a / w_a;
        
        pboxx = axesHandle.PlotBoxAspectRatio;
        w_r = pboxx(1);
        h_r = pboxx(2);
        r_new = h_r / w_r;

        if r_new <= r_old
            w_new = w_old;
            h_new = w_old * r_new * r_old;
        else
            w_new = h_old / r_new / r_old;
            h_new = h_old;
        end

        x_new = (w_old-w_new)/2 + x_old;
        y_new = (h_old-h_new)/2 + y_old;
        
        x_a = x_new;
        y_a = y_new;
        w_a = w_new;
        h_a = h_new;
    end
    
    x_n = (x_d-x_dlim(1))*w_a/w_d + x_a;
    y_n = (y_d-y_dlim(1))*h_a/h_d + y_a;
    
    axesHandle.Units = oldUnits;
    resPos = [x_n, y_n];
end

