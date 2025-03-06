function performBMS(cohortNo)

%% performBMS
%  Performs Bayesian Model Selection to determine what model in the model
%  space describes the data acquired in the current dataset (cohort) best
%
%   SYNTAX:       preformBMS(cohortNo)
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
% specifications for this analysis
if exist('optionsFile.mat','file')==2
    load("optionsFile.mat");
else
    optionsFile = runOptions();
end

addpath(genpath([optionsFile.paths.toolboxDir,'spm']));

disp('************************************** BAYESIAN MODEL SELECTION **************************************');
disp('*');
disp('*');

% load data
load([optionsFile.paths.cohort(cohortNo).results,optionsFile.cohort(cohortNo).name,filesep,'modelInv.mat']);



for iModel = length(optionsFile.model.space)
    for iMouse = 1:optionsFile.cohort.nSize
        res.LME(iMouse,iModel)   = allMice(iMouse,iModel).est.optim.LME;
        res.prc_param(iMouse,iModel).ptrans = allMice(iMouse,iModel).est.p_prc.ptrans(optionsFile.modelSpace(iModel).prc_idx);
        res.obs_param(iMouse,iModel).ptrans = allMice(iMouse,iModel).est.p_obs.ptrans(optionsFile.modelSpace(iModel).obs_idx);
    end
en


end