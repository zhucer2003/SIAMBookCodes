function[xchain,acc_rate,log_c_chain] = RTO_MH(x0,cost_fun,p,nsamp)
% This m-file implements Randomize-then-Optimize (RTO) as a proposal within 
% the Metropolis-Hastings (MH) algorithm. Each proposal is the minimizer of 
% a nonlinear least squares function of the form ||Q'(A(x)-(b+e))||^2,
% where Q is an isomtery (typically Q from the thin QR factorization of the
% Jacobian of A evaluated at the minimizer of ||A(x)-b||^2. After a sample
% is computed, it is accepted or rejected based on the value of the log of
%   log c(x) = log(det(Q'*J(x)))+0.5*||A(x)-b||^2-0.5*||Q'*(A(x)-b)||^2.
%
% INPUTS: x0         = initial guess for Levenbur-Marquardt optimization.
%         cost_fun(x,p) = evaluates the residual and its Jacobian at x. 
%         p          = parameters needed to evaluate cost_fun.
%         nsamp      = length of MCMC chain.
%
%
% OUTPUTS: xchain    = the MCMC chain generated by RTO-MH.
%          acc_rate  = acceptance rate for the proposal.
%
Nrand       = p.Nrand;
N           = length(x0);
xchain      = zeros(N,nsamp+1);
xchain(:,1) = x0;
p.e         = zeros(Nrand,1); % set randomization to 0.   
[Qtr,QtJ,r] = feval(cost_fun,x0,p); 
log_c_chain = zeros(nsamp+1,1);
log_c_chain(1) = sum(log(diag(chol(QtJ'*QtJ))))+0.5*(norm(r)^2-norm(Qtr)^2);                                  
naccept     = 0;
if nsamp > 100, h = waitbar(0,'RTO-MH in progress'); end 
for i = 1:nsamp
    if nsamp > 100, h = waitbar(i/nsamp); end 
    % Propose a sample using RTO.
    p.e     = randn(Nrand,1); % randomize the measurements.
    [x,Qtr] = LevMar(x0,@(x)cost_fun(x,p),0.001,1e-8,100);
    nresid  = norm(Qtr)^2;
    % Evaluate log(c(xtemp)). 
    p.e         = zeros(Nrand,1); % set randomization to 0.   
    [Qtr,QtJ,r] = feval(cost_fun,x,p); 
    log_c_temp   = sum(log(diag(chol(QtJ'*QtJ))))+0.5*(norm(r)^2-norm(Qtr)^2);                                  
    % Now accept or reject the proposed sample using the MH ratio. We also 
    % check that Q'*(b+e) is in the range of Q'*A, by checking that 
    % nresid is approximately 0.
    if log_c_chain(i)-log_c_temp > log(rand) & nresid < 1e-8
        naccept          = naccept+1;
        xchain(:,i+1)    = x;
        log_c_chain(i+1) = log_c_temp;
    else
        xchain(:,i+1)    = xchain(:,i);
        log_c_chain(i+1) = log_c_chain(i);
    end
end
if nsamp > 100, close(h), end
xchain   = xchain(:,2:end);
acc_rate = naccept/nsamp;

