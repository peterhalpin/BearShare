# ------------------------------------------------------------
# Data simulation for paper: Psychometric models of small group collaborations.
# ------------------------------------------------------------

# devtools::install_github("peterhalpin/scirt")
library("scirt")
library("ggplot2")

# ------------------------------------------------------------
# Data simulation for one-parameter RSC model
# ------------------------------------------------------------

# Data generating parameters
n_obs <- 1000 # n respondents
n_items <- 100 # n items
i <- 20 # n items for short form
K <- n_obs/2 # n groups
set.seed(101)

# Individual test
ind_alpha <- runif(n_items, .65, 2.5)
ind_beta <- sort(rnorm(n_items, mean = 0, sd = 1.3))
ind_parms <- data.frame(ind_alpha, ind_beta)
ind_names <- paste0("item", 1:n_items, "_IND")
ind_names_short <- ind_names[sample(n_items, i)] # short forms
row.names(ind_parms) <- ind_names
names(ind_parms) <- c("alpha", "beta")

# Group test
col_alpha <- runif(n_items, .65, 2.5)
col_beta <- sort(rnorm(n_items, mean = 0, sd = 1.3))
col_parms <- data.frame(col_alpha, col_beta)
col_names <- paste0("item", 1:n_items, "_COL")
col_names_short <- col_names[sample(n_items, i)] # short form
row.names(col_parms) <- col_names
names(col_parms) <- c("alpha", "beta")
parms <- rbind(col_parms, ind_parms)

# Respondents
odd <- seq(1, n_obs, by = 2)
theta <- rnorm(n_obs)
theta1 <- theta[odd] # odds
theta2 <- theta[odd + 1] # evens

# RSC parameter
u <- rnorm(K, 0, 1)

# Generate group data
col_data <- data_gen(1, u, col_parms, theta1, theta2)
ind_data <- data_gen(1, rep(0, n_obs), ind_parms, theta, theta)
data <- cbind(col_data[rep(1:K, each = 2),], ind_data[, -c(1:5)])
head(data)

# Save data
#sim_parms <- parms
#sim_data <- data
#devtools::use_data(sim_parms, sim_data, overwrite = T)

# ------------------------------------------------------------
# Parameter estimation for 4 conditions
# ------------------------------------------------------------

# long group test, long individual test
ll_items <- c(col_names, ind_names)
ml_ll <-  rsc(data[ll_items], parms[ll_items, ], method = "ML")
map_ll <- rsc(data[ll_items], parms[ll_items, ], method = "MAP")

# long group test, short individual test
ls_items <- c(col_names, ind_names_short)
ml_ls <-  rsc(data[ls_items], parms[ls_items, ], method = "ML")
map_ls <- rsc(data[ls_items], parms[ls_items, ], method = "MAP")

# short group test, long individual test
sl_items <- c(col_names_short, ind_names)
ml_sl <-  rsc(data[sl_items], parms[sl_items, ], method = "ML")
map_sl <- rsc(data[sl_items], parms[sl_items, ], method = "MAP")

# short group test, short individual test
ss_items <- c(col_names_short, ind_names_short)
ml_ss <-  rsc(data[ss_items], parms[ss_items, ], method = "ML")
map_ss <- rsc(data[ss_items], parms[ss_items, ], method = "MAP")

# ------------------------------------------------------------
# Plots
# ------------------------------------------------------------

# Set up data.frame
gg <- rbind(ml_ll, map_ll, ml_sl, map_sl, ml_ls, map_ls, ml_ss, map_ss)
gg$ind_form <- rep(c("Individual long", "Indvidual short"), each = K*4)
gg$col_form <- rep(c("Group long", "Group short"), each = K*2) %>% rep(times = 2)
gg$Method <- rep(c("ML", "MAP"), each = K) %>% rep(times = 4)
gg$dgp_u <- rep(u, times = 8)

gg$sample <- 0
gg$sample[sample(nrow(gg), nrow(gg)/10)] <- 1

# Drop MLEs that diverged to boundary
drops <- gg[abs(gg$u) > 5, ]
#drops <- gg[abs(gg$u_se) > 15, ]
table(drops$ind_form, drops$col_form, drops$Method)
gg <- gg[abs(gg$u) < 5, ]

# Plot bias
p <- ggplot(gg, aes(x = dgp_u, y = u, group = Method)) +
     geom_point(data = gg[gg$sample == 1,], size = 3, aes(shape = Method, color = Method)) +
    geom_smooth(se = F, size = .75,  aes(linetype = Method, color = Method)) +
    scale_color_manual(values = c("grey10", "grey10")) +
    scale_shape_discrete(solid=F) +
    xlab("Data generating values") +
    ylab("Estimate")  +
    geom_abline(slope = 1, intercept = 0, col = "grey50", size = 1.2) +
    theme_bw(base_size = 15)

p + facet_grid(ind_form ~ col_form)

# Plot SE
q <- ggplot(gg, aes(x = u, y = u_se, group = Method)) +
    geom_point(data = gg[gg$sample == 1,], size = 3, aes(shape = Method, color = Method)) +
    geom_smooth(se = F, size = .8, aes(linetype = Method, color = Method)) +
    scale_color_manual(values = c("grey10", "grey10")) +
    scale_shape_discrete(solid=F) +
    xlab("Estimate") +
    ylab("Standard error")  +
    theme_bw(base_size = 15) +
    coord_cartesian(ylim=c(0,5), xlim=c(-4,4))

q + facet_grid(ind_form ~ col_form)
