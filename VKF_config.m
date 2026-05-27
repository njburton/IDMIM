function c = VKF_config(cohortNo,iTask)

addpath(genpath(pwd));

% load or run options for running this function
if exist('optionsFile.mat','file')==2
    load('optionsFile.mat');
else
    optionsFile = runOptions();
end


u = optionsFile.cohort(cohortNo).testTask(iTask).inputs;

c.c_prc.lambda_mu(1) = VBA_sigmoid(mean(u(1:60)));  % Volatility learning rate (0-1, higher = faster volatility change)
c.c_prc.lambda_sa(1) = 0.3; 
c.c_prc.lambda_mu(2) = VBA_sigmoid(mean(u(61:120)));
c.c_prc.lambda_sa(2) = 0.3; 
c.c_prc.lambda_mu(3) = VBA_sigmoid(mean(u(121:180)));
c.c_prc.lambda_sa(3) = 0.3; 
c.c_obs.v0_mu = 0.5;       % Initial volatility
c.c_obs.v0_sa = 0.35;   
c.c_obs.omega_mu = 0.2;
c.c_obs.omega_sa = 0.15;

c.c_prc.priormus = [mean(c.c_prc.lambda_mu)];
c.c_prc.priorsas = [mean(c.c_prc.lambda_sa)];
c.c_obs.priormus = [c.c_obs.v0_mu, c.c_obs.omega_mu];
c.c_obs.priorsas = [c.c_obs.v0_sa, c.c_obs.omega_sa];

c.optim.optalgo = 'quasinewton_optim';
c.optim.c_opt = eval('quasinewton_optim_config');

end