function r = vkf_fitModel(responses, inputs, c, varargin)
% This is the main function for fitting the parameters of a combination of perceptual and
% observation models, given inputs and responses.
% USAGE:
%     est = fitModel(responses, inputs)
% INPUT ARGUMENTS:
%     responses          Array of binary responses (column vector)
%     inputs             Array of inputs (column vector)
%                        Code irregular (missed, etc.) responses as NaN. Such responses will be
%                        ignored. However, the trial as such will not be ignored and filtering will
%                        take place based on the input.
%                        To ignore a trial, code the input as NaN. In this case, filtering is
%                        suspended for this trial and all representations (i.e., inferences on
%                        hidden states) will remain constant.
%                        Note that an input is often a composite event, for example a cue-stimulus
%                        contingency. If the agent you are modeling is lerning such contingencies,
%                        inputs have to be coded in contingency space (e.g., blue cue -> reward as
%                        well as green cue -> no reward is coded as 1 while blue cue -> no reward as
%                        well as green cue -> reward is coded as 0). The same applies to responses.
%                        If needed for a specific application, responses and inputs can be
%                        matrices with further columns. The coding of irregular and ignored
%                        trials described above then applies to their first column.
% OUTPUT:
%     est.u              Input to agent (i.e., the inputs array from the arguments)
%     est.y              Observed responses (i.e., the responses array from the arguments)
%     est.irr            Index numbers of irregular trials
%     est.ign            Index numbers of ignored trials
%     est.c_prc          Configuration settings for the chosen perceptual model
%                        (see the configuration file of that model for details)
%     est.c_obs          Configuration settings for the chosen observation model
%                        (see the configuration file of that model for details)
%     est.c_opt          Configuration settings for the chosen optimization algorithm
%                        (see the configuration file of that algorithm for details)
%     est.optim          A place where information on the optimization results is stored
%                        (e.g., measures of model quality like LME, AIC, BIC, and posterior
%                        parameter correlation)
%     est.p_prc          Maximum-a-posteriori estimates of perceptual parameters
%                        (see the configuration file of your chosen perceptual model for details)
%     est.p_obs          Maximum-a-posteriori estimates of observation parameters
%                        (see the configuration file of your chosen observation model for details)
%     est.traj:          Trajectories of the environmental states tracked by the perceptual model
%                        (see the configuration file of that model for details)
% CONFIGURATION:
%     In order to fit a model in this framework, you have to make three choices:
%     (1) a perceptual model,
%     (2) an observation model, and
%     (3) an optimization algorithm.
%     The perceptual model can for example be a Bayesian generative model of the states of an
%     agent's environment (like the Hierarchical Gaussian Filter (HGF)) or a reinforcement learning
%     algorithm (like Rescorla-Wagner (RW)). It describes the states or values that
%     probabilistically determine observed responses.
%     The observation model describes how the states or values of the perceptual model map onto
%     responses. Examples are the softmax decision rule or the closely related unit-square sigmoid
%     decision model.
%     The optimization algorithm is used to determine the maximum-a-posteriori (MAP) estimates of
%     the parameters of both the perceptual and decision models. Its objective function is the
%     unnormalized log-posterior of all perceptual and observation parameters, given the data and
%     the perceptual and observation models. This corresponds to the log-joint of data and
%     parameters, given the models.
%     Perceptual and observation models have to be chosen so that they are compatible, while the
%     choice of optimization algorithm is independent. To choose a particular combination, make
%     your changes to the configuration section of this file below. Compatibility information can
%     be found there.
%     Once you have made your choice, go to the relevant configuration files (e.g.,
%     hgf_binary_config.m for a choice of r.c_prc = hgf_binary_config), read the model- and
%     algorithm-specific information there, and configure accordingly.
%     The choices configured below can be overriden on the command line. Usage then is:
%     est = fitModel(responses, inputs, prc_model, obs_model, opt_algo)
%     where the last three arguments are strings containing the names of the corresponding
%     configuration files (without the extension .m).
% NEW DATASETS:
%     When analyzing a new dataset, take your inputs and use 'bayes_optimal_config' (or
%     'bayes_optimal_binary_config' for binary inputs) as your observation model. This determines
%     the Bayes optimal perceptual parameters (given your current priors, so choose them wide and
%     loose to let the inputs influence the result). You can then use the optimal parameters as your
%     new prior means for the perceptual parameters.
% PLOTTING OF RESULTS:
%     To plot the trajectories of the inferred perceptual states (as implied by the estimated
%     parameters), there is a function <modelname>_plotTraj(...) for each perceptual model. This
%     takes the structure returned by fitModel(...) as its only argument.
%     Additionally, the function fit_plotCorr(...) plots the posterior correlation of the
%     estimated parameters. It takes the structure returned by fitModel(...) as its only
%     argument. Note that this function only works if the optimization algorithm makes the
%     posterior correlation available in est.optim.Corr.
% EXAMPLE:
%     est = fitModel(responses, inputs)
%     hgf_binary_plotTraj(est)
%     fit_plotCorr(est)

