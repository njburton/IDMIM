function [priors,optionsFile] = get_informedPriors(priorCohort,subCohort,iTask,iCondition,iRep)

%% get_informedPriors
%  gets MAP estimates from cohort specified by 'priorCohort' and saves into
%  config files used in the currently analysed cohort. What priorCohort,
%  task,condition, etc. the MAP estimates should be taken from is specified
%  in getDataSetSpecifics.m and saved in optionsFile.
%
%   SYNTAX:       [priors,optionsFile] = get_informedPriors(priorCohort,subCohort,iTask,iCondition,iRep)
%
%   IN: priorCohort:  integer, cohort number, from optionsFile.cohort(cohortNo).priorsFromCohort.
%       subCohort:    string or [] if n.a., {'control','treatment'} specified in
%                    optionsFile.cohort(cohortNo).priorsFromSubCohort, in case only
%                    subcohort should inform the current dataset or empty
%       iTask:        integer or [] if n.a., task number specified in optionsFile.cohort(cohortNo).priorsFromTask
%       iCondition:   integer or [] if n.a., condition number of where priors should be taken from specified in
%                              optionsFile.cohort(cohortNo).priorsFromCondition
%       iRep:         integer or [] if n.a., repetition number of where priors should be taken from specified in
%                              optionsFile.cohort(cohortNo).priorsFromRepetition
%
%
%   OUT: priors:      struct, contains priors from priorCohort
%
%        optionsfile: struct, updated optionsFile with new config file
%                             settings
%
% Coded by: 30-04-2025, Katharina V. Wellstein
%                       https://github.com/kwellstein
%
% -------------------------------------------------------------------------
% Copyright (C) 2025
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

if exist('optionsFile.mat','file')==2
    load('optionsFile.mat');
else
    optionsFile = runOptions();
end

%% LOAD inverted mouse data
currTask = optionsFile.cohort(priorCohort).testTask(iTask).name;

% get mouse IDs and sample size
[mouseIDs,nSize] = getSampleVars(optionsFile,priorCohort,subCohort);

for iMouse = 1:nSize
    currMouse = mouseIDs{iMouse};
    for m_est = 1:numel(optionsFile.model.space)
        % get file name
        loadName = getFileName(optionsFile.cohort(priorCohort).taskPrefix,currTask,...
            subCohort,iCondition,iRep,optionsFile.cohort(priorCohort).taskRepetitions,[]);
        % load results from real data model inversion
        rec.est(iMouse,m_est).task(iTask).data =  load([char(optionsFile.paths.cohort(priorCohort).results),...
            'mouse',char(currMouse),'_',loadName,'_',optionsFile.dataFiles.rawFitFile{m_est},'.mat']);
    end
end

%% AVERAGE MAP estimates across trajectories
priors = struct();

for iModel = 1:numel(optionsFile.model.space)
    for pPrc = 1:size(optionsFile.modelSpace(iModel).prc_idx,2)
        for n = 1:size(rec.est,1)
            % store perceptual model MAPs in variable
            prc_posteriorMus(n) = rec.est(n,iModel).task(1,iTask).data.est.p_prc.ptrans(optionsFile.modelSpace(iModel).prc_idx(pPrc));
        end

        [priors.prc_posteriorSa(iModel).param(pPrc),priors.prc_posteriorMu(iModel).param(pPrc) ] = robustcov(prc_posteriorMus);
    end
    clear n;

    for pObs = 1:size(optionsFile.modelSpace(iModel).obs_idx,2)
        for n = 1:size(rec.est,1)
            % store perceptual model MAPs in variable
            obs_posteriorMus(n) = rec.est(n,iModel).task(1,iTask).data.est.p_obs.ptrans(optionsFile.modelSpace(iModel).obs_idx(pObs));
        end
        [priors.obs_posteriorSa(iModel).param(pObs),priors.obs_posteriorMu(iModel).param(pObs) ] = robustcov(obs_posteriorMus);
    end
    clear n;

    % save in a priors struct
    priors.config = optionsFile.modelSpace;

    %% SAVE pilot priors for main dataset into appropriate struct

    % perceptual model
    for pPrc = 1:size(optionsFile.modelSpace(iModel,iTask).prc_idx,2)
        priors.config(iModel,iTask).prc_config.priorsas(optionsFile.modelSpace(iModel,iTask).prc_idx(pPrc)) = ...
            round(priors.prc_posteriorSa(iModel).param(pPrc),4);
        priors.config(iModel,iTask).prc_config.priormus(optionsFile.modelSpace(iModel,iTask).prc_idx(pPrc)) = ...
            round(priors.prc_posteriorMu(iModel).param(pPrc),4);
    end
    priors.config(iModel,iTask).prc_config          = tapas_align_priors_mod(priors.config(iModel,iTask).prc_config);
    optionsFile.modelSpace(iModel,iTask).prc_config = priors.config(iModel,iTask).prc_config;

    % observational model
    for pObs = 1:size(optionsFile.modelSpace(iModel,iTask).obs_idx,2)
        priors.config(iModel,iTask).obs_config.priorsas(optionsFile.modelSpace(iModel,iTask).obs_idx(pObs)) = ...
            round(priors.prc_posteriorSa(iModel).param(pObs),4);
        priors.config(iModel,iTask).obs_config.priormus(optionsFile.modelSpace(iModel,iTask).obs_idx(pObs)) = ...
            round(priors.obs_posteriorMu(iModel).param(pObs),4);
    end
    priors.config(iModel,iTask).obs_config      = tapas_align_priors_mod(priors.config(iModel,iTask).obs_config);
    optionsFile.modelSpace(iModel,iTask).obs_config  = priors.config(iModel,iTask).obs_config;
end

end