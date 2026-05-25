function [y, x, v, m] = gen_vkf_binary(nTrials, lambda, v0, omega, nPhases)
% Generate binary responses using VKF generative model
%
% Inputs:
%   nTrials  - Number of trials to generate
%   lambda   - Volatility learning rate (0-1)
%   v0       - Initial volatility
%   omega    - Observation noise variance
%   u        - Input sequence (not used in this version, included for flexibility)
%
% Outputs:
%   y        - Generated binary observations (nTrials x 1)
%   x        - Hidden state beliefs (nTrials x 1)
%   v        - Volatility trajectory (nTrials x 1)
%   m        - Posterior means (nTrials x 1)

% Initialize variables
m = zeros(nTrials, 1);      % Belief (mean)
v = zeros(nTrials, 1);      % Volatility
w = zeros(nTrials, 1);      % Uncertainty (variance)
y = zeros(nTrials, 1);      % Generated observations
x = zeros(nTrials, 1);      % Hidden state trajectory

% Initial conditions
m_curr = 0;                 % Initial belief
w_curr = 1.0;               % Initial uncertainty
v_curr = v0;                % Initial volatility

% Sigmoid function
sigmoid = @(z) 1 / (1 + exp(-z));

for i = 1:nPhases
    % Generate trajectory
    if i ==1
        tStart = 1;
        tStop = 60;
    else
        tStart = tStop+1;
        tStop = tStop+nTrials/nPhases;
    end
    for t = tStart:tStop

        % Store trajectory
        m(t) = m_curr;
        v(t) = v_curr;
        w(t) = w_curr;

        % Predict probability of y=1
        p_y1 = sigmoid(m_curr);

        % Generate binary observation
        y(t) = double(rand() < p_y1);

        % Update belief (VKF update)
        % Prediction error
        prediction_error = y(t) - p_y1;

        % Kalman gain
        K = (w_curr + v_curr) / (w_curr + v_curr + omega);

        % Update state
        m_curr = m_curr + K * prediction_error;
        w_curr = (1 - K) * (w_curr + v_curr);

        % Update volatility (from VKF equations)
        delta = sqrt(w_curr + v_curr) * prediction_error;
        v_curr = v_curr + lambda(i) * (delta^2 + K * (w_curr + v_curr) - K * v_curr);

        % Ensure volatility stays positive
        v_curr = max(v_curr, 0.01);

        % Hidden state for visualization
        x(t) = m_curr;
    end
end
end