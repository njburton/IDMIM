function [] = setup_simulations(cohortNo)

%% WBEST_setup_simulations
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
% Amended
% -------------------------------------------------------------------------
% Copyright (C) 2024, Katharina V. Wellstein
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

%% INITIALIZE Variables for running this function
% specifications for this analysis
if exist('optionsFile.mat','file')==2
    load("optionsFile.mat");
else
    optionsFile = runOptions();
end

optionsFile = setup_configFiles(optionsFile,cohortNo);

addpath(genpath([optionsFile.paths.toolboxDir,'HGF']));
disp('************************************** SETUP_SIMULATIONS **************************************');
disp('*');
disp('*');

%% Add in input sequence that has been generated
%>>>>>>>>>> COMMENT: ???
%Save input seq as variable in workspace so that I can subsititute it in
%the code when running this funcition
%newInputs = xlsread('C:\Users\c3200098\Desktop\ImprovedInputSequence.csv');

%% GENERATE synthetic agents using default priors from toolbox
sim.agent  = struct();
sim.input  = struct();
s.task    = struct();

for iAgent = 1:optionsFile.simulations.nSamples
    for iModel = 1:length(optionsFile.model.space)
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

        % create simulation input vectors (native space)
        c.c_prc = optionsFile.modelSpace(iModel).prc_config;
        input.prc.nativeInp = optionsFile.modelSpace(iModel).prc_config.transp_prc_fun(c, input.prc.transInp);
        c.c_obs = optionsFile.modelSpace(iModel).obs_config;
        input.obs.nativeInp = optionsFile.modelSpace(iModel).obs_config.transp_obs_fun(c, input.obs.transInp);

        % simulate predictions for SNR calculation
        stable = 0;

        for iTask = 1:numel(optionsFile.cohort(cohortNo).testTask)
            optionsFile.cohort(cohortNo).testTask(iTask).inputs
            disp(['Simulating with input sequence from ', optionsFile.cohort(cohortNo).testTask(iTask).name,'...   ']);

            while stable == 0
                try %tapas_simModel(inputs, prc_model, prc_pvec, varargin)
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
                    for j = 1:size(res.main.ModSpace(iModel).prc_idx,2)
                        input.prc.transInp(optionsFile.modelSpace(iModel,iTask).prc_idx(j)) = ...
                            normrnd(optionsFile.modelSpace(iModel,iTask).prc_config.priormus(optionsFile.modelSpace(iModel,iTask).prc_idx(j)),...
                            abs(sqrt(optionsFile.modelSpace(iModel,iTask).prc_config.priorsas(optionsFile.modelSpace(iModel,iTask).prc_idx(j)))));
                    end
                    input.prc.nativeInp = optionsFile.modelSpace(iModel,iTask).prc_config.transp_prc_fun(c, input.prc.transInp);
                end
            end
            % save simulation input
            s.task(iTask).data = data;
            sim.agent(iAgent,iModel).task(iTask).data = s.task(iTask).data;
            sim.agent(iAgent,iModel).task(iTask).input = input;

            % Update the rng state idx
            optionsFile.rng.idx    = optionsFile.rng.idx+1;
            if optionsFile.rng.idx == (length(optionsFile.rng.settings.State)+1)
                optionsFile.rng.idx = 1;
            end
        end
    end
end

%% PLOT predictions
for iTask = 1:numel(optionsFile.cohort(cohortNo).testTask)
    for iModel = 1:numel(optionsFile.model.space)
        for iAgent = 1:optionsFile.simulations.nSamples

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
        txt = ['Simulation results (n=50) using ', optionsFile.model.prc{iModel}];
        title(txt)
        hold on
        set(gcf, 'color', 'none');   %transparent background
        set(gca, 'color', 'none');   %transparent background
        xticks([0 40 80 120 160 200 240 280])
        hold on;

        figdir = fullfile([char(optionsFile.paths.cohort(cohortNo).simPlots),optionsFile.model.space{iModel},'_predictions', optionsFile.cohort(cohortNo).testTask(iTask).name]);
        save([figdir,'.fig'])
        print(figdir, '-dpng');
        close;

        % reset rng state idx
        optionsFile.rng.idx = 1;

        %% SAVE model simulation specs as struct
        save([optionsFile.paths.cohort(cohortNo).simulations,optionsFile.model.space{iModel},optionsFile.cohort(cohortNo).testTask(iTask).name,'_sim'], '-struct', 'sim');
    end
end
disp('simulated data successfully created.')

end