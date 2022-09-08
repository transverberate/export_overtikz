classdef testExtractLabels < matlab.unittest.TestCase

    properties
        TestFigure
    end
    
    methods(TestClassSetup)        

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
    end
    
end

