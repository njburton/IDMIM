function [priors,optionsFile] = get_informedPriors(priorCohort,subCohort,iTask,iCondition,iRep,optionsHandle)

%% get_informedPriors_from_pilotData
%  Parameter recovery analysis based on simulations. This step will be
%  executed if optionsFile.doSimulations = 1;
%
%   SYNTAX:       parameter_recovery(cohortNo,{'treatment','controls',[]})
%
%   IN: cohortNo:  integer, cohort number, see optionsFile for what cohort
%                            corresponds to what number in the
%                            optionsFile.cohort(cohortNo).name struct. This
%                            allows to run the pipeline and its functions for different
%                            cohorts whose expcifications have been set in runOptions.m
%
% Original: 29-05-2024; Katharina V. Wellstein,
%           katharina.wellstein@newcastle.edu.au
%
% -------------------------------------------------------------------------
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

if exist('optionsFile.mat','file')==2
    load('optionsFile.mat');
else
    optionsFile = runOptions();
end

disp('************************************** GET_PRIORS_FROM_PILOT_DATA **************************************');
disp('*');
disp('*');


%% LOAD inverted mouse data
% and save data into rec.est struct and paramete values for recovery into
% rec.param.{}.est
currTask = optionsFile.cohort(priorCohort).testTask(iTask).name;

[mouseIDs,nSize] = getSampleSpecs(optionsFile,priorCohort,subCohort);

for iMouse = 1:nSize
    currMouse = mouseIDs{iMouse};
    for m_est = 1:numel(optionsFile.model.space)
        loadName = getFileName(optionsFile.cohort(priorCohort).taskPrefix,currTask,...
                    subCohort,iCondition,iRep,optionsFile.cohort(priorCohort).taskRepetitions,[]);
        % load results from real data model inversion
            rec.est(iMouse,m_est).task(iTask).data =  load([char(optionsFile.paths.cohort(priorCohort).results),...
                'mouse',char(currMouse),'_',loadName,'_',optionsFile.dataFiles.rawFitFile{m_est},'.mat']);
    end
end

%% AVERAGE MAP estimates across trajectories
priors = struct();

for m = 1:numel(optionsFile.model.space)
    for i = 1:size(optionsFile.modelSpace(m).prc_idx,2)
        for n = 1:size(rec.est,1)
            prc_posteriorMus(n) = rec.est(n,m).task(1,iTask).data.est.p_prc.ptrans(optionsFile.modelSpace(m).prc_idx(i));
        end

        [priors.prc_posteriorSa(m).param(i),priors.prc_posteriorMu(m).param(i) ] = robustcov(prc_posteriorMus);
    end
clear i;
    for j = 1:size(optionsFile.modelSpace(m).obs_idx,2)

        for n = 1:size(rec.est,1)
            obs_posteriorMus(n) = rec.est(n,m).task(1,iTask).data.est.p_obs.ptrans(optionsFile.modelSpace(m).obs_idx(j));
        end
        [priors.obs_posteriorSa(m).param(j),priors.obs_posteriorMu(m).param(j) ] = robustcov(obs_posteriorMus);
    end
clear j;

priors.config = optionsFile.modelSpace;

%% SAVE pilot priors for main dataset into appropriate struct

    % perceptual model
    for i = 1:size(optionsFile.modelSpace(m,iTask).prc_idx,2)
        priors.config(m,iTask).prc_config.priorsas(optionsFile.modelSpace(m,iTask).prc_idx(i)) = ...
            round(priors.prc_posteriorSa(m).param(i),4);
        priors.config(m,iTask).prc_config.priormus(optionsFile.modelSpace(m,iTask).prc_idx(i)) = ...
            round(priors.prc_posteriorMu(m).param(i),4);
    end
    priors.config(m,iTask).prc_config           = tapas_align_priors_mod(priors.config(m,iTask).prc_config);
    optionsFile.modelSpace(m,iTask).prc_config  = priors.config(m,iTask).prc_config;

    % observational model
    for j = 1:size(optionsFile.modelSpace(m,iTask).obs_idx,2)
        priors.config(m,iTask).obs_config.priorsas(optionsFile.modelSpace(m,iTask).obs_idx(j)) = ...
            round(priors.prc_posteriorSa(m).param(j),4);
        priors.config(m,iTask).obs_config.priormus(optionsFile.modelSpace(m,iTask).obs_idx(j)) = ...
            round(priors.obs_posteriorMu(m).param(j),4);
    end
    priors.config(m,iTask).obs_config           = tapas_align_priors_mod(priors.config(m,iTask).obs_config);
    optionsFile.modelSpace(m,iTask).obs_config  = priors.config(m,iTask).obs_config;
end

if optionsHandle
%% SAVE options file
save([optionsFile.paths.projDir,'optionsFile.mat'],'optionsFile');
end
end