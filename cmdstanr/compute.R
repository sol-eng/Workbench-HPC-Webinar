# prerequisites
# install cmdstan 
cmdstanr::install_cmdstan()

# Get STAN model
write(RCurl::getURI("https://raw.githubusercontent.com/stan-dev/cmdstanr/master/vignettes/articles-online-only/opencl-files/bernoulli_logit_glm.stan"),"model.stan")

# Generate some fake data
n <- 25000
k <- 20
X <- matrix(rnorm(n * k), ncol = k)
y <- rbinom(n, size = 1, prob = plogis(3 * X[,1] - 2 * X[,2] + 1))
mdata <- list(k = k, n = n, y = y, X = X)

# Compile and run the model on the CPU
mod_cpu <- cmdstanr::cmdstan_model("model.stan")
system.time(fit_cpu <- mod_cpu$sample(data = mdata, chains = 4, parallel_chains = 4, refresh = 0))

fx<-function(x) mod_cpu$sample(data = mdata, chains = 4, parallel_chains = 4, refresh = 0)
system.time(fit_cpu <- clustermq::Q(fx,x=1,n_jobs=1,export=list(mod_cpu=mod_cpu,mdata=mdata),template=list(cores=4,memory=1024),log_worker = TRUE,verbose=TRUE))

