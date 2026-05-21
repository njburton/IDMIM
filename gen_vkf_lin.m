function [y, x, z] = gen_vkf_lin(tx,N)

lambda = tx.lambda;
v0     = tx.v0;
sigma  = tx.sigma;
        
eta = 1-lambda;
nu  = .5/(1-eta);

x   = nan(N+1,1);    
z   = nan(N+1,1);
y   = nan(N+1,1);

x(1,:) = 0;    
z(1,:) = v0^-1;
for n=2:(N+1)    
    epsil = betarnd(eta*nu,(1-eta)*nu) + eps;
    z(n) = z(n-1)*(eta.^-1)*epsil;    
    x(n) = randnormal(x(n-1),(z(n))^-1);
    y(n) = randnormal(x(n),sigma);
end
y(1,:) = [];

y = y(1:N/2,:);
x = x(1:N/2+1,:);
z = z(1:N/2+1,:);
end

function z = randnormal(m,v)
z = m + sqrt(v).*randn(size(m));
end