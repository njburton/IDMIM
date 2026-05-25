function ll = ll_vkf_binary(params, y)
    % Log-likelihood of VKF model for binary observations
    %
    % Inputs:
    %   params - [log(lambda), log(v0), log(omega)]
    %   y      - Binary observations (nTrials x 1)
    %
    % Output:
    %   ll     - Negative log-likelihood (for minimization)
    
    % Convert from log-space
    lambda = exp(params(1));
    v0 = exp(params(2));
    omega = exp(params(3));
    
    % Run VKF
    [dv, lr, vol, um] = vkf_bin(y, lambda, v0, omega);
    
    % Compute log-likelihood (Bernoulli)
    % Clip probabilities to avoid log(0)
    um = max(min(um, 1 - 1e-6), 1e-6);
    
    ll = sum(y .* log(um) + (1 - y) .* log(1 - um));
    
    % Return negative LL for minimization
    ll = -ll;
end