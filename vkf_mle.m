function [params_fit, ll_fit, info] = vkf_optim(y, varargin)
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
    addParameter(p, 'nRestarts', 3, @isnumeric);
    addParameter(p, 'confidence', true, @islogical);
    addParameter(p, 'hessian', true, @islogical);
    addParameter(p, 'lb', [log(0.01), log(0.01), log(0.01)]);
    addParameter(p, 'ub', [log(0.99), log(5.0), log(2.0)]);
    
    parse(p, varargin{:});
    opts = p.Results;
    
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
        x0_log = [log(opts.init.lambda), log(opts.init.v0), log(opts.init.omega)];
    else
        x0_log = log(opts.init(:));
    end
    
    % Compute initial log-likelihood
    ll_init = compute_ll_vkf(y, x0_log);
    
    if opts.verbose
        fprintf('\nInitial parameters (log-space):\n');
        fprintf('  lambda: %.4f (exp: %.4f)\n', x0_log(1), exp(x0_log(1)));
        fprintf('  v0:     %.4f (exp: %.4f)\n', x0_log(2), exp(x0_log(2)));
        fprintf('  omega:  %.4f (exp: %.4f)\n', x0_log(3), exp(x0_log(3)));
        fprintf('Initial log-likelihood: %.4f\n\n', ll_init);
    end
    
    %% Fit with optional multiple restarts
    best_ll = -Inf;
    best_x = x0_log;
    all_results = {};
    
    for restart = 1:opts.nRestarts
        if opts.nRestarts > 1 && opts.verbose
            fprintf('--- Restart %d of %d ---\n', restart, opts.nRestarts);
        end
        
        % Random initial guess for restarts
        if restart > 1
            x0_log = opts.lb + (opts.ub - opts.lb) .* rand(1, 3);
        end
        
        % Run optimization
        [x_fit, ll, exitflag, output, grad, hess] = optimize_vkf(...
            y, x0_log, opts.method, opts.lb, opts.ub, opts.verbose);
        
        all_results{restart} = struct('x', x_fit, 'll', ll, 'exitflag', exitflag, ...
            'output', output, 'grad', grad, 'hess', hess);
        
        if ll > best_ll
            best_ll = ll;
            best_x = x_fit;
        end
    end
    
    % Use best result
    x_fit = best_x;
    ll_fit = best_ll;
    
    %% Convert from log-space
    params_fit = struct(...
        'lambda', exp(x_fit(1)), ...
        'v0', exp(x_fit(2)), ...
        'omega', exp(x_fit(3)));
    
    %% Compute diagnostics
    [~, ~, ~, ~, grad_fit] = optimize_vkf(y, x_fit, opts.method, opts.lb, opts.ub, false);
    
    info = struct(...
        'exitflag', all_results{end}.exitflag, ...
        'iterations', all_results{end}.output.iterations, ...
        'gradient', grad_fit, ...
        'initial_ll', ll_init, ...
        'll_improvement', ll_fit - ll_init);
    
    %% Compute Hessian and confidence intervals
    if opts.hessian
        hess = compute_hessian_numerical(y, x_fit);
        info.hessian = hess;
        
        % Standard errors from inverse Hessian
        try
            inv_hess = inv(hess);
            se = sqrt(diag(inv_hess));
            info.se = se;
            
            % 95% Confidence intervals (on original scale using delta method)
            z_crit = 1.96;
            
            % For log-normal parameters: CI = exp(log(param) ± z * SE / param)
            params_orig = exp(x_fit);
            info.ci_lower = params_orig .* exp(-z_crit * se ./ params_orig);
            info.ci_upper = params_orig .* exp(z_crit * se ./ params_orig);
            
            % Condition number
            info.condition_number = cond(hess);
        catch
            if opts.verbose
                warning('Could not invert Hessian - singular or ill-conditioned');
            end
            info.se = NaN(3, 1);
            info.ci_lower = NaN(3, 1);
            info.ci_upper = NaN(3, 1);
            info.condition_number = NaN;
        end
    end
    
    %% Display results
    if opts.verbose
        fprintf('\n=== FITTED PARAMETERS ===\n');
        fprintf('Lambda (volatility):     %.4f\n', params_fit.lambda);
        fprintf('v0 (initial volatility): %.4f\n', params_fit.v0);
        fprintf('Omega (obs. noise):      %.4f\n', params_fit.omega);
        fprintf('\nFinal log-likelihood: %.4f\n', ll_fit);
        fprintf('Improvement over initial: %.4f\n\n', info.ll_improvement);
        
        if opts.hessian && ~isnan(info.se(1))
            fprintf('=== STANDARD ERRORS & 95%% CI ===\n');
            fprintf('Lambda:  SE=%.4f, CI=[%.4f, %.4f]\n', ...
                info.se(1), info.ci_lower(1), info.ci_upper(1));
            fprintf('v0:      SE=%.4f, CI=[%.4f, %.4f]\n', ...
                info.se(2), info.ci_lower(2), info.ci_upper(2));
            fprintf('Omega:   SE=%.4f, CI=[%.4f, %.4f]\n', ...
                info.se(3), info.ci_lower(3), info.ci_upper(3));
            fprintf('Hessian condition number: %.2e\n\n', info.condition_number);
        end
        
        % Model fit quality
        [~, ~, ~, p_pred] = vkf_bin(y, params_fit.lambda, params_fit.v0, params_fit.omega);
        % Compute information criteria
        bic = -2 * ll_fit + n_params * log(n_trials);
        aic = -2 * ll_fit + 2 * n_params;

        % Approximate log model evidence using Laplace approximation
        % LME ≈ log(likelihood) - 0.5 * n_params * log(n_trials)
        lme = loglik - 0.5 * n_params * log(n_trials);
        accuracy = mean((p_pred > 0.5) == y);
        fprintf('Model prediction accuracy: %.2f%%\n', 100*accuracy);
    end
    