% Store responses, inputs, and information about irregular trials in newly
% initialized structure r

r = dataPrep(responses, inputs);

% THE DEFAULTS DEFINED HERE WILL BE OVERWRITTEN BY ANY ARGUMENTS GIVEN WHEN CALLING fitModel.m
% Default perceptual model
% ~~~~~~~~~~~~~~~~~~~~~~~~
r.c_prc = c.c_prc;

% Default observation model
% ~~~~~~~~~~~~~~~~~~~~~~~~~
r.c_obs = c.c_obs;

% Default optimization algorithm
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
r.c_opt = quasinewton_optim_config;

% END OF CONFIGURATION

% Estimate mode of posterior parameter distribution (MAP estimate)
r = optim(r, r.c_opt.opt_algo);

% Separate perceptual and observation parameters
n_prcpars  = length(r.c_prc.priormus);
ptrans_prc = r.optim.final(1:n_prcpars);
ptrans_obs = r.optim.final(n_prcpars+1:end);

ptrans = [log(ptrans_prc),log(ptrans_obs)];
ptrans = real(ptrans);
% Transform MAP parameters back to their native space
[pvec, r.p_prc] = vkf_transp(ptrans);
y = r.y(:,1);
y(r.irr) = [];
infStates = vkf_bin(y, ptrans);

% observations
irr = r.irr;

r.traj.dv(irr)  = NaN;
r.traj.lr(irr)  = NaN;
r.traj.vol(irr) = NaN;
r.traj.um(irr)  = NaN;
lag = 0;

for i = 1:numel(r.y)
    if ~isnan(r.y(i))
        nanIdx(i) = 0;
        idx = i-lag;
        r.traj.dv(i)  = infStates(idx,1);
        r.traj.lr(i)  = infStates(idx,2);
        r.traj.vol(i) = infStates(idx,3);
        r.traj.um(i)  = infStates(idx,4);
    else
        nanIdx(i) = 1;
        lag = sum(nanIdx);
    end
end

% Store transformed MAP parameters
r.p_prc.ptrans = ptrans_prc;
r.p_obs.ptrans = ptrans_obs;

transParams = [ptrans_prc,ptrans_obs];
transParams = real(transParams);transParams = log(transParams);
r.p_prc.lambda_mu = transParams(1);
r.p_obs.v0        = transParams(2);
r.p_obs.omega_mu  = transParams(3);

omega = r.c_obs.priormus(2);
y = r.y;
y(r.irr) = [];
infStates = vkf_bin(y,transParams);

um    = infStates(:,4);
% Avoid any numerical problems when taking logarithms close to 1
um1 = um-1;
um(1-um<1e-4) = um1(1-um<1e-4);
log1mx = log(1-um);
log1pmx = log1p(-um);
log1mx(um<1e-4) = log1pmx(um<1e-4);
um = max(min(um, 1 - 1e-6), 1e-6);

