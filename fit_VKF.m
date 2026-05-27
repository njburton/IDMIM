function [params_fit,model_quantities,optim] = fit_VKF(c,y, nRestarts, varargin)
    % Maximum Likelihood Estimation for Volatile Kalman Filter (Binary Responses)
    %
    % Fits VKF parameters (lambda, v0, omega) to binary response data using
    % maximum likelihood estimation. Includes multiple optimization algorithms,
    % confidence intervals, and model diagnostics.
    %
    % Usage:
    %   [params, ll, info] = vkf_mle(y)                    % Default settings
    %   [params, ll, info] = vkf_mle(y, 'method', 'bfgs')  % Specify optimizer
    %   [params, ll, info] = vkf_mle(y, 'init', p0)        % Initial parameters
    %   [params, ll, info] = vkf_mle(y, 'verbose', true)   % Display progress
    %
    % Inputs:
    %   y          - Binary observations (nTrials x 1), values in {0, 1}
    %
    % Optional Name-Value Arguments:
    %   'method'   - Optimization method: 'fmincon' (default), 'bfgs', 'ga', 'pso'
    %   'init'     - Initial parameter guesses: struct or [lambda, v0, omega]
    %   'verbose'  - Display convergence information (true/false, default: true)
    %   'nRestarts'- Number of random restarts (default: 3)
    %   'confidence' - Compute confidence intervals (true/false, default: true)
    %   'hessian'  - Compute Hessian for standard errors (true/false, default: true)
    %
    % Outputs:
    %   params_fit - Structure with fitted parameters:
    %       .lambda - Volatility learning rate
    %       .v0     - Initial volatility
    %       .omega  - Observation noise variance
    %       .ll     - Log-likelihood at convergence
    %       .lme
    %       .bic
    %       .aic
    %
    %   ll_fit     - Final log-likelihood value
    %
    %   info       - Diagnostic information:
    %       .exitflag      - Optimization exit code
    %       .iterations    - Number of iterations
    %       .gradient      - Gradient at solution
    %       .hessian       - Hessian matrix (if requested)
    %       .se            - Standard errors of parameters
    %       .ci_lower      - 95% lower confidence interval
    %       .ci_upper      - 95% upper confidence interval
    %       .initial_ll    - Log-likelihood at initial guess
    %       .ll_improvement - Improvement in log-likelihood
    %       .condition_number - Hessian condition number
    %
    % Examples:
    %   % Fit with defaults
    %   y = [1; 0; 1; 1; 0; 0; 1];
    %   [params, ll, info] = vkf_mle(y);
    %
    %   % Fit with custom initial guess
    %   p0 = struct('lambda', 0.4, 'v0', 0.5, 'omega', 0.2);
    %   [params, ll, info] = vkf_mle(y, 'init', p0, 'method', 'bfgs');
    %
    %   % Fit multiple random restarts
    %   [params, ll, info] = vkf_mle(y, 'nRestarts', 10, 'verbose', true);
    %
    % See also: VKF_BIN, FIT_VKF_ML_GRID, VKF_MLE_PROFILE
    
    %% Parse inputs
    p = inputParser;
    addParameter(p, 'method', 'fmincon', @ischar);
    addParameter(p, 'init', [], @(x) isstruct(x) || isvector(x));
    addParameter(p, 'verbose', true, @islogical);
    addParameter(p, 'confidence', true, @islogical);
    addParameter(p, 'hessian', true, @islogical);
    addParameter(p, 'lb', [log(0.01), log(0.01), log(0.01)]);
    addParameter(p, 'ub', [log(0.99), log(5.0), log(2.0)]);
    
    parse(p, varargin{:});
    opts = p.Results;

    % Estimate mode of posterior parameter distribution (MAP estimate)
    n_prcpars = length(c.c_prc.priormus);
    n_obspars = length(c.c_obs.priormus);


    % Validate input
    assert(isvector(y) && all(ismember(y(:), [0, 1])), ...
        'Input y must be a binary vector (0 or 1)');
    y = y(:);  % Ensure column vector
    
    if opts.verbose
        fprintf('=== VKF Optimiztion ===\n');
        fprintf('Number of trials: %d\n', length(y));
        fprintf('Number of trials: %d\n', length(y));
        fprintf('Response distribution: %.1f%% ones, %.1f%% zeros\n', ...
            100*mean(y), 100*(1-mean(y)));
    end
    
    %% Initialize parameters
    if isempty(opts.init)
        x0_log = [log(0.2), log(0.3), log(0.2)];  % Default initial guess
    elseif isstruct(opts.init)
        x0_log = [log(c.c_prc.lambda_mu), log(c.c_obs.v0_mu), log(c.c_obs.omega_mu)];
    end
    
    % Compute initial log-likelihood
    negll_init = compute_ll_vkf(y, c);

    % Calculate the log-prior of the perceptual parameters.
