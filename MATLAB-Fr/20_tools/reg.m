function results = reg(X,y,cst,drop,show)
%
% Author: Stephane Surprenant, UQAM
% Creation: 03/08/2019
%
% Description: This function runs a simple OLS regression of y on X and
% returns a structure containing results. The function drops all rows with
% missing values when drop = 1.
%
% INPUTS
% X : an N x K matrix of regressors
% y : an N x 1 matrix containing the dependent variable
% cst : adds a constant if equal to 1
% drop: drops rows with missing values if equal to 1
% show: shows output if equal to 1
%
% OUTPUTS
% results: structure with entries table, reg_wald, reg_stat and desc
% containing output. All tests are asymptotic and assumes homoskedastic
% errors. Intercept comes on the first row of table.
% ======================================================================= %

% Drop missing values, if any:
data  = [y,X];
if drop == 1
    data(any(isnan(data), 2),:) = [];
    X = data(:,2:end);
    y = data(:,1);
end

% Get dimensions
[N,K] = size(X);

% Add constant
if cst == 1
   X = [ones(N,1), X]; 
   K = K + 1;
end

% OLS point estimate
bhat = X\y; % Since X is not square, it uses a generalized inverse which
% corresponds to the OLS formula bhat = (X'X)^-1 X'y.
ehat = y - X*bhat; % OLS residuals

% Homoskedastic variance estimator
sigma2 = ehat'*ehat/(N-K);
vhat   = sigma2*inv(X'*X);

% t statistic for individual coefficients
t =  bhat./sqrt(diag(vhat));
% NB: H0: B(i) == 0 vs H1: B(i) =/= 0

% p-values for individual coefficients
p = 2*(1-normcdf(abs(t)));                     % Asymptotic test --> N(0,1)

% Joint wald test on all coefficients, but the constant
% H0: B(i) = 0 for all i vs H1: B(i) =/= 0 for one i, i in 2,...,K
% We write it in the form: RB - q = 0 with J restrictions and q = 0;
J = K - 1;
R = [zeros(J,1), eye(K-1)];
W = ((R*bhat)'/(R*vhat*R'))*R*bhat; %NB: sigma2 is in vhat
p_reg = 1- chi2cdf(W,J);                      % Asymptotic test --> Chi2(J)

% R2 and adjusted R2
My   = y - ones(N,1)*mean(y);
R2   = 1-(ehat'*ehat)/(My'*My);
R2a  = 1-((N-1)/(N-K))*(ehat'*ehat)/(My'*My);

% Gather results
results.table    = [bhat, sqrt(diag(vhat)), t, p];
results.reg_wald = [W, p_reg];
results.reg_stat = [R2, R2a, N];
results.desc = ['The .table contains point estimates, their standard', ...
                ' errors (homos.), t-statistics and p-values.', ...
                ' P-values are asymptotic and the intercept is on the' ...
                ' first row', ...
                ' The .reg_walk contains the wald statistic and its', ...
                ' p-value for a joint test on the nullity of all', ...
                ' coefficients but the intercept. The .reg_stat', ...
                ' contains R2, R2 adjusted and the number of', ...
                ' observations used, excluding NaN.'];

% Display results neatly, if required
if show == 1
    % Create cell array of names for rows
    rownames    = cell(1,K);
    rownames{1} = 'Intercept';
    for ii = 2:K
       rownames{ii} = ['Var_', num2str(ii)];
    end
    % Gather results in two tables
    output1  = array2table(results.table, ...
                           'VariableNames', {'Coefficients', ...
                                             'Standard_errors', ...
                                             't_statistics', ...
                                             'p_values'}, ...
                           'Rownames', rownames);
    output2 = array2table([results.reg_wald, results.reg_stat], ...
                           'VariableNames', {['Regression_wald', ...
                                              '_statistic'], ...
                                             'p_value', ...
                                             'R2', 'R2a', 'Nobs'});
   % Neatly display results for user
   disp(repmat('=', 1, 80));
   disp(output1);
   disp(repmat('=', 1, 80));
   disp(output2);
   disp(repmat('=', 1, 80));
end

end