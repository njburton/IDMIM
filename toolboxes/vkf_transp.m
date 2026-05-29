function [pvec, pstruct] = vkf_transp(ptrans)


pvec    = NaN(1,length(ptrans));
pstruct = struct;


pvec(1)        = ptrans(1);   
pstruct.lambda = pvec(1);
pvec(2)        = exp(ptrans(2));
pstruct.v0     = pvec(2);
pvec(3)        = ptrans(3); 
pstruct.omega  = pvec(3);

end
