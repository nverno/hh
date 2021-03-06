### compare.R --- 
## Filename: compare.R
## Description: Compare fits
## Author: Noah Peart
## Created: Mon Mar 30 18:04:51 2015 (-0400)
## Last-Updated: Fri Apr 10 21:21:05 2015 (-0400)
##           By: Noah Peart
######################################################################
source("~/work/ecodatascripts/vars/heights/prep.R")                 # data prep
source("~/work/ecodatascripts/vars/heights/canopy/load_canopy.R")   # canopy functions
library(dplyr)
library(magrittr)

## Re-run fast fits
models <- c("gompertz", "power")
inds <- c("dbh", "full", "can", "elev")  # independent variable groupings
specs <- c("abba", "beco")
basedir <- paste0("~/work/hh/")
can_func <- "can_hh"
yrs <- c(99, 11)

stats <- list()
fits <- list()
for (model in models) {
    moddir <- paste0(basedir, model, "/")
    for (ind in inds) {
        inddir <- paste0(moddir, ind, "/")
        source(paste0(inddir, "model.R"))  # get model and fit function
        for (spec in specs) {
            for (yr in yrs) {
                dat <- prep_hh(dat=tp, yr=yr, spec=spec, can_func=can_func)
                dat$ELEV <- dat$ELEV/1000
                ps <- readRDS(paste0(inddir, tolower(spec), "/", tolower(spec), "_", yr, ".rds"))
                fit <- run_fit(dat, ps, yr)
                name <- paste(tolower(model),tolower(spec), yr, ind, sep="_")
                fits[name] <- fit
                stats[[name]] <- c(spec, model, ind, yr, AIC(fit), AICc(fit, nobs=nrow(dat)))
            }
        }
    }
}

## Profile
model <- "power"
ind <- "full"
spec <- "beco"
yr <- 99
method <- "Nelder-Mead"
p1 <- profile(fit, method="uniroot")
ps <- coef(p1)
names(ps) <- gsub("\\..*", "", names(ps))
fit <- run_fit(dat, ps, yr)

## Stats
stats <- as.data.frame(do.call(rbind, stats))
rownames(stats) <- NULL
names(stats) <- c("Species", "Model", "Vars", "Year", "AIC", "AICc")
stats$AIC <- as.numeric(as.character(stats$AIC))
stats$AICc <- as.numeric(as.character(stats$AICc))

## Save fits/stats to temp
if (!file.exists("~/work/hh/temp")) dir.create("~/work/hh/temp")
saveRDS(fits, "./temp/fits.rds")
saveRDS(stats, "./temp/stats.rds")

## By species
abbas <- stats[stats$Species == "abba", ]

## Compare AICs
aics <- lapply(fits, AIC)
abbas <- grep("abba", names(aics))
becos <- grep("beco", names(aics))

acomp <- split(aics[abbas], grep("gompertz", names(aics[abbas])))
bcomp <- split(aics[becos], grep("gompertz", names(aics[becos])))

## LRT
anova(fits[[1]], fits[[3]])  # full model compared to canopy only model
anova(fits[[1]], fits[[5]])  # full -> elev only

## Visuals
library(ggplot2)
