function [mE, sE, CC, nans, dxstat] = VKF_comp_pf(simData, tx_sim, pf)

Ys = simData.y;
Xs = simData.x;
Zs = simData.z;
lambda = tx_sim.lambda;
v0     = tx_sim.v0;
sigma  = tx_sim.sigma;

Vs = Zs.^-1;
model = @(y)vkf_lin(y,lambda,v0,sigma);

nsim = size(Ys,2);
bad_traj = zeros(1,nsim);
ef      = nan(nsim,2);
dxs      = nan(nsim,1);
for n=1:nsim
    y = Ys(:,n);
    x = Xs(2:end,n);
    v = Vs(2:end,n);

    mpf = pf(n).m(2:end,:);
    vpf = pf(n).v(2:end,:);

    [mm,temp,vm] = model(y);
    
    [mi] = kalman(y,v,sigma);

    e1 = median(abs(mm-x));
    e2 = median(abs(mpf-x));
    ef(n,1)  = (e1/e2-1)*100;

    e1 = median(abs(mm-x));
    e2 = median(abs(mi-x));
    ef(n,2)  = (e1/e2-1)*100;

    ef(n,3)  = fisher(corr(mm,mpf));
    ef(n,4)  = fisher(corr(vm,vpf,'type','spearman'));

    dx = abs(diff(x));
    dxs(n,:) = median(dx);

    dxs(bad_traj==1,:) = nan;

    dxstat = nanmean(dxs);
    mE = nanmean(ef);
    sE = nanserr(ef);
    CC = invfisher(mE(3:4));
    mE(3:4) = [];
    sE(3:4) = [];

    nans = sum(bad_traj);

    dxstat  = round(dxstat*100)/100;
    mE = round(mE*100)/100;
    sE = round(sE*100)/100;
    CC = round(CC*100)/100;
end