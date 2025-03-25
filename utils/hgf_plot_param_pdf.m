function [] = hgf_plot_param_pdf(paramNames,data,i,j,t,type)

%% hgf_plot_param_pdf
%  plots prior predictive distributions of the priors generated from the
%  pilot dataset as well as the default priors based on the toolbox.
%  This is a subfunction of WBEST_get_priors_from_pilotData.m
%
%   SYNTAX:  hgf_plot_param_pdf(paramNames,data,main,pilot,i,type)
% M(m),res.main.ModSpace(m),res.pilot.ModSpace(m), j, 'prc')
%   IN:      paramNames: names of the free parameters of the model being
%                        processed in WBEST_get_priors_from_pilotData.m
%            data:       struct with MAP estimates for the parameters of the
%                        given model (see above)
%            main:       model space specifications which were the basis
%                        for inverting the main dataset (default priors)
%            pilot:      model space specifications which were the basis
%                        for inverting the pilot dataset (default priors)
%            i:          looping index for the current model being
%                        processed (see above)
%            type:       string specifying if the model being processed is
%                        a perceptual ('prc') or observational ('obs') model
%
% Original: 29-10-2021; Alex Hess
% Amended:  30-05-2023; Katharina V. Wellstein
% -------------------------------------------------------------------------
% Copyright (C) 2023 TNU, Institute for Biomedical Engineering, University of Zurich and ETH Zurich.
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

%% PLOTTING Priors for PERCEPTUAL Models

if strcmp(type, 'prc')
     priorMu  = data(1,1).task(1,t).data.est.c_prc.priormus(i);
     priorSa  = data(1,1).task(1,t).data.est.c_prc.priorsas(i);
    for n = 1:numel(data)
        posteriorMus(n,1) = data(n,1).task(1,t).data.est.p_prc.ptrans(i);
    end

elseif strcmp(type, 'obs')
     priorMu  = data(1,1).task(1,t).data.est.c_obs.priormus(i);
     priorSa  = data(1,1).task(1,t).data.est.c_obs.priorsas(i);
    for n = 1:numel(data)
        posteriorMus(n,1) = data(n,1).task(1,t).data.est.p_obs.ptrans(i);
    end
end

    [posteriorSa,posteriorMu] = robustcov(posteriorMus);
    
    % get data
    mMaxMean = round(abs(max(posteriorMu))); pMaxMean = round(abs(max(priorMu)));
    mMaxSa   = round(abs(max(priorSa))); pMaxSa = round(abs(max(posteriorSa)));
    maxMeans = [mMaxMean,pMaxMean];
    maxSas   = [mMaxSa,pMaxSa];
    x_min = -(max(maxMeans) + max(maxSas))-1;
    x_max = max(maxMeans) + max(maxSas)+1;
    x     = x_min:0.1:x_max;

    % create prior predictive density function based on prior mus and prior variances
    y_posterior = normpdf(x, posteriorMu, sqrt(posteriorSa));
    y_prior     = normpdf(x, priorMu, sqrt(priorSa));

    % plot
    figure('Color', [1 1 1]);
    plot(x, y_posterior, 'k')
    hold on
    plot(x, y_prior, 'k--')
    ylim([-0.1 1.5])

    % legends and titles
    str = sprintf('prior mu = %0.3g, prior sa = %0.3g \n posterior mu = %0.3g, posterior sa = %0.3g',...
        priorMu, sqrt(priorSa),...
        posteriorMu,sqrt(posteriorSa));
    T = text(min(get(gca, 'xlim')), max(get(gca, 'ylim')), str);
    set(T,'fontSize', 16,'verticalalignment', 'top', 'horizontalalignment', 'left');
    legend('posterior','prior','MAP estimates','fontSize', 16)

    title(paramNames{j})

end