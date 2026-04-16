% MATLAB script to apply VBA_EKF to SPIRL binary data, compute belief,
% uncertainty, learning rate, predicted probabilities, and plot all

clear all; close all;
load('c_behav_pilot_30sub_preprocessed_IncludedInAnalysis1_logt.mat');
% --- Load your data ---
u = SPIRL(1).u; % 301x1 binary input (double)
y = SPIRL(1).y(:,1); % 301x1 binary outcome (double)



len=length(u);

% --- Verify data ---
% if length(u) ~= 301 || length(y) ~= 301
%     error('Data vectors must be 301x1');
% end
% if ~all(ismember(u, [0, 1])) || ~all(ismember(y, [0, 1]))
%     warning('Data contains non-binary values, which may affect results');
% end

% --- Define model parameters ---
n = 1; % Number of hidden states (single state)
n_t = len; % Number of time points
p = 1; % Number of observations
u_dim = 1; % Number of inputs
Q = 0.1; % Process noise variance
R = 0.1; % Observation noise variance (Gaussian approximation)
muX0 = 0; % Initial state mean
SigmaX0 = 0.1; % Initial state covariance
alpha = 1; % Process precision (1/Q)
sigma = 1; % Observation precision (1/R)

% --- Set up VBA_EKF inputs ---
dim.n = n;
dim.n_t = n_t;
dim.p = p;
dim.u = u_dim;
dim.n_theta = 0; % No evolution parameters
dim.n_phi = 0; % No observation parameters
posterior.muX0 = muX0;
posterior.SigmaX0 = SigmaX0;
posterior.muTheta = [];
posterior.muPhi = [];
posterior.a_alpha = [alpha]; % Array for consistency
posterior.b_alpha = [1]; % Array for consistency
posterior.a_sigma = [sigma]; % Add this: Array to allow indexing with 'end'
posterior.b_sigma = [1]; % Add this: Array to allow indexing with 'end'

% --- Define minimal anonymous functions for VBA_EKF ---
% Evolution: x_t+1 = 0.9*x_t + 0.1*u_t
options.f_fname = @(x, theta, u, in, dim, t) deal(0.9 * x + 0.1 * u, 0.9);
% Observation: P(y=1) = sigmoid(x)
options.g_fname = @(x, phi, u, in, dim, t) deal(1 / (1 + exp(-x)), (1 / (1 + exp(-x))) * (1 - 1 / (1 + exp(-x))));
options.f_nout = 2; % Outputs: fx, dF_dX
options.g_nout = 2; % Outputs: gx, dG_dX
options.decim = 1; % No time decimation
options.skipf = zeros(1, dim.n_t); % No skipping of evolution function
options.checkGrads = 0; % Disable gradient checking
options.isYout = zeros(dim.p, dim.n_t); % No missing observations
options.OnLine = 0; % Batch processing
options.verbose = 1; % Display progress
options.microU = 0; % No micro-time inputs
options.sources.type = 0; % Change this: Use Gaussian observation model to define sigma
options.inF = []; % No additional evolution parameters
options.inG = []; % No additional observation parameters
options.dim = dim; % Include dim in options for VBA_getSuffStat

% --- Set up priors ---
options.priors.iQx = cell(n_t, 1);
options.priors.iQy = cell(n_t, 1);
for t = 1:n_t
    options.priors.iQx{t} = 1/Q; % Inverse process noise covariance
    options.priors.iQy{t} = 1/R; % Inverse observation noise covariance
end

% --- Run VBA_EKF ---
[muX, SigmaX, suffStat] = VBA_EKF(y', u', posterior, dim, options, 1);

% --- Compute learning rate (Kalman gain) ---
kalman_gain = zeros(n, n_t);
for t = 1:n_t
    gx_t = 1 / (1 + exp(-muX(:,t))); % Inline sigmoid
    dG_dX = gx_t * (1 - gx_t); % Inline Jacobian
    kalman_gain(:,t) = sigma * SigmaX{t} * dG_dX * (1/R); % Kalman gain
end
learning_rate = abs(kalman_gain); % Magnitude of Kalman gain

% --- Debug: Check for empty or invalid arrays ---
disp('Debug: Array Sizes and Non-Zero Checks');
disp(['muX size: ', num2str(size(muX))]);
disp(['Non-zero muX elements: ', num2str(sum(muX(:) ~= 0))]);
disp(['SigmaX size: ', num2str(size(SigmaX))]);
disp(['Non-zero SigmaX elements: ', num2str(sum(cellfun(@(x) sum(x(:) ~= 0), SigmaX)))]);
disp(['gx size: ', num2str(size(suffStat.gx))]);
disp(['Non-zero gx elements: ', num2str(sum(suffStat.gx(:) ~= 0))]);
disp(['learning_rate size: ', num2str(size(learning_rate))]);
disp(['Non-zero learning_rate elements: ', num2str(sum(learning_rate(:) ~= 0))]);

% --- Plot results ---
t = 1:n_t;
figure('Name', 'EKF Results for SPIRL Binary Data', 'Position', [100, 100, 1200, 1000]);

% Plot posterior mean (belief)
subplot(4, 1, 1);
plot(t, muX, 'b-', 'LineWidth', 2);
title('Posterior Mean (Belief) of Hidden State');
xlabel('Time'); ylabel('State Value');
grid on;

% Plot uncertainty (posterior variance)
uncertainty = zeros(1, n_t);
for t_idx = 1:n_t
    uncertainty(t_idx) = SigmaX{t_idx}(1,1); % FIX: Extract scalar from 1x1 matrix
end
subplot(4, 1, 2);
plot(t, uncertainty, 'b-', 'LineWidth', 2);
title('Uncertainty (Posterior Variance) of Hidden State');
xlabel('Time'); ylabel('Variance');
grid on;

% Plot learning rate
subplot(4, 1, 3);
plot(t, learning_rate, 'k-', 'LineWidth', 2);
title('Learning Rate (Magnitude of Kalman Gain)');
xlabel('Time'); ylabel('Learning Rate');
grid on;

% Plot observations and predicted probabilities
subplot(4, 1, 4);
h1 = plot(t, y, 'ko', 'MarkerSize', 4); hold on;
h2 = plot(t, suffStat.gx, 'b-', 'LineWidth', 2);
title('Observations and Predicted Probabilities');
xlabel('Time'); ylabel('Probability / Binary');
legend([h1(1), h2], {'Observed (y)', 'Predicted P(y=1)'});
grid on;

% Save figure
saveas(gcf, 'ekf_spirl_all_plots.png');

% --- Display additional statistics ---
disp('Summary Statistics:');
disp(['Mean Squared Prediction Error (dy2): ', num2str(suffStat.dy2)]);
disp(['Mean Squared State Error (dx2): ', num2str(suffStat.dx2)]);