end

%% ========== OPTIMIZATION ROUTINES ==========

function [x_fit, ll_fit, exitflag, output, grad, hess] = optimize_vkf(...
    y, x0, method, lb, ub, verbose)
    % Run optimization using specified method
    
    switch lower(method)
        case 'fmincon'
            obj_fcn = @(x) compute_ll_vkf(y, x);
            
            options = optimoptions('fmincon', ...
                'Algorithm', 'interior-point', ...
                'Display', iif(verbose, 'iter', 'off'), ...
                'MaxIterations', 1000, ...
                'TolFun', 1e-8, ...
                'TolX', 1e-8, ...
                'SpecifyObjectiveGradient', false);
            
            [x_fit, ll_fit, exitflag, output] = fmincon(...
                obj_fcn, x0, [], [], [], [], lb, ub, [], options);
            
        case 'bfgs'
            obj_fcn = @(x) compute_ll_vkf(y, x);
            
            options = optimoptions('fminunc', ...
                'Algorithm', 'quasi-newton', ...
                'Display', iif(verbose, 'iter', 'off'), ...
                'MaxIterations', 1000, ...
                'TolFun', 1e-8, ...
                'TolX', 1e-8);
            
            [x_fit, ll_fit, exitflag, output] = fminunc(...
                obj_fcn, x0, options);
            
        case 'ga'
            obj_fcn = @(x) compute_ll_vkf(y, x);
            
            options = optimoptions('ga', ...
                'Display', iif(verbose, 'iter', 'off'), ...
                'MaxGenerations', 200, ...
                'PopulationSize', 50);
            
            [x_fit, ll_fit, exitflag, output] = ga(...
                obj_fcn, 3, [], [], [], [], lb, ub, [], options);
            
        case 'pso'
            obj_fcn = @(x) compute_ll_vkf(y, x);
            
            options = optimoptions('particleswarm', ...
                'Display', iif(verbose, 'iter', 'off'), ...
                'MaxIterations', 500, ...
                'SwarmSize', 50);
            
            [x_fit, ll_fit, exitflag] = particleswarm(...
                obj_fcn, 3, lb, ub, options);
            
            output = struct('iterations', [], 'funcCount', []);
            
        otherwise
            error('Unknown optimization method: %s', method);
    end
    
    % Compute gradient and Hessian at solution
    [~, grad] = compute_ll_vkf(y, x_fit);
    hess = compute_hessian_numerical(y, x_fit);
end

%% ========== LOG-LIKELIHOOD FUNCTIONS ==========

function [ll, grad] = compute_ll_vkf(y, log_params)
    % Compute negative log-likelihood for VKF
    %
    % Returns negative LL for minimization
    
    % Convert from log-space
    lambda = exp(log_params(1));
    v0 = exp(log_params(2));
    omega = exp(log_params(3));
    
    % Bounds check
    if lambda < 0.01 || lambda > 0.99 || v0 < 0.01 || v0 > 5 || omega < 0.01 || omega > 2
        ll = 1e10;
        grad = NaN(3, 1);
        return;
    end
    
    % Run VKF
    [~, ~, ~, p_pred] = vkf_bin(y, lambda, v0, omega);
    
    % Ensure probabilities are in valid range
    p_pred = max(min(p_pred, 1 - 1e-10), 1e-10);
    
    % Bernoulli log-likelihood
    ll_bernoulli = sum(y .* log(p_pred) + (1 - y) .* log(1 - p_pred));
    
    % Return negative LL (for minimization) and gradient if requested
    ll = -ll_bernoulli;
    
    if nargout > 1
        % Numerical gradient
        h = 1e-6;
        grad = zeros(3, 1);
        for i = 1:3
            x_plus = log_params;
            x_plus(i) = x_plus(i) + h;
            ll_plus = compute_ll_vkf(y, x_plus);
            
            x_minus = log_params;
            x_minus(i) = x_minus(i) - h;
            ll_minus = compute_ll_vkf(y, x_minus);
            
            grad(i) = (ll_plus - ll_minus) / (2 * h);
        end
    end
end

%% ========== HESSIAN & INFORMATION MATRIX ==========

function hess = compute_hessian_numerical(y, x, h)
    % Compute numerical Hessian matrix
    
    if nargin < 3
        h = 1e-5;
    end
    
    hess = zeros(3, 3);
    
    for i = 1:3
        for j = 1:3
            % f(x_i + h, x_j + h)
            x_pp = x;
            x_pp(i) = x_pp(i) + h;
            x_pp(j) = x_pp(j) + h;
            ll_pp = compute_ll_vkf(y, x_pp);
            
            % f(x_i + h, x_j - h)
            x_pm = x;
            x_pm(i) = x_pm(i) + h;
            x_pm(j) = x_pm(j) - h;
            ll_pm = compute_ll_vkf(y, x_pm);
            
            % f(x_i - h, x_j + h)
            x_mp = x;
            x_mp(i) = x_mp(i) - h;
            x_mp(j) = x_mp(j) + h;
            ll_mp = compute_ll_vkf(y, x_mp);
            
            % f(x_i - h, x_j - h)
            x_mm = x;
            x_mm(i) = x_mm(i) - h;
            x_mm(j) = x_mm(j) - h;
            ll_mm = compute_ll_vkf(y, x_mm);
            
            % Central difference approximation
            hess(i, j) = (ll_pp - ll_pm - ll_mp + ll_mm) / (4 * h^2);
        end
    end
end

%% ========== UTILITY FUNCTIONS ==========

function result = iif(condition, true_val, false_val)
    % Inline if-then-else
    if condition
        result = true_val;
    else
        result = false_val;
    end
end