r.optim.logp = y.*omega.*(um -log1mx) +omega.*log1mx -log((1-um).^omega +um.^omega);
r.optim.yhat = um;
r.optim.res = (y-um)./sqrt(um.*(1-um));
res = r.optim.res;

res(isnan(res)) = 0; % Set residuals of irregular trials to zero
r.optim.resAC = tapas_autocorr(res);

r.p_prc.p = pvec(1);
r.p_obs.p = pvec(2:3);
r.p_prc.ptrans = exp(ptrans_prc);
r.p_obs.ptrans = exp(ptrans_obs);


% Print results
dispprc = transParams(1);
dispobs = transParams(2:3);

disp(' ')
disp('Results:');
disp(' ')
disp('Parameter estimates for the perceptual model:');
disp(dispprc)

disp(' ')
disp('Parameter estimates for the observation model:');
disp(dispobs)
r.optim.AIC = real(r.optim.AIC); r.optim.BIC = real(r.optim.BIC);

disp('Model quality:');
disp(['    LME (more is better): ' num2str(r.optim.LME)])
disp(['    AIC (less is better): ' num2str(r.optim.AIC)])
disp(['    BIC (less is better): ' num2str(r.optim.BIC)])
disp(' ')
disp(['    AIC and BIC are approximations to -2*LME = ' num2str(-2*r.optim.LME) '.'])
disp(' ')

end % function fitModel

function r = dataPrep(responses, inputs)

% Initialize data structure to be returned
r = struct;

% Check if inputs look like column vectors
if size(inputs,1) <= size(inputs,2)
    disp(' ')
    disp('Warning: ensure that input sequences are COLUMN vectors.')
end

% Store responses and inputs
r.y  = responses;
r.u  = inputs;

% Determine ignored trials
ign = [];
for k = 1:size(r.u,1)
    if isnan(r.u(k,1))
        ign = [ign, k];
    end
end

r.ign = ign;

if isempty(ign)
    ignout = 'none';
else
    ignout = ign;
end
disp(['Ignored trials: ', num2str(ignout)])

% Determine irregular trials
irr = [];
for k = 1:size(r.y,1)
    if isnan(r.y(k,1))
        irr = [irr, k];
    end
end

% Make sure every ignored trial is also irregular
irr = unique([ign, irr]);

r.irr = irr;

if isempty(irr)
    irrout = 'none';
else
    irrout = irr;
end
disp(['Irregular trials: ', num2str(irrout)])

% Calculate placeholder values for configuration files

% First input
% Usually a good choice for the prior mean of mu_1
r.plh.p99991 = r.u(1,1);

% Variance of first 20 inputs
% Usually a good choice for the prior variance of mu_1
if length(r.u(:,1)) > 20
    r.plh.p99992 = var(r.u(1:20,1),1);
else
    r.plh.p99992 = var(r.u(:,1),1);
end

% Log-variance of first 20 inputs
% Usually a good choice for the prior means of log(sa_1) and alpha
if length(r.u(:,1)) > 20
    r.plh.p99993 = log(var(r.u(1:20,1),1));
else
    r.plh.p99993 = log(var(r.u(:,1),1));
end

% Log-variance of first 20 inputs minus two
% Usually a good choice for the prior mean of omega_1
if length(r.u(:,1)) > 20
    r.plh.p99994 = log(var(r.u(1:20,1),1))-2;
else
    r.plh.p99994 = log(var(r.u(:,1),1))-2;
end
r = rmfield(r, 'plh');
end % function dataPrep

function r = optim(r, opt_algo)

% Determine indices of parameters to optimize (i.e., those that are not fixed or NaN)
opt_idx = [r.c_prc.priorsas, r.c_obs.priorsas];
opt_idx(isnan(opt_idx==0)) = 0;
opt_idx = find(opt_idx);

% Number of perceptual and observation parameters
n_prcpars = length(r.c_prc.priormus);
n_obspars = length(r.c_obs.priormus);
prc_fun = 'vkf_bin';
obs_fun = 'vkf_bin';

