function [] = setup_simulations(cohortNo)

%% setup_simulations
%  Simulat synthetic agents using priors determined from pilot dataset
%
%   SYNTAX:       setup_simulations
%
%   IN: cohortNo:  integer, cohort number, see optionsFile for what cohort
%                            corresponds to what number in the
%                            optionsFile.cohort(cohortNo).name struct. This
%                            allows to run the pipeline and its functions for different
%                            cohorts whose expcifications have been set in runOptions.m
%
% Original: Katharina V. Wellstein
% -------------------------------------------------------------------------
% Copyright (C) 2025, Katharina V. Wellstein
%
% This file is released under the terms of the GNU General Public Licence
% (GPL), version 3. You can redistribute it and/or modify it under the
% terms of the GPL (either version 3 or, at your option, any later version).
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details:
% <http://www.gnu.org/licenses/>
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
% _________________________________________________________________________
% =========================================================================

%% INITIALIZE options and variables needed to run this function

disp('************************************** SETUP_SIMULATIONS **************************************');
disp('*');
disp('*');

% load or run options for running this function
if exist('optionsFile.mat','file')==2
    load('optionsFile.mat');
else
    optionsFile = runOptions();
end

% prespecify variables needed for running this function
nTasks   = numel(optionsFile.cohort(cohortNo).testTask);
nModels  = numel(optionsFile.model.space);
nSamples = optionsFile.simulations.nSamples;
sim.agent = struct();
sim.input = struct();
s.task    = struct();

%% get modeling specifications
% add toolbox path
addpath(genpath([optionsFile.paths.toolboxDir,'HGF']));

% if responses to the task in this cohort should be simulated using informed priors,
% run getInformedPriors.m with the settings prespecified in the optionsFile
if ~isempty(optionsFile.cohort(cohortNo).priorsFromCohort)
    optionsFile = setup_configFiles(optionsFile,cohortNo);
    disp('get priors from pilot data...');
    % input aguments: priorCohort,currCohort,subCohort,iTask,iCondition,iRep,optionsHandle
    [~,optionsFile] = get_informedPriors(optionsFile.cohort(cohortNo).priorsFromCohort,...
        cohortNo,optionsFile.cohort(cohortNo).priorsFromSubCohort,...
        optionsFile.cohort(cohortNo).priorsFromTask,optionsFile.cohort(cohortNo).priorsFromCondition,...
        optionsFile.cohort(cohortNo).priorsFromRepetition,0);

else % otherwise just set up the configfiles for the models in the modelspace
    optionsFile = setup_configFiles(optionsFile,cohortNo);
end


%% GENERATE synthetic agents using default priors from toolbox

