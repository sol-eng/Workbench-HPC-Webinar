# example courtesy of Andrie de Vries (andrie@posit.co)
compute <- function(n) {
  peng <- penguins %>% 
    filter(!is.na(species) & !is.na(sex)) %>%
    mutate(
      species = as.factor(species),
      sex = as.factor(sex)
    ) %>% 
    sample_n(333)
  glm(body_mass_g ~ species + sex, data = peng)
}

samples=1000

library(crew.cluster) 
library(dplyr)
library(palmerpenguins)

controller<-crew_controller_slurm(
  name = "penguins",
  workers = 10L,
  seconds_idle = 10,
#  slurm_log_output="out",
#  slurm_log_error="error",
  slurm_memory_gigabytes_per_cpu=1
)

controller$start()

# run a big-ish compute job
res <- controller$map(
  command=compute(),
  data=list(compute=compute),
  iterate = list(
    n = seq(samples)
  ),
  packages=c("palmerpenguins","dplyr"),
  verbose=FALSE
)

controller$terminate()

# create new data
new_dat <- tibble::tribble(
  ~species, ~sex,
  "Chinstrap", "male"
)

# create prediction for each of the models
library(purrr)
library(tibble)
preds <- tibble(mass = map_dbl(res$result, predict, new_dat))

# plot the result
library(ggplot2)
ggplot(preds, aes(x = mass)) + 
  geom_histogram(bins=samples/50) +
  ggtitle("Ensemble model prediction of mass of male Chinstrap penguins")

