% %% Plot est mice (X axis are mice/sim) Yaxis=values;
% % Plot free perceptual model parameters
% xAxis = 1:optionsFile.cohort.nSize;
% for iTask = 1:numel(optionsFile.task.testTask)
%     for m = 1:2 % numel(optionsFile.model.space) have to fix prc_idx for RW model (and eventually VK model)
%         for p = 1:length(optionsFile.modelSpace(m).prc_idx)   % Plot both free params in perceptual model
%             for n = 1:optionsFile.cohort.nSize
%                 PostPerceptParam = rec.sim.task(iTask).agent(m,iAgent,m).data.p_prc.ptrans(optionsFile.modelSpace(m).prc_idx(p));
%                 fig = plot(xAxis(n),PostPerceptParam,'Marker', 'o','Color','b'); %ylim([-5.0, 5.0]);
%                 hold on
%             end %
% 
%             yline(rec.sim.task(iTask).agent(m,iAgent,m_).data.est.c_prc.priormus(optionsFile.modelSpace(m).prc_idx),'Color','r');
%             title(fig,['mice perceptual parameters',num2str(p),' ',optionsFile.task.testTask(iTask).name]);
%             figDir = fullfile([char(optionsFile.paths.plotsDir),filesep,'model',num2str(m),'_mice_prc_param',num2str(p),' ',optionsFile.task.testTask(iTask).name]);
%             save([figDir,'.fig']);
%             print([figDir,'.png'], '-dpng');
%             close all;
%         end
% 
%         %Plot free observational model parameters
%         for j = 1:optionsFile.cohort.nSize
%             PostObsParam = rec.sim.task(iTask).agent(m,iAgent,m_).data.est.p_obs.ptrans(optionsFile.modelSpace(m).obs_idx);   % Plot single free param in observation model
%             fig = plot(xAxis(j),PostObsParam,'Marker','o','Color','b');
%             hold on
%         end
% 
%         yline(rec.sim.task(iTask).agent(m,iAgent,m_).data.est.c_obs.priormus(optionsFile.modelSpace(m).obs_idx),'Color','r');
%         title(fig,['mice observational parameters',num2str(p),' ',optionsFile.task.testTask(iTask).name]);
%         figDir = fullfile([char(optionsFile.paths.plotsDir),filesep,'model',num2str(m),'_mice_obs_param',num2str(p),' ',optionsFile.task.testTask(iTask).name]);
%         save([figDir,'.fig']);
%         print([figDir,'.png'], '-dpng');
%         close all;
%     end
% end

% %% Plot simAgent's Perceptual & Observational Free Parameter values *TO CHECK IF THAT WORKS
% %Plot free perceptual model parameters
% xAxis = 1:length(optionsFile.task.MouseID);
% for iTask = 1:numel(optionsFile.task.testTask)
%     for m = 1:2 % numel(optionsFile.model.space) have to fix prc_idx for RW model (and eventually VK model)
%         for p = 1:length(optionsFile.modelSpace(m).prc_idx)   % Plot both free params in perceptual model
%             for n = 1:length(optionsFile.task.MouseID)
%                 PostPerceptParam = simResp.agent(iAgent,m_in).task(iTask).data.p_prc.p(optionsFile.modelSpace(m).prc_idx(p));
%                 fig = plot(xAxis(n),PostPerceptParam,'Marker', 'o','Color','b');
%                 hold on
%             end
%             yline(simResp.agent(iAgent,m_in).task(iTask).data.c_prc.priormus(optionsFile.modelSpace(m).prc_idx(p)),'Color','r');
%             %     title(fig,['simulated observational parameters',num2str(p)]);
%             figDir = fullfile([char(optionsFile.paths.plotsDir),filesep,'model',num2str(m),'_simAgents_prc_param',num2str(p)]);
%             save([figDir,'.fig']);
%             print([figDir,'.png'], '-dpng');
%             close all;
%         end
%     end
% 
%     %Plot free observational model parameters
%     for m = 1:2 % numel(optionsFile.model.space) have to fix prc_idx for RW model (and eventually VK model)
%         for j = 1:length(optionsFile.task.MouseID)
%             PostObsParam = simResp.agent(iAgent,m_in).task(iTask).data.p_obs.ptrans(optionsFile.modelSpace.obs_idx);   % Plot single free param in observation model
%             fig = plot(xAxis(j),PostObsParam,'Marker','o','Color','b');
%             hold on
%         end
%         yline(simResp.agent(iAgent,m_in).task(iTask).data.c_obs.priormus(optionsFile.modelSpace.obs_idx),'Color','r');
%         % title(fig,['simulated observational parameters',num2str(p)]);
%         figDir = fullfile([char(optionsFile.paths.plotsDir),filesep,'model',num2str(m),'_simAgents_obs_param',num2str(p)]);
%         save([figDir,'.fig']);
%         print([figDir,'.png'], '-dpng');
%         close all;
%     end
% end