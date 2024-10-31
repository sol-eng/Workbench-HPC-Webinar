# example courtesy of Andrie de Vries (andrie@posit.co)

compute <- function(n) {
  peng <- penguins %>%
    mutate(species = as.factor(species), sex = as.factor(sex)) %>%
    sample_n(100)
  glm(body_mass_g ~ species + sex, data = peng)
}

library(clustermq)

samples <- 1000

# run a big-ish compute job
res <- clustermq::Q(
  compute,
  n = 1:samples,
  n_jobs = 20,
  chunk_size = 10,
  pkgs = c("dplyr", "palmerpenguins")
)

# create new data
new_dat <- tibble::tribble(~ species, ~ sex, "Chinstrap", "male")

# create prediction for each of the models
library(purrr)
library(tibble)
preds <- tibble(mass = map_dbl(res, predict, new_dat))


# plot the result
library(ggplot2)
ggplot(preds, aes(x = mass)) +
  geom_histogram(bins = samples / 50) +
  ggtitle("Ensemble model prediction of mass of male Chinstrap penguins")
