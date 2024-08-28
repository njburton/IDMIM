                %             %plot da
                %             area(RWFit.traj.da)
                %             title('PredictionError');
                %             xlabel('Trial');
                %             ylabel('prediction error delta ');
                %             %Save plot
                %             figdir = fullfile([char(optionsFile.paths.plotsDir),'\mouse',num2str(currMouse),'_RW_PredictionErrorPlot']);
                %             save([figdir,'.fig']);
                %             print([figdir,'.png'], '-dpng');
                %             close all;
                %
                %             %plot value
                %             area(RWFit.traj.v)
                %             title('Value of RightLever');
                %             xlabel('Trial');
                %             ylabel('Value');
                %             %Save plot
                %             figdir = fullfile([char(optionsFile.paths.plotsDir),'\mouse',num2str(currMouse),'_RW_ValuePlot']);
                %             save([figdir,'.fig']);
                %             print([figdir,'.png'], '-dpng');
                %             close all;

                %Plot RWFit alpha (learning rate values per treatmentgroup)
% for m = 1:length(optionsFile.Task.MouseID)
%     if endsWith(num2str(ModelFitTable.MouseID(m)),"2")  %If MouseID ends in "2" and is UCMS
%         bar(ModelFitTable,ModelFitTable.RWFit_Alpha(m,4),Color="#7E2F8E"); hold on  %Plot alpha value in purple
%     else   %Or if MouseID doesn't end in 2 and is considered control
%         bar(ModelFitTable,ModelFitTable.RWFit_Alpha(m),Color="#000000"); hold on %Plot alpha value in black
%     end
% end


%Plot LMEs
%LMEHeatMap = heatmap(ModelFitTable,"eHGFFitLME","RWFitLME")