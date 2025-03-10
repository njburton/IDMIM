function [] = hgf_plot_param_pdf(paramNames,data,prior,posterior,i,type)

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

    % get data
    idx = prior.prc_idx(1,i);
    mMaxMean = round(abs(max(posterior.prc_config.priormus))); pMaxMean = round(abs(max(prior.prc_config.priormus)));
    mMaxSa   = round(abs(max(posterior.prc_config.priorsas))); pMaxSa = round(abs(max(prior.prc_config.priorsas)));
    maxMeans = [mMaxMean,pMaxMean]; maxSas = [mMaxSa,pMaxSa];
    x_min = -(max(maxMeans) + max(maxSas))-1;
    x_max = max(maxMeans) + max(maxSas)+1;
    x     = x_min:0.1:x_max;

    % create prior predictive density function based on prior mus and prior variances
    y_posterior   = normpdf(x, posterior.prc_config.priormus(1,idx), sqrt(posterior.prc_config.priorsas(1,idx)));
    y_prior = normpdf(x, prior.prc_config.priormus(1,idx), sqrt(prior.prc_config.priorsas(1,idx)));

    % plot
    figure('Color', [1 1 1]);
    plot(x, y_posterior, 'k')
    hold on
    plot(x, y_prior, 'k--')
    hold on
    plot(data.prc_est(:,i), -0.05, 'ko')

    % legends and titles
    ylim([-0.1 1.5])
    str = sprintf('pilot mu = %0.3g, pilot sa = %0.3g \n init mu = %0.3g, init sa = %0.3g',...
        posterior.prc_config.priormus(1,idx), sqrt(posterior.prc_config.priorsas(1,idx)),...
        prior.prc_config.priormus(1,idx),sqrt(prior.prc_config.priorsas(1,idx)));
    T = text(min(get(gca, 'xlim')), max(get(gca, 'ylim')), str);
    set(T,'fontSize', 12,'verticalalignment', 'top', 'horizontalalignment', 'left');
    legend('posterior','prior','MAP estimates')

    title(paramNames{i})

%% PLOTTING Priors for OBSERVATIONAL Models

elseif strcmp(type, 'obs')

    % get data
    idx = prior.obs_idx(1,i);
    mMaxMean = round(abs(max(posterior.obs_config.priormus))); pMaxMean = round(abs(max(prior.obs_config.priormus)));
    mMaxSa   = round(abs(max(posterior.obs_config.priorsas))); pMaxSa = round(abs(max(prior.obs_config.priorsas)));
    maxMeans = [mMaxMean,pMaxMean]; maxSas = [mMaxSa,pMaxSa];
    x_min    = -(max(maxMeans) + max(maxSas))-1;
    x_max    = max(maxMeans) + max(maxSas)+1;
    x = x_min:0.1:x_max;

    % create prior predictive density function based on prior mus and prior variances
    y_posterior = normpdf(x, posterior.obs_config.priormus(1,idx), sqrt(posterior.obs_config.priorsas(1,idx)));
    y_prior = normpdf(x, prior.obs_config.priormus(1,idx), sqrt(prior.obs_config.priorsas(1,idx)));

    % plot
    figure('Color', [1 1 1]);
    plot(x, y_posterior, 'k')
    hold on
    plot(x, y_prior, 'k--')
    hold on
    plot(data.obs_est(:,i), -0.05, 'ko')

    % legends and titles
    ylim([-0.1 1.5])
    str = sprintf('pilot mu = %0.3g, pilot sa = %0.3g \n init mu = %0.3g, init sa = %0.3g',...
        posterior.obs_config.priormus(1,idx), sqrt(posterior.obs_config.priorsas(1,idx)),...
        prior.obs_config.priormus(1,idx),sqrt(prior.obs_config.priorsas(1,idx)));
    T = text(min(get(gca, 'xlim')), max(get(gca, 'ylim')), str);
    set(T, 'fontSize', 12,'verticalalignment','top','horizontalalignment','left');
    legend('posterior','prior','MAP estimates')

    title(paramNames{i})

end

end