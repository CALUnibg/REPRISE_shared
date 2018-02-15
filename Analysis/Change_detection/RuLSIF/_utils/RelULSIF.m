function [rPE, g_nu, g_re, theta, sigma_chosen, lambda_chosen] = RelULSIF( x_de, x_nu, x_re, x_ce, alpha, fold, sigma, lambda, autoCV)
rng default


% Relative Unconstrained least-squares importance fitting (with leave-one-out cross validation)
%
% Estimating relative ratio of probability densities
%   \frac{ p_{nu}(x) }{al*p_{nu}(x) + (1 - al)* p_{de}(x) }
% from samples
%    { xde_i | xde_i\in R^{d} }_{i=1}^{n_{de}}
% drawn independently from p_{de}(x) and samples
%    { xnu_i | xnu_i\in R^{d} }_{i=1}^{n_{nu}}
% drawn independently from p_{nu}(x).
%
% Usage:
%       [PE, wh_x_nu,wh_x_de]=RuLSIF(x_nu,x_de,x_re,sigma_list,lambda_list,b)
%
% Input:
%    x_de:         d by n_de sample matrix corresponding to `denominator' (iid from density p_de)
%    x_nu:         d by n_nu sample matrix corresponding to `numerator'   (iid from density p_nu)
%    x_re:         (OPTIONAL) d by n_re reference sample matrix
%    sigma_list:   (OPTIONAL) Gaussian width
%                  If sigma_list is a vector, one of them is selected by cross validation.
%                  If sigma_list is a scalar, this value is used without cross validation.
%                  If sigma_list is empty/undefined, Gaussian width is chosen from
%                  some default canditate list by cross validation.
%    lambda_list: (OPTIONAL) regularization parameter
%                 If lambda_list is a vector, one of them is selected by cross validation.
%                 If lambda_list is a scalar, this value is used without cross validation
%                 If lambda_list is empty, Gaussian width is chosen from
%                 some default canditate list by cross validation
%    b:           (OPTINLAL) positive integer representing the number of kernels (default: 100)
%    fold:        (OPTINLAL) positive integer representing the number of folds
%                 in cross validation / 0: leave-one-out (default: 0)
%
% Output:
%         PE:     theta-relative PEarson divergence
%    wh_x_de:     estimates of density ratio w=p_nu/(al*p_nu + (1 - al)*p_de) at x_de
%    wh_x_re:     estimates of density ratio w=p_nu/(al*p_nu + (1 - al)*p_de) at x_re (if x_re is provided)
%
% (c) Makoto Yamada & Masashi Sugiyama, Department of Compter Science, Tokyo Institute of Technology, Japan.
%     yamada@sg.cs.titech.ac.jp, sugi@cs.titech.ac.jp,     http://sugiyama-www.cs.titech.ac.jp/~sugi/software/RuLSIF/

if nargin < 6 || isempty(fold)
    fold = 5;
end
[~,n_nu] = size(x_nu);
[~,n_de] = size(x_de);

% Parameter Initialization Section
if nargin < 4 || isempty(x_ce)
    b = min(100, n_nu); % max 100 samples for computational reasons
    idx = randperm(n_nu);
    x_ce = x_nu(:, idx(1:b)); % data permutation as in "A Least-squares Approach to Direct Importance Estimation"
end

if nargin < 5
    alpha = 0.5;
end

% construct gaussian centers
[~, n_ce] = size(x_ce);
% get sigma candidates
x = [x_de, x_nu];
med = comp_med(x); % compute median distance between samples
sigma_list = med * [.6, .8, 1.0, 1.2, 1.4];
% get lambda candidates
lambda_list = 10.^[-3:1:1];

[dist2_de] = comp_dist(x_de, x_ce);
%n_de * n_ce
[dist2_nu] = comp_dist(x_nu, x_ce);
%n_nu * n_ce

if autoCV == 1
    %The Cross validation Section Begins
    score = zeros(length(sigma_list),length(lambda_list));
    
    for i = 1:length(sigma_list)
        
        k_de = kernel_gau(dist2_de, sigma_list(i));
        k_nu = kernel_gau(dist2_nu, sigma_list(i));
        
        for j = 1:length(lambda_list)
            
            cv_index_nu = randperm(n_nu);
            cv_split_nu = floor([0:n_nu-1]*fold./n_nu)+1;
            cv_index_de = randperm(n_de);
            cv_split_de = floor([0:n_de-1]*fold./n_de)+1;
            
            sum = 0;
            for k = 1:fold
                k_de_k = k_de(cv_index_de(cv_split_de~=k),:)';
                %n_ce * n_de
                k_nu_k = k_nu(cv_index_nu(cv_split_nu~=k),:)';
                %n_ce * n_nu
                
                H_k = ((1-alpha)/size(k_de_k,2)) * (k_de_k * k_de_k') + ...
                      (alpha/size(k_nu_k,2)) * (k_nu_k * k_nu_k');
                h_k = mean(k_nu_k,2);
                
                theta = (H_k + eye(n_ce)*lambda_list(j))\h_k;
                % theta = max(theta,0);
                
                k_de_test = k_de(cv_index_de(cv_split_de==k),:)';
                k_nu_test = k_nu(cv_index_nu(cv_split_nu==k),:)';
                % objective function value
                J = alpha/2 * mean((theta' * k_nu_test).^2)+ ...
                    (1-alpha)/2*mean((theta' * k_de_test).^2)- ...
                    mean(theta' * k_nu_test);
                sum = sum + J;
            end
            score(i,j) = sum/fold;
        end
    end
    
    %find the chosen sigma and lambda
    [i_min,j_min] = find(score==min(score(:)));
    sigma_chosen = sigma_list(i_min);
    lambda_chosen = lambda_list(j_min);
    
else
    sigma_chosen = sigma;
    lambda_chosen = lambda;
end

%compute the final result
k_de = kernel_gau(dist2_de', sigma_chosen);
k_nu = kernel_gau(dist2_nu', sigma_chosen);

H = ((1-alpha)/n_de)* (k_de * k_de') + (alpha/n_nu) * (k_nu * k_nu');
h = mean(k_nu, 2);

theta = (H + eye(n_ce)*lambda_chosen)\h;
% theta = max(theta,0);



g_nu = theta'*k_nu;
g_de = theta'*k_de;
g_re = [];
if ~isempty(x_re)
    dist2_re = comp_dist(x_re, x_ce);
    k_re = kernel_gau(dist2_re', sigma_chosen);
    g_re = theta' * k_re;
end

% rPE = mean(g_nu) - 1/2*(alpha*mean(g_nu.^2) + ...
%     (1-alpha)*mean(g_de.^2)) - 1/2;

rPE = 1/2 * mean(g_nu) - 1/2;
end