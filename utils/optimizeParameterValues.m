function [opt_params, nll] = optimizeParameterValues(y)
% Initial parameter guess and bounds
lux = @(x) 1./(1 + exp(-x));  % Sigmoid transform

% Initial parameter guess and bounds
init_params = [0; -2.2; log(0.1)];         % [lambda, v0, omega]
lb = [-5; -5; log(1e-3)];                  % Lower bounds
ub = [5; 5; log(10)];                      % Upper bounds

negloglik = @(p) vkf_likelihood(p, y);     % Objective

opts = optimoptions('fmincon', 'Display', 'iter', ...
    'Algorithm', 'interior-point', 'MaxIterations', 300, ...
    'OptimalityTolerance', 1e-6, 'StepTolerance', 1e-6);

[opt_params, nll] = fmincon(negloglik, init_params, [], [], [], [], lb, ub, [], opts);

end