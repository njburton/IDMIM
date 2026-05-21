function [loglik, beta] = fit_responses(X,Y,params)
beta     = exp(params(1));

sumX=sum(X,2);
adaptX = X./sumX;

z        = adaptX*beta;
%f        = (1./(1+exp(-z)));
ev  = exp(z); % expected value
sev = sum(ev,2);
f   = ev./sev;


p = [];
for kk=1:length(z)
    
    if Y(kk)==1
        p_temp        = f(kk,1);
    end
    if Y(kk)==2
        p_temp       = f(kk,2);
    end
    if Y(kk)==3
        p_temp       = f(kk,3);
    end
    
    p = [p;p_temp];
    
end


loglik   = sum(sum(log(p+eps)));
end