for iAgent = 1:nSamples
    for iModel = 1:nModels
        % sample free parameter values
        input.prc.transInp = optionsFile.modelSpace(iModel).prc_config.priormus;
        input.obs.transInp = optionsFile.modelSpace(iModel).obs_config.priormus;

        for iPerc = 1:size(optionsFile.modelSpace(iModel).prc_idx,2)
            input.prc.transInp(optionsFile.modelSpace(iModel).prc_idx(iPerc)) = ...
                normrnd(optionsFile.modelSpace(iModel).prc_config.priormus(optionsFile.modelSpace(iModel).prc_idx(iPerc)),...
                abs(sqrt(optionsFile.modelSpace(iModel).prc_config.priorsas(optionsFile.modelSpace(iModel).prc_idx(iPerc)))));
        end

        for iObs = 1:size(optionsFile.modelSpace(iModel).obs_idx,2)
            input.obs.transInp(optionsFile.modelSpace(iModel).obs_idx(iObs)) = ...
                normrnd(optionsFile.modelSpace(iModel).obs_config.priormus(optionsFile.modelSpace(iModel).obs_idx(iObs)),...
                abs(sqrt(optionsFile.modelSpace(iModel).obs_config.priorsas(optionsFile.modelSpace(iModel).obs_idx(iObs)))));
        end

        c.c_prc = optionsFile.modelSpace(iModel).prc_config;
        input.prc.nativeInp = optionsFile.modelSpace(iModel).prc_config.transp_prc_fun(c, input.prc.transInp);
        c.c_obs = optionsFile.modelSpace(iModel).obs_config;
        input.obs.nativeInp = optionsFile.modelSpace(iModel).obs_config.transp_obs_fun(c, input.obs.transInp);

        % simulate predictions for SNR calculation
        stable = 0;

        for iTask = 1:nTasks
            disp(['Simulating with input sequence from ', optionsFile.cohort(cohortNo).testTask(iTask).name,'...   ']);

            while stable == 0
                try %sim = tapas_simModel(inputs, prc_model, prc_pvec, obs_model, obs_pvec)
                    data = tapas_simModel(optionsFile.cohort(cohortNo).testTask(iTask).inputs,...
                        optionsFile.modelSpace(iModel).prc,...
                        input.prc.nativeInp,...
                        optionsFile.modelSpace(iModel).obs,...
                        input.obs.nativeInp,...
                        optionsFile.rng.settings.State(optionsFile.rng.idx, 1));
                    stable = 1;

                catch
                    fprintf('simulation failed for Model %1.0f, synth. Sub %1.0f \n', [iModel, iAgent]);
                    fprintf('Prc Param Values: \n');
                    input.prc.nativeInp
                    fprintf('Obs Param Values: \n');
                    input.obs.nativeInp
                    % re-sample prc param values
                    for j = 1:size(optionsFile.modelSpace(iModel,iTask).prc_idx,2)
                        input.prc.transInp(optionsFile.modelSpace(iModel,iTask).prc_idx(j)) = ...
                            normrnd(optionsFile.modelSpace(iModel,iTask).prc_config.priormus(optionsFile.modelSpace(iModel,iTask).prc_idx(j)),...
                            abs(sqrt(optionsFile.modelSpace(iModel,iTask).prc_config.priorsas(optionsFile.modelSpace(iModel,iTask).prc_idx(j)))));
                    end
                    input.prc.nativeInp = optionsFile.modelSpace(iModel,iTask).prc_config.transp_prc_fun(c, input.prc.transInp);

                end
                % save simulation input
                s.task(iTask).data = data;
                sim.agent(iAgent,iModel).task(iTask).data  = s.task(iTask).data;
                sim.agent(iAgent,iModel).task(iTask).input = input;

                % Update the rng state idx
                optionsFile.rng.idx     = optionsFile.rng.idx+1;
                if optionsFile.rng.idx == (length(optionsFile.rng.settings.State)+1)
                    optionsFile.rng.idx = 1;
                end
            end
        end % END TASK loop
    end % END MODEL loop
end % END AGENTS loop

%% PLOT predictions
if optionsFile.doCreatePlots
    for iTask = 1:nTasks
        for iModel = 1:nModels
            for iAgent = 1:nSamples

                if any(strcmp('muhat',fieldnames(sim.agent(iAgent,iModel).task(iTask).data.traj)))
                    plot(sim.agent(iAgent,iModel).task(iTask).data.traj.muhat(:,1), 'color', optionsFile.col.tnub);
                    ylabel('$\hat{\mu}_{1}$', 'Interpreter', 'Latex')
                else
                    plot(sim.agent(iAgent,iModel).task(iTask).data.traj.vhat(:,1), 'color', optionsFile.col.tnub);
                    ylabel('v_hat')
                end

                hold on;
            end

            %Create figure of trajectory
            ylim([-0.1 1.1])
            plot(sim.agent(1).task(iTask).data.u,'o','Color','b');
            % plot(optionsFile.task.probStr,'Color','b');
            xlabel('Trials');
            ylabel('Reward Probability');
            txt = ['Simulation results from',num2str(nSamples),'with ', optionsFile.model.prc{iModel}];
            title(txt)
            hold on
            set(gcf, 'color', 'none');   %transparent background
            set(gca, 'color', 'none');   %transparent background
            xticks(0:40:numel(optionsFile.cohort(cohortNo).testTask(iTask).inputs))
            hold on;

            figdir = fullfile([char(optionsFile.paths.cohort(cohortNo).groupSim),optionsFile.cohort(priorCohort).taskPrefix, optionsFile.cohort(cohortNo).testTask(iTask).name,'_',optionsFile.model.space{iModel},'_predictions']);
            save([figdir,'.fig'])
            print(figdir, '-dpng');
            close;
        end
        % reset rng state idx
        optionsFile.rng.idx = 1;

        %% SAVE model simulation specs as struct
        save([optionsFile.paths.cohort(cohortNo).simulations,optionsFile.cohort(priorCohort).taskPrefix,optionsFile.cohort(cohortNo).testTask(iTask).name,'_',optionsFile.model.space{iModel},'_sim'], '-struct', 'sim');
    
    end % END TASK loop
end % END CREATE PLOTS loop

disp('simulated data successfully for cohort ',optionsFile.cohort(cohortNo).name,' created.')

end