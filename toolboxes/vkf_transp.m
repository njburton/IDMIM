function [pvec, pstruct] = vkf_transp(ptrans)


pvec    = NaN(1,length(ptrans));
pstruct = struct;


pvec(1)        = ptrans(1);                           % mu_0
pstruct.lambda   = pvec(1);
pvec(2)       = exp(ptrans(2));                  % sa_0
pstruct.v0  = pvec(2);
pvec(3)       = ptrans(3);                     % rho
pstruct.omega   = pvec(3);

end