% Only parameters that are neither NaN nor fixed (non-zero prior variance) are relevant.
prc_idx = c.c_prc.priorsas;
prc_idx(isnan(prc_idx)) = 0;
prc_idx = find(prc_idx);

logPrcPriors = -1/2.*log(8*atan(1).*c.c_prc.priorsas(prc_idx)) - 1/2.*(x0_log(prc_idx) - c.c_prc.priormus(prc_idx)).^2./c.c_prc.priorsas(prc_idx);
logPrcPrior  = sum(logPrcPriors);

% Calculate the log-prior of the observation parameters.
% Only parameters that are neither NaN nor fixed (non-zero prior variance) are relevant.
obs_idx = c.c_obs.priorsas;
obs_idx(isnan(obs_idx)) = 0;
obs_idx = find(obs_idx);

logObsPriors = -1/2.*log(8*atan(1).*c.c_obs.priorsas(obs_idx)) - 1/2.*(x0_log(obs_idx) - c.c_obs.priormus(obs_idx)).^2./c.c_obs.priorsas(obs_idx);
logObsPrior  = sum(logObsPriors);
opt_algo    = eval(c.optim.optalgo);
negLogJoint = -(logLl + logPrcPrior + logObsPrior);
init = [c.c_prc.priormus, c.c_obs.priormus];

% Determine indices of parameters to optimize (i.e., those that are not fixed or NaN)
opt_idx = [c.c_prc.priorsas, c.c_obs.priorsas];
opt_idx(isnan(opt_idx)) = 0;
opt_idx = find(opt_idx);

% Check whether priors are in a region where the objective function can be evaluated
stable = 0; nresamp = 0;
while stable == 0
    try
        [dummy1, dummy2, rval, err] = nlj(init);
        if rval ~= 0
            rethrow(err);
        end
        stable = 1;
    catch
        disp('Warning: priors in unstable region for this startpoint.')
        disp('Re-sampling startpoints...')
        % Get standard deviations of parameter priors
        priorsds = sqrt([c.c_prc.priorsas, c.c_obs.priorsas]);
        optsds = priorsds(opt_idx);
        % re-sample starting points
        init(opt_idx) = init(opt_idx) + randn(1,length(optsds)).*optsds;
        % update re-sampling counter
        nresamp = nresamp + 1;
        if nresamp > 1000
            error('tapas:hgf:StartpointUnstableRegionOfPriors', 'Model inversion aborted. No stable startpoint found for the current priors in 1000 startpoint sampling iterations.')
        end
    end
end

% Do an optimization run
optres = optimrun(nlj, init, opt_idx, opt_algo, c.optim.c_opt);

% Record optimization results
c.optim.init            = optres.init;
c.optim.final           = optres.final;
c.optim.H               = optres.H;
c.optim.Sigma           = optres.Sigma;
c.optim.Corr            = optres.Corr;
c.optim.trialLogLlsplit = optres.trialLogLlsplit;
c.optim.negLl           = optres.negLl;
c.optim.negLj           = optres.negLj;
c.optim.LME             = optres.LME;
c.optim.decompLME       = optres.decompLME;
c.optim.accu            = optres.accu;
c.optim.comp            = optres.comp;
c.optim.iter            = optres.iter;

% Do further optimization runs with random initialization
if isfield(c.optim.c_opt, 'nRandInit') && c.optim.c_opt.nRandInit > 0

    % Set seed if provided
    if isnan(c.optim.c_opt.seedRandInit)
        rng('shuffle');
    else
        rng(c.optim.c_opt.seedRandInit)
    end

    for i = 1:c.optim.c_opt.nRandInit
        % Use prior mean as starting value for random draw
        init = [c.c_prc.priormus, c.c_obs.priormus];

        % Get standard deviations of parameter priors
        priorsds = sqrt([c.c_prc.priorsas, c.c_obs.priorsas]);
        optsds = priorsds(opt_idx);

        % Add random values to prior means, drawn from Gaussian with prior sd
        init(opt_idx) = init(opt_idx) + randn(1,length(optsds)).*optsds;

        % Check whether initialization point is in a region where the objective
        % function can be evaluated
        [dummy1, dummy2, rval, err] = nlj(init);
        if rval ~= 0
            rethrow(err);
        end

        % Do an optimization run
        optres = optimrun(nlj, init, opt_idx, opt_algo, c.optim.c_opt);

        % Record optimization if the LME is better than the previous record
        if optres.LME > c.optim.LME
            c.optim.init            = optres.init;
            c.optim.final           = optres.final;
            c.optim.H               = optres.H;
            c.optim.Sigma           = optres.Sigma;
            c.optim.Corr            = optres.Corr;
            c.optim.trialLogLlsplit = optres.trialLogLlsplit;
            c.optim.negLl           = optres.negLl;
            c.optim.negLj           = optres.negLj;
            c.optim.LME             = optres.LME;
            c.optim.decompLME       = optres.decompLME;
            c.optim.accu            = optres.accu;
            c.optim.comp            = optres.comp;
            c.optim.iter            = optres.iter;
        end
    end
