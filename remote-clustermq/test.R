library(clustermq)

compute <- function(n) {
  .libPaths(libpath)
  library(palmerpenguins)
  library(dplyr)
  peng <- penguins %>% 
    filter(!is.na(species) & !is.na(sex)) %>%
    mutate(
      species = as.factor(species),
      sex = as.factor(sex)
    ) %>% 
    sample_n(333)
  glm(body_mass_g ~ species + sex, data = peng)
}

init <- function(n) {
  if (!dir.exists(libpath)) dir.create(libpath,recursive=TRUE)
  .libPaths(libpath)
  install.packages("pak", libpath, repos = sprintf(
    "https://r-lib.github.io/p/pak/stable/%s/%s/%s",
    .Platform$pkgType,
    R.Version()$os,
    R.Version()$arch
  ))
 
  options(repos=myrepos)
  pak::pkg_install(installed_pkgs,lib=libpath)
}


folder="~/.clustermq/libs"
installed_pkgs<-as.data.frame(installed.packages())[c("Package","Version","Priority")]
installed_pkgs<-installed_pkgs[is.na(installed_pkgs$Priority),]
installed_pkgs<-paste0(installed_pkgs$Package,"@",installed_pkgs$Version)

clustermq::Q(init,
              n=1,
              export=list(libpath=folder,
                          installed_pkgs=installed_pkgs,
                          myrepos=options()$repos),
              n_jobs=1,
              template=list(cores=4,memory=1024))


samples=5000
# run a big-ish compute job
res <- clustermq::Q(compute, 
                    n = 1:samples, 
                    n_jobs = 20,
                    chunk_size=100, 
                    export=list(libpath=folder),
                    template=list(cores=1,memory=1024),
                    log_worker = TRUE)
