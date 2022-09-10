classdef testExtractLabels < matlab.unittest.TestCase

    properties
        TestFigure
    end
    
    methods(TestClassSetup)        

    end

    methods
        function drawCircle(testCase)
            theta = 2*pi*linspace(0, 1, 100);
            xxs = cos(theta);
            yys = sin(theta);
            plot(xxs, yys);
        end
    end
    
    methods(TestMethodSetup)
        function updatePackagePath(testCase)
            addpath(fullfile(pwd,'..'));
        end
        function createFigure(testCase)
            testCase.TestFigure = figure;
        end
    end

    methods(TestMethodTeardown)
        function closeFigure(testCase)
            close(testCase.TestFigure)
        end
    end

    methods(Test)
        % Test methods
        
        function filterTicksToThoseVisible(testCase)
            import overtikz.*

            % setup fig
            figure(testCase.TestFigure)
            t = linspace(0, 1, 501);
            t = t(1:end-1);
            x = sin(2*pi*t);
            plot(t, x);
            
            axis([0.13, 0.75, -.3, .8])
            % invisible ticks
            xticks(linspace(0,1,9))
            yticks(linspace(-1,1,9))

            extractLabels(testCase.TestFigure)
        end

        function extractAnnotationsR2020(testCase)
            import overtikz.*

            % setup fig
            figure(testCase.TestFigure)
            t = linspace(0, 1, 501);
            t = t(1:end-1);
            x = sin(2*pi*t);
            plot(t, x);
            hold on;
            plot(t, -t);
            hold off;

            legend( ...
                {'$\gamma$ Signal 1', '$\beta$ Signal 2'}, ...
                'Orientation','horizontal', ...
                'Location','north' ...
            );
        end

        function pbaspectCorrectAxisPositioning(testCase)
            import overtikz.*

            % draw figure
            figure(testCase.TestFigure)
            testCase.drawCircle()
            resize_typeset(3.35, 3.15)
            tix = [-1, -.5, 0, .5, 1];
            
            % modify pbaspect
            pbaspect([1 1 1])
            xlabel('$\theta$', 'Interpreter', 'latex')
            ylabel('$v$','Interpreter', 'latex')
            set(gca,'TickLabelInterpreter','latex')
            xticks(tix)
            yticks(tix)
            box on;

            t_str={'$-2\pi$', '$-\pi$', '0', '$\pi$', '$2\pi$'};
            xticklabels(t_str)
            yticklabels(t_str)

        end

    end
    
end

