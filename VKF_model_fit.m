function est = VKF_model_fit(u,y,nTrials)

nt = length(y);

% Check binary validity
assert(all(ismember(y, [0 1])), 'Outcome y must be binary (0 or 1)');
assert(length(u) == nTrials, 'Input and output must have same number of trials');

%% --- Define VKF parameters manually ---
lambda = 0.4;   % Volatility learning rate (between 0 and 1)
v0     = 0.1;   % Initial volatility
omega  = 0.1;   % Observation noise variance

%% --- Run VKF using your provided function ---
[dv, lr, vol, um] = vkf_bin(y, lambda, v0, omega);

% Derived metrics
est.belief_median   = dv;
est.belief_variance = lr.^2;
est.vol_median      = median(vol);
est.lr_median       = median(lr);
est.predicted_prob  = um;

%% --- Display summary statistics ---
fprintf('--- VKF Summary ---\n');
fprintf('Trials               : %d\n', nt);
fprintf('Mean Belief          : %.4f\n', median(belief_median));
fprintf('Mean Variance        : %.4f\n', median(belief_variance));
fprintf('Mean Volatility      : %.4f\n', median(vol));
fprintf('Mean Learning Rate   : %.4f\n', median(lr));
fprintf('Prediction Accuracy  : %.2f%%\n', 100 * median((predicted_prob > 0.5) == y));

%% --- Plot: 3 informative VKF panels ---
t = 1:nt;
figure('Name', 'VKF Real Data Output', 'Position', [100 100 1000 900]);

% Panel 1: Belief and uncertainty
subplot(3,1,1);
yyaxis left;
plot(t, belief_median, 'b-', 'LineWidth', 2);
ylabel('Belief (mean)');
yyaxis right;
plot(t, belief_variance, 'r--', 'LineWidth', 2);
ylabel('Uncertainty (variance)');
xlabel('Trial');
title('Belief and Uncertainty');
grid on;
legend('Belief', 'Variance');

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
grid on;
legend('Volatility', 'Learning Rate');

% Panel 3: Predicted vs observed outcomes
subplot(3,1,3);
plot(t, y, 'ko', 'MarkerSize', 4); hold on;
plot(t, predicted_prob, 'b-', 'LineWidth', 2);
xlabel('Trial'); ylabel('Binary / Probability');
title('Observed Outcomes vs. Predicted Probabilities');
legend('Observed', 'Predicted P(y=1)');
grid on;


saveas(gcf, 'vkf_spirl_plot.png');




%% === FIXED: Run Binary Kalman Filter (KF) ===


%% === Load your binary data ===
y = SPIRL(1).y(:,1);        % 301x1 binary outcome
nt = length(y);
assert(all(ismember(y, [0 1])));

%% === EKF Parameters (match VBA priors) ===
mu0     = 0;        % Initial mean
sigma0  = 0.1;      % Initial variance
alpha   = 1/0.1;    % Process precision (1 / Q)
sigma_obs = 1/0.1;  % Observation precision (1 / R)

%% === Preallocate outputs ===
muX     = zeros(nt,1);       % Posterior mean
SigmaX  = zeros(nt,1);       % Posterior variance
um      = zeros(nt,1);       % Predicted P(y=1)
lr      = zeros(nt,1);       % Kalman gain
jac     = zeros(nt,1);       % Jacobian (sigmoid derivative)

% Initial state
m = mu0;
w = sigma0;

%% === EKF Update Loop ===
for t = 1:nt
    % Predict
    mu_pred = m;
    sig_pred = w + 1/alpha;

    % Nonlinear observation model: g(x) = sigmoid(x)
    gx = 1 / (1 + exp(-mu_pred));
    dgdx = gx * (1 - gx);       % Jacobian of sigmoid

    % Observation prediction
    p = gx;
    e = y(t) - p;

    % Innovation variance
    S = dgdx^2 * sig_pred + 1/sigma_obs;

    % Kalman gain
    K = (sig_pred * dgdx) / S;

    % Update state
    m = mu_pred + K * e;
    w = (1 - K * dgdx) * sig_pred;

    % Store results
    muX(t)    = m;
    SigmaX(t) = w;
    um(t)     = gx;
    lr(t)     = abs(K);       % learning rate
    jac(t)    = dgdx;
end

%% === Plot ===
t = 1:nt;
figure('Name', 'EKF (like VBA)', 'Position', [100 100 1000 800]);

% Panel 1: Belief and Uncertainty
subplot(3,1,1);
yyaxis left;
plot(t, muX, 'b-', 'LineWidth', 2);
ylabel('Belief (mu)');
yyaxis right;
plot(t, SigmaX, 'r--', 'LineWidth', 2);
ylabel('Uncertainty (variance)');
xlabel('Trial');
title('EKF: Belief and Uncertainty');
legend('mu', 'Sigma');
grid on;

% Panel 2: Learning Rate and Jacobian
subplot(3,1,2);
plot(t, lr, 'k-', 'LineWidth', 2); hold on;
% plot(t, jac, 'm--', 'LineWidth', 2);
xlabel('Trial');
ylabel('Learning rate');
title('Learning Rate');
% title('Learning Rate and Jacobian (sigmoid slope)');
% legend('Learning Rate', 'Jacobian');
grid on;

% Panel 3: Predicted vs Observed
subplot(3,1,3);
plot(t, y, 'ko', 'MarkerSize', 4, 'DisplayName', 'Observed'); hold on;
plot(t, um, 'b-', 'LineWidth', 2, 'DisplayName', 'Predicted P(y=1)');
xlabel('Trial'); ylabel('Probability / Binary');
title('EKF: Observed vs Predicted Outcomes');
legend('Location', 'best');
grid on;

% Save
saveas(gcf, 'ekf_spirl_matched_vba.png');
fprintf('\n✅ EKF (VBA-like) plot saved: ekf_spirl_matched_vba.png\n');