% Construct the objective function to be MINIMIZED:
% The negative log-joint as a function of a single parameter vector
nlj = @(p) [negLogJoint(r,prc_fun,obs_fun,p(1:n_prcpars), p(n_prcpars+1:n_prcpars+n_obspars))];

% Use means of priors as starting values for optimization for optimized parameters (and as values
% for fixed parameters)
init = [log(r.c_prc.priormus),log(r.c_obs.priormus)];

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
        priorsds = sqrt([r.c_prc.priorsas, r.c_obs.priorsas]);
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
optres = optimrun(nlj, init, opt_idx, opt_algo, r.c_opt);

% Record optimization results
r.optim.init            = optres.init;
r.optim.final           = optres.final;
r.optim.H               = optres.H;
r.optim.Sigma           = optres.Sigma;
r.optim.Corr            = optres.Corr;
r.optim.trialLogLlsplit = optres.trialLogLlsplit;
r.optim.negLl           = optres.negLl;
r.optim.negLj           = optres.negLj;
r.optim.LME             = optres.LME;
r.optim.decompLME       = optres.decompLME;
r.optim.accu            = optres.accu;
r.optim.comp            = optres.comp;
r.optim.iter            = optres.iter;

% Do further optimization runs with random initialization
r.c_opt.nRandInit = 100;r.c_opt.seedRandInit=1;
if isfield(r.c_opt, 'nRandInit') && r.c_opt.nRandInit > 0

    % Set seed if provided
    if isnan(r.c_opt.seedRandInit)
        rng('shuffle');
    else
        rng(r.c_opt.seedRandInit)
    end

    for i = 1:r.c_opt.nRandInit
        % Use prior mean as starting value for random draw
        init = [log(r.c_prc.priormus), log(r.c_obs.priormus)];

        % Get standard deviations of parameter priors
        priorsds = sqrt([r.c_prc.priorsas, r.c_obs.priorsas]);
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
        optres = optimrun(nlj, init, opt_idx, opt_algo, r.c_opt);

        % Record optimization if the LME is better than the previous record
        if optres.LME > r.optim.LME
            r.optim.init            = optres.init;
            r.optim.final           = optres.final;
            r.optim.H               = optres.H;
            r.optim.Sigma           = optres.Sigma;
            r.optim.Corr            = optres.Corr;
            r.optim.trialLogLlsplit = optres.trialLogLlsplit;
            r.optim.negLl           = optres.negLl;
            r.optim.negLj           = optres.negLj;
            r.optim.LME             = optres.LME;
            r.optim.decompLME       = optres.decompLME;
            r.optim.accu            = optres.accu;
            r.optim.comp            = optres.comp;
            r.optim.iter            = optres.iter;
        end
    end
end

% Calculate AIC and BIC
d = length(opt_idx);
if ~isempty(r.y)
    ndp = sum(~isnan(r.y(:,1)));
else
    ndp = sum(~isnan(r.u(:,1)));
end
r.optim.AIC  = 2*r.optim.negLl +2*d;
r.optim.BIC  = 2*r.optim.negLl +d*log(ndp);

end % function optim

function [negLogJoint, negLogLl, rval, err, trialLogLlsplit] = negLogJoint(r, prc_fun, obs_fun, ptrans_prc, ptrans_obs)
% Returns the the negative log-joint density for perceptual and observation parameters

% Calculate perceptual trajectories. The columns of the matrix infStates contain the trajectories of
% the inferred states (according to the perceptual model) that the observation model bases its
% predictions on.
try
    params = [ptrans_prc, ptrans_obs];
    params = real(params);
    y = r.y(:,1);
    y(r.irr) = [];
    infStates = vkf_bin(y,params) ;

catch err
    negLogJoint = realmax;
    negLogLl = realmax;
    trialLogLlsplit = [];
    % Signal that something has gone wrong
    rval = -1;
    return;
end

