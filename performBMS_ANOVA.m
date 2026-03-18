function performBMS_ANOVA(cohortNo,iTask)

%% performBMS
%  Performs Bayesian Model Selection to determine what model in the model
%  space describes the data acquired in the current dataset (cohort) best
%
%   SYNTAX:       preformBMS(cohortNo)
%
%   IN: cohortNo:  integer, cohort number, see optionsFile for what cohort
%                            corresponds to what number in the
%                            optionsFile.cohort(cohortNo).name struct.
%
%       subCohort: string, {'control','treatment'} OR [], if you are running this
%                           function for all subCohorts use [], otherwise specify using the appropriate string
%
%       iTask: integer, task number see optionsFile for what task
%                            corresponds to what number.
%
%       iCondition: integer, condition number. See optionsFile for what what place in the cell {cond1, cond2...}
%                            the condition that you want to run this function for in appears. If you are calling
%                            this function from the runAnalysis.m or another wrapper function, loop through
%                            conditions there.
%
%       iRep:       integer, repetition number. iRep= 1 if the current Task is not repeated more than once in this cohort.
%
%       >>!! NOTE: All the above variables are saved inf the optionsFile struct and specifed here: setDatasetSpecifics.m << !!
%
% Original: 29-05-2024; Katharina V. Wellstein,
%           katharina.wellstein@newcastle.edu.au
%
% -------------------------------------------------------------------------
% This file is released under the terms of the GNU General Public Licence
% (GPL), version 3. You can redistribute it and/or modify it under the
% terms of the GPL (either version 3 or, at your option, any later version.
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

%% Suppress SPM/FieldTrip path warnings
warning('off', 'MATLAB:rmpath:DirNotFound');

%% INITIALIZE Variables for running this function

disp('************************************** BAYESIAN MODEL SELECTION **************************************');
disp('*');
disp('*');

% load or run options for running this function
if exist('optionsFile.mat','file')==2
    load('optionsFile.mat');
else
    optionsFile = runOptions();
end

% prespecify variables needed for running this function
nModels  = numel(optionsFile.model.space);
nReps    = optionsFile.cohort(cohortNo).taskRepetitions;
currTask = optionsFile.cohort(cohortNo).testTask(iTask).name;

% model settings
addpath(genpath([optionsFile.paths.toolboxDir,'spm']));
optionsFile = setup_configFiles(optionsFile,cohortNo);

% get mouse IDs
if isempty(optionsFile.cohort(cohortNo).conditions)
    nGroups = size(optionsFile.cohort(cohortNo).subCohorts,2);
    groups  = optionsFile.cohort(cohortNo).subCohorts;
    effect = 'bwtGroups';
else
    nGroups = size(optionsFile.cohort(cohortNo).conditions,2);
    groups  = optionsFile.cohort(cohortNo).conditions;
    effect = 'withinGroups';
end

%% EXCLUDE MICE from this analysis
% check available mouse data and exclusion criteria

% check for what mice no data is available
for iGroup = 1:nGroups
if strcmp(effect,'bwtGroups')
    [mouseIDs,nSize] = getSampleVars(optionsFile,cohortNo,groups{iGroup});
else
    [mouseIDs,nSize] = getSampleVars(optionsFile,cohortNo,'all');
end
    noDataArray = zeros(1,nSize);
    exclArray   = zeros(1,nSize);

    for iMouse = 1:nSize
        currMouse = mouseIDs{iMouse};
        if isempty(optionsFile.cohort(cohortNo).conditions)
            loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,...
                [],[],1,1,'info');
        else
            loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,...
                [],groups{iGroup},1,1,'info');
        end

        if isfile([char(optionsFile.paths.cohort(cohortNo).data),'mouse',char(currMouse),'_',loadInfoName,'.mat'])
        else
            disp(['data for mouse ', currMouse,' not available']);
            noDataArray(iMouse) = iMouse;
        end
    end

    noDataArray = sort(noDataArray,'descend');
    noDataArray(noDataArray==0)=[];

    for i=noDataArray
        mouseIDs(i) =[];
    end

    % update sample size
    nSize = numel(mouseIDs);

    % check what mice are to be excluded based on exclusion criteria
    for iMouse = 1:nSize
        currMouse = mouseIDs{iMouse};
        if isempty(optionsFile.cohort(cohortNo).conditions)
            loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,...
                [],[],1,1,'info');
        else
            loadInfoName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,...
                [],groups{iGroup},1,1,'info');
        end

        load([char(optionsFile.paths.cohort(cohortNo).data),...
            'mouse',char(currMouse),'_',loadInfoName]);
        if any([MouseInfoTable.exclCrit2_met,MouseInfoTable.exclCrit1_met],'all')
            disp(['mouse ', currMouse,' excluded based on exclusion criteria']);
            exclArray(iMouse) = iMouse;
        end
    end

    exclArray = sort(exclArray,'descend');
    exclArray(exclArray==0)=[];

    for i=exclArray
        mouseIDs(i) =[];
    end
 if strcmp(effect,'bwtGroups')
    if iGroup == 1
        allMouseIDs = char(mouseIDs);
        groupArray  = ones(numel(mouseIDs),1);
    else
        allMouseIDs = [allMouseIDs; char(mouseIDs)];
        groupArray  = [groupArray; iGroup*ones(numel(mouseIDs),1)];
    end
 else
     if iGroup == 1
         groupArray  = ones(numel(mouseIDs),1)';
     else
        groupArray = [groupArray iGroup*ones(numel(mouseIDs),1)'];
     end
     allMouseIDs = char(mouseIDs);
 end
end

% update sample size
nSize = size(allMouseIDs,1);

%% LOAD mice
for iGroup = 1:nGroups
    for iMouse = 1:nSize
        currMouse = allMouseIDs(iMouse,:);
        for iModel = 1:nModels
            % load results from real data model inversion
            if isempty(optionsFile.cohort(cohortNo).conditions)
                loadName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,...
                    [],[],1,1,[]);
            else
                loadName = getFileName(optionsFile.cohort(cohortNo).taskPrefix,currTask,...
                    [],groups{iGroup},1,1,[]);
            end
            load([char(optionsFile.paths.cohort(cohortNo).results),...
                'mouse',char(currMouse),'_',loadName,'_',optionsFile.dataFiles.rawFitFile{iModel},'.mat']);
            
            if strcmp(effect,'bwtGroups')
                res(iGroup).LME(iModel,iMouse)              = est.optim.LME;
                res(iGroup).prc_param(iModel,iMouse).ptrans = est.p_prc.ptrans(optionsFile.modelSpace(iModel).prc_idx);
                res(iGroup).obs_param(iModel,iMouse).ptrans = est.p_obs.ptrans(optionsFile.modelSpace(iModel).obs_idx);

            elseif strcmp(effect,'withinGroups')
                res.LME(iModel,iMouse,iGroup)              = est.optim.LME;
                res.prc_param(iModel,iMouse,iGroup).ptrans = est.p_prc.ptrans(optionsFile.modelSpace(iModel).prc_idx);
                res.obs_param(iModel,iMouse,iGroup).ptrans = est.p_obs.ptrans(optionsFile.modelSpace(iModel).obs_idx);
            end
        end
    end
end

%% PERFORM rfx BMS ANOVA



if strcmp(effect,'bwtGroups')
    for g = 1:nGroups
        LMEs{g} = res(g).LME(:,groupArray==g); 
    end % get LMEs for current group

        [h,p] = VBA_groupBMC_btwGroups(LMEs,[]);  
elseif strcmp(effect,'withinGroups')
        [ep,out] = VBA_groupBMC_btwConds(res.LME,[]);
end

%% save figures
% if strcmp(effect,'bwtGroups')
% figTitle = getFigTitle(optionsFile,cohortNo,subCohort,[]);
% else
%     figTitle = getFigTitle(optionsFile,cohortNo,subCohort,[]);
% end

end