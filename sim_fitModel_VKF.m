function est = sim_fitModel_VKF(u,Y,nTrials,opts,cohortNo,iTask,m_in,m_est,iSample)

nt = length(y);

% Check binary validity
assert(all(ismember(y, [0 1])), 'Outcome y must be binary (0 or 1)');
assert(length(u) == nTrials, 'Input and output must have same number of trials');

%% --- Estimate VKF parameters using fmincon ---
lambda = .1;
v0 = 1;
sigma = 1;
% simcat = 'comp_gen';
np   = 10000; % number of times particle filter is run
nsim = 1000; % number of times simulations are run
nchunk = 50;
ii = 1:nchunk;

tx_sim = struct('lambda',lambda,'v0',v0,'sigma',sigma);
rbpf_model = @(y)rbpf_vkf_lin(y,lambda,v0,sigma,np);
N = nTrials*2;
for n=1:nsim
[Y(:,n),x(:,n),z(:,n)] = gen_vkf_lin(tx_sim,N);
end

simData.y = Y;
simData.x = x;
simData.z = z;
rng(0);
randnum = randperm(nsim);

pf(1:nsim) = deal(struct('m',[],'v',[],'c',[]));

for i = ii
    nn = (i-1)*(nsim/nchunk) + (1:(nsim/nchunk));
    for j = 1:length(nn)
        n = nn(j);
        Y = simData.y(:,n);
        rng(randnum(n));
        [mpf,vpf,cpf] = rbpf_model(Y);
        pf(j) = struct('m',mpf,'v',vpf,'c',cpf);
    end
end

pf(1:nsim) = deal(struct('m',[],'v',[],'c',[]));

% [mE, sE, CC, nans, dxstat] = VKF_comp_pf(simData,tx_sim, pf)
% [mm, temp,vm] = model(Y)
% 
% choice   = Y;
% outcome  = u;
% 
% outcome(:,1:2) = 2*outcome(:,1:2) - 1;
% outcome(:,3:4) = 2*outcome(:,3:4) + 1;
% outcome(choice==2) = -outcome(choice==2);
% 
% outcome(outcome==-1) = 0;
% 
% dv  = vkf_bin(outcome,lambda,v0,omega);
% 
% Y  = choice==1;
% 
% [loglik, beta] = VKF_fit_responses(v,Y,params);
% MLE = mle(v,Y,params);

% Derived metrics
est.prc.belief_median   = dv;
est.prc.belief_variance = lr.^2;      
est.prc.vol_median      = median(vol);
est.prc.lr_median       = median(lr);
est.prc.predicted_prob  = um;
est.optim.LL            = loglik;
est.optim.beta          = beta;

%% --- Display summary statistics ---
fprintf('--- VKF Summary ---\n');
fprintf('Trials               : %d\n', nt);
fprintf('Mean Belief          : %.4f\n', median(est.belief_median));
fprintf('Mean Variance        : %.4f\n', median(est.belief_variance));
fprintf('Mean Volatility      : %.4f\n', median(vol));
fprintf('Mean Learning Rate   : %.4f\n', median(lr));
fprintf('Prediction Accuracy  : %.2f%%\n', 100 * median((est.predicted_prob > 0.5) == Y));

%% --- Plot: 3 informative VKF panels ---
t = 1:nt;
figure('Name', 'VKF Real Data Output', 'Position', [100 100 1000 900]);

% Panel 1: Belief and uncertainty
subplot(3,1,1);
yyaxis left;
plot(t, est.belief_median, 'b-', 'LineWidth', 2);
ylabel('Belief (mean)');
yyaxis right;
plot(t, est.belief_variance, 'r--', 'LineWidth', 2);
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
plot(t, Y, 'ko', 'MarkerSize', 4); hold on;
plot(t, est.predicted_prob, 'b-', 'LineWidth', 2);
xlabel('Trial'); ylabel('Binary / Probability');
title('Observed Outcomes vs. Predicted Probabilities');
legend('Observed', 'Predicted P(y=1)');
grid on;


figdir = fullfile([char(opts.paths.cohort(cohortNo).simPlots),...
                            'simAgent_', num2str(iSample),'_',opts.cohort(cohortNo).testTask(iTask).name,'_model_in_',opts.dataFiles.rawFitFile{m_in},...
                            '_model_est_',opts.dataFiles.rawFitFile{m_est}]);
save([figdir,'.fig']);
print([figdir,'.png'], '-dpng');
close all;




%% === FIXED: Run Binary Kalman Filter (KF) ===


%% === Load your binary data ===
Y = SPIRL(1).y(:,1);        % 301x1 binary outcome
nt = length(Y);
assert(all(ismember(Y, [0 1])));

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
    e = Y(t) - p;

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
plot(t, Y, 'ko', 'MarkerSize', 4, 'DisplayName', 'Observed'); hold on;
plot(t, um, 'b-', 'LineWidth', 2, 'DisplayName', 'Predicted P(y=1)');
xlabel('Trial'); ylabel('Probability / Binary');
title('EKF: Observed vs Predicted Outcomes');
legend('Location', 'best');
grid on;

est.traj.muX =     muX;
est.traj.SigmaX = SigmaX;
est.traj.um     = um;
est.traj.lr     = lr;       % learning rate
est.traj.jac    = jac;
est.optim.nll   = nll;
est.optim.opt_params = opt_params;

% Save
saveas(gcf, 'ekf_matched_vba.png');
fprintf('\n✅ EKF (VBA-like) plot saved: ekf_spirl_matched_vba.png\n');
