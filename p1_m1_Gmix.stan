data {
    int<lower=2> Ngauss;
    int<lower=1> n;
    vector[n] x;
    vector[n] y;
    matrix[2,2] M[n];
}
transformed data{
    int p = 1; // number of covariates
    real pi_conc = 1.0;
    matrix[2,2] M_inv[n];
    for(i in 1:n)
      M_inv[i] = inverse(M[i]);
}
parameters {
    vector[n] xi;
    vector[n] eta;
    real alpha;
    real beta;
    real<lower=0> Sigma;
    simplex[Ngauss] pi;
    ordered [Ngauss] mu_raw;
    vector<lower=0> [Ngauss] Tau_raw;
    real<lower=0> U_raw;
    real<lower=0> W;
}
transformed parameters {
  vector [Ngauss] Tau = Tau_raw * inv(2*W);
  real U = U_raw * inv(2*W);
  vector [Ngauss] mu = mu_raw * sqrt(U);
}

model {
    vector [Ngauss] log_sqrt_Tau = 0.5 * log(Tau);
    vector [Ngauss] log_pi = log(pi);
    target += (pi_conc - 1) * sum(log(pi));  
    target += -log(Sigma);
    for (i in 1:n) {
        real lps[Ngauss];
        for (k in 1:Ngauss) {
          lps[k] = log_pi[k] - 0.5 * square(xi[i] - mu[k]) / Tau[k] - log_sqrt_Tau[k];
        }
        target += log_sum_exp(lps);
    }
    eta ~ normal(alpha+beta*x, sqrt(Sigma));
    target += -0.5*(sum(square(mu)) - square(sum(mu))/Ngauss)/U - 0.5*log(U)*Ngauss;
    Tau ~ inv_gamma((Ngauss + p)/2.0,1/(2*W));
    U ~ inv_gamma((Ngauss + p)/2.0 ,1/(2*W));
    for (i in 1:n) {
        vector[2] xy = [x[i], y[i]]';
        vector[2] xieta = [xi[i], eta[i]]';
        xy ~ multi_normal_prec(xieta, M_inv[i]);
     }
}
generated quantities{
  vector [Ngauss] log_Tau = log(Tau);
  real log_U = log(U);
  real log_W = log(W);

  vector [Ngauss] log_Tau_raw = log(Tau_raw);
  real log_U_raw = log(U_raw);

  real mu0 = normal_rng(mean(mu),sqrt(U/Ngauss));
}