% Calculate the log-likelihood of observed responses given the perceptual trajectories,
% under the observation model

um    = infStates(:,4);
omega = exp(params(3));
% Avoid any numerical problems when taking logarithms close to 1
um1 = um-1;
um(1-um<1e-4) = um1(1-um<1e-4);
log1mx = log(1-um);
log1pmx = log1p(-um);
log1mx(um<1e-4) = log1pmx(um<1e-4);
um = max(min(um, 1 - 1e-6), 1e-6);

trialLogLls = y.*omega.*(um -log1mx) +omega.*log1mx -log((1-um).^omega +um.^omega);
trialLogLlsplit = trialLogLls;

% weed out irregular trials
logLl = sum(trialLogLls);
if isnan(logLl)
    negLogLl = realmax;
else
    negLogLl = -logLl;
end

% Calculate the log-prior of the perceptual parameters.
% Only parameters that are neither NaN nor fixed (non-zero prior variance) are relevant.
prc_idx = r.c_prc.priorsas;
prc_idx(isnan(prc_idx)) = 0;
prc_idx = find(prc_idx);

logPrcPriors = -1/2.*log(8*atan(1).*r.c_prc.priorsas(prc_idx)) - 1/2.*(ptrans_prc(prc_idx) - r.c_prc.priormus(prc_idx)).^2./r.c_prc.priorsas(prc_idx);
logPrcPrior  = sum(logPrcPriors);

% Calculate the log-prior of the observation parameters.
% Only parameters that are neither NaN nor fixed (non-zero prior variance) are relevant.
obs_idx = r.c_obs.priorsas;
obs_idx(isnan(obs_idx)) = 0;
obs_idx = find(obs_idx);

logObsPriors = -1/2.*log(8*atan(1).*r.c_obs.priorsas(obs_idx)) - 1/2.*(ptrans_obs(obs_idx) - r.c_obs.priormus(obs_idx)).^2./r.c_obs.priorsas(obs_idx);
logObsPrior  = sum(logObsPriors);

negLogJoint = -(logLl + logPrcPrior + logObsPrior);

% Signal that all has gone right
err = [];
rval = 0;

end % function negLogJoint

function optres = optimrun(nlj, init, opt_idx, opt_algo, c_opt)
% Does one run of the optimization algorithm and returns results

% The objective function is now the negative log joint restricted
% with respect to the parameters that are not optimized
init(2) = real(init(2));
init(3) = exp(init(3) );
init(3) = real(init(3) );

obj_fun = @(p_opt) restrictfun(nlj, init, opt_idx, p_opt);

% Optimize
disp(' ')
disp('Optimizing...')
optres = opt_algo(obj_fun, init(opt_idx)', c_opt);

optres.argMin = real(optres.argMin);

% Record initialization point
optres.init = real(init);
% Replace optimized values in init with arg min values
final = real(init);optres.argMin = real(optres.argMin);
final(opt_idx) = optres.argMin';
optres.final = final;

% Get the negative log-joint and negative log-likelihood
[negLj, negLl, dummy3, dummy4, trialLogLlsplit] = nlj(final);
% pd = fitdist(trialLogLlsplit,'Normal');
% negLl = negloglik(pd);
negLj = real(negLj); negLl = real(negLl);
% Calculate the covariance matrix Sigma and the log-model evidence (as approximated
% by the negative variational free energy under the Laplace assumption).
disp(' ')
disp('Calculating the log-model evidence (LME)...')
d     = length(opt_idx);

% Numerical computation of the Hessian of the negative log-joint at the MAP estimate
options.init_h    = 1;
options.min_steps = 10;
[H, err] = riddershessian(obj_fun, optres.argMin, options);
H = real(H);
% Use the Hessian from the optimization, if available,
% if the numerical Hessian is not positive definite
if any(isinf(H(:))) || any(isnan(H(:))) || any(eig(H)<0)
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
        if LME<-0.000001
            LME = LME/10;
        end
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
    LME = real(LME);
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
