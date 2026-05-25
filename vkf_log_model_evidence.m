function [loglik, bic, aic, lme] = vkf_log_model_evidence(y, lambda, v0, omega, params_response)
% VKF_LOG_MODEL_EVIDENCE Calculate log model evidence for VKF fit
%
% Syntax:
%   [loglik, bic, aic, lme] = vkf_log_model_evidence(y, lambda, v0, omega, params_response)
%
% Inputs:
%   y                - observed binary outcomes [n_trials x 1]
%   lambda           - volatility learning rate (0-1)
%   v0               - initial volatility
%   omega            - observation noise variance
%   params_response  - response/decision parameters [n_params x 1]
%
% Outputs:
%   loglik           - negative log-likelihood
%   bic              - Bayesian Information Criterion
%   aic              - Akaike Information Criterion
%   lme              - log model evidence (Laplace approximation)

% Get number of trials
n_trials = length(y);

% Run VKF to get beliefs
dv = vkf_bin(y, lambda, v0, omega);

% Compute response probabilities using decision model
[loglik, beta] = fit_A_response(dv, y, params_response);

% Count number of parameters
n_params = length(params_response) + 3;  % +3 for lambda, v0, omega

% Compute information criteria
bic = -2 * loglik + n_params * log(n_trials);
aic = -2 * loglik + 2 * n_params;

% Approximate log model evidence using Laplace approximation
% LME ≈ log(likelihood) - 0.5 * n_params * log(n_trials)
lme = loglik - 0.5 * n_params * log(n_trials);

end

function [loglik, beta] = fit_A_response(dv, y, params_response)
% FIT_A_RESPONSE Compute log-likelihood of responses given beliefs
%
% Format: [loglik, beta] = fit_A_response(dv, y, params_response)

beta = exp(params_response(1));
% Additional response parameters...

% Compute softmax probabilities
z = dv * beta;
ev = exp(z);
p_correct = ev ./ (ev + (1 - ev));

% Compute log-likelihood
loglik = sum(y .* log(p_correct + eps) + (1 - y) .* log(1 - p_correct + eps));

end