end


%%%%% Calculate AIC and BIC
d = length(opt_idx);
if ~isempty(c.y)
    ndp = sum(~isnan(c.y(:,1)));
else
    ndp = sum(~isnan(c.u(:,1)));
end
c.optim.AIC  = 2*c.optim.negLl +2*d;
c.optim.BIC  = 2*c.optim.negLl +d*log(ndp);


function optres = optimrun(nlj, init, opt_idx, opt_algo, c_opt)
% Does one run of the optimization algorithm and returns results

% The objective function is now the negative log joint restricted
% with respect to the parameters that are not optimized
obj_fun = @(p_opt) restrictfun(nlj, init, opt_idx, p_opt);

% Optimize
disp(' ')
disp('Optimizing...')
optres = opt_algo(obj_fun, init(opt_idx)', c_opt);

% Record initialization point
optres.init = init;

% Replace optimized values in init with arg min values
final = init;
final(opt_idx) = optres.argMin';
optres.final = final;

% Get the negative log-joint and negative log-likelihood
[negLj, negLl, dummy3, dummy4, trialLogLlsplit] = nlj(final);

% Calculate the covariance matrix Sigma and the log-model evidence (as approximated
% by the negative variational free energy under the Laplace assumption).
disp(' ')
disp('Calculating the log-model evidence (LME)...')
d     = length(opt_idx);

% Numerical computation of the Hessian of the negative log-joint at the MAP estimate
options.init_h    = 1;
options.min_steps = 10;
H = riddershessian(obj_fun, optres.argMin, options);

% Use the Hessian from the optimization, if available,
% if the numerical Hessian is not positive definite
if any(isinf(H(:))) || any(isnan(H(:))) || any(eig(H)<=0)
    if isfield(optres, 'T')
        % Hessian of the negative log-joint at the MAP estimate
        % (avoid asymmetry caused by rounding errors)
        H = inv(optres.T);
        % Parameter covariance
        Sigma = optres.T;
        % Ensure H and Sigma are positive semi-definite
        H = nearest_psd(H);
        Sigma = nearest_psd(Sigma);
        % Parameter correlation
        Corr = tapas_Cov2Corr(Sigma);
        % Log-model evidence ~ negative variational free energy
        LME = -optres.valMin + 1/2*log(1/det(H)) + d/2*log(2*pi);
        % decomposed LME
        decompLME.logjoint = -optres.valMin;
        decompLME.postpredcorr = 1/2*log(1/det(H));
        decompLME.freepars = d/2*log(2*pi);
    else
        disp('Warning: Cannot calculate Sigma and LME because the Hessian is not positive definite.')
    end
else
    % Calculate parameter covariance
    Sigma = inv(H);
    % Ensure H and Sigma are positive semi-definite
    H = nearest_psd(H);
    Sigma = nearest_psd(Sigma);
    % Parameter correlation
    Corr = tapas_Cov2Corr(Sigma);
    % Log-model evidence ~ negative variational free energy
    LME = -optres.valMin + 1/2*log(1/det(H)) + d/2*log(2*pi);
    % decomposed LME
    decompLME.logjoint = -optres.valMin;
    decompLME.postpredcorr = 1/2*log(1/det(H));
    decompLME.freepars = d/2*log(2*pi);
end

% Record results
optres.H = H;
optres.Sigma = Sigma;
optres.Corr = Corr;
optres.trialLogLlsplit = trialLogLlsplit;
optres.negLl = negLl;
optres.negLj = negLj;
optres.LME = LME;
optres.decompLME = decompLME;

% Calculate accuracy and complexity (LME = accu - comp)
optres.accu = -negLl;
optres.comp = optres.accu -LME;

end % function optimrun

function val = restrictfun(f, arg, free_idx, free_arg)
% This is a helper function for the construction of file handles to
% restricted functions.
% It returns the value of a function restricted to subset of the
% arguments of the input function handle. The input handle takes
% *one* vector as its argument.
% INPUT:
%   f            The input function handle
%   arg          The argument vector for the input function containing the
%                fixed values of the restricted arguments (plus dummy values
%                for the free arguments)
%   free_idx     The index numbers of the arguments that are not restricted
%   free_arg     The values of the free arguments

% Replace the dummy arguments in arg
arg(free_idx) = free_arg;

% Evaluate
val = f(arg);

end % function val

   