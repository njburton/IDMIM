% run_vkf_spirl_realdata.m
% Real SPIRL binary data → VKF → Parameter fitting → Analysis → Plot


load('/Volumes/Samsung_T5/SNG/projects/IDMIM/results/2023_UCMS/simulations/NJB_HGF_sim.mat');
%% --- Load SPIRL binary input/output ---
y = agent(1).task(1).data.y;
u = agent(1).task(1).data.u;
nt = length(y);

assert(all(ismember(y, [0 1])), 'Outcome y must be binary (0 or 1)');
assert(length(u) == nt, 'Input and output must have same length');

%% --- Estimate VKF parameters using fmincon ---
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

% Transform to true VKF values
lambda = lux(opt_params(1));
v0     = 10 * lux(opt_params(2));
omega  = exp(opt_params(3));

fprintf('\nEstimated VKF Parameters:\n');
fprintf('  lambda = %.4f\n', lambda);
fprintf('  v0     = %.4f\n', v0);
fprintf('  omega  = %.4f\n', omega);

%% --- Run VKF using estimated parameters ---
[dv, lr, vol, um] = vkf_bin(y, lambda, v0, omega);

belief_mean     = dv;
belief_variance = lr.^2;
predicted_prob  = um;

%% --- Summary ---
fprintf('\n--- VKF Summary ---\n');
fprintf('Trials               : %d\n', nt);
fprintf('Mean Belief          : %.4f\n', mean(belief_mean));
fprintf('Mean Variance        : %.4f\n', mean(belief_variance));
fprintf('Mean Volatility      : %.4f\n', mean(vol));
fprintf('Mean Learning Rate   : %.4f\n', mean(lr));
fprintf('Prediction Accuracy  : %.2f%%\n', 100 * mean((predicted_prob > 0.5) == y));

%% --- Plot results ---
t = 1:nt;
figure('Name', 'VKF Real Data Output (Estimated)', 'Position', [100 100 1000 900]);

% Panel 1: Belief and uncertainty
subplot(3,1,1);
yyaxis left;
plot(t, belief_mean, 'b-', 'LineWidth', 2);
ylabel('Belief (mean)');
yyaxis right;
plot(t, belief_variance, 'r--', 'LineWidth', 2);
ylabel('Uncertainty (variance)');
xlabel('Trial');
title('Belief and Uncertainty');
legend('Belief', 'Variance');
grid on;

% Panel 2: Volatility and learning rate
subplot(3,1,2);
yyaxis left;
plot(t, vol, 'm-', 'LineWidth', 2);
ylabel('Volatility');
yyaxis right;
plot(t, lr, 'k--', 'LineWidth', 2);
ylabel('Learning Rate');
xlabel('Trial');
title('Volatility and Learning Rate');
legend('Volatility', 'Learning Rate');
grid on;

% Panel 3: Observed vs Predicted
subplot(3,1,3);
plot(t, y, 'ko', 'MarkerSize', 4); hold on;
plot(t, predicted_prob, 'b-', 'LineWidth', 2);
xlabel('Trial'); ylabel('Binary / Probability');
title('Observed Outcomes vs. Predicted Probabilities');
legend('Observed', 'Predicted P(y=1)');
grid on;

saveas(gcf, 'vkf_from_spirl_estimated.png');
fprintf('✅ Figure saved: vkf_from_spirl_estimated.png\n');


