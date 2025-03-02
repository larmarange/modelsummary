source("helpers.R")
requiet("fixest")
fixest::setFixest_nthreads(1)

panels <- list(
"Panel A: MPG" = list(
    "A" = lm(mpg ~ hp, data = mtcars),
    "B" = lm(mpg ~ hp + factor(gear), data = mtcars)),
"Panel B: Displacement" = list(
    "A" = lm(disp ~ hp, data = mtcars),
    "C" = lm(disp ~ hp + factor(gear), data = mtcars)))

# (non-)matching models
panels <- list(
    "Panel A: MPG" = list(
        lm(mpg ~ hp, data = mtcars),
        lm(mpg ~ hp + factor(gear), data = mtcars)),
    "Panel B: Displacement" = list(
        lm(disp ~ hp, data = mtcars),
        lm(disp ~ hp + factor(gear), data = mtcars))
)
tab1 <- modelsummary(panels, gof_map = "nobs", output = "dataframe", shape = "rbind")
expect_equivalent(colnames(tab1), c(" ", "(1)", "(2)"))

panels <- list(
    "Panel A: MPG" = list(
        "A" = lm(mpg ~ hp, data = mtcars),
        "B" = lm(mpg ~ hp + factor(gear), data = mtcars)),
    "Panel B: Displacement" = list(
        "A" = lm(disp ~ hp, data = mtcars),
        "C" = lm(disp ~ hp + factor(gear), data = mtcars))
)
tab2 <- modelsummary(panels, gof_map = "nobs", output = "dataframe", shape = "rbind")
expect_equivalent(colnames(tab2), c(" ", "A", "B", "C"))

# stars note
p <- suppressWarnings(modelsummary(panels, output = "markdown", stars = TRUE, shape = "rbind"))
expect_true(any(grepl("Note", p)))

# output formats: no validity
p <- modelsummary(panels, output = "gt", shape = "rbind")
expect_inherits(p, "gt_tbl")
p <- modelsummary(panels, output = "latex", shape = "rbind")
expect_inherits(p, "knitr_kable")

# Issue #593: rbind vs rcollapse
panels <- list(
    list(
        lm(mpg ~ hp, data = mtcars),
        lm(mpg ~ hp + am, data = mtcars)),
    list(
        lm(qsec ~ hp, data = mtcars),
        lm(qsec ~ hp + am, data = mtcars)))
tab1 <- modelsummary(panels, shape = "rbind", gof_map = "nobs", output = "dataframe")
tab2 <- modelsummary(panels, shape = "rcollapse", gof_map = "nobs", output = "dataframe")
expect_true(nrow(tab1) == nrow(tab2) + 1)

# Issue #593: models with different FEs do not get collapsed
panels <- list(
    list(
        feols(mpg ~ cyl | gear, data = mtcars, cluster = ~hp),
        feols(mpg ~ cyl | gear + am, data = subset(mtcars, mpg > 20), cluster = ~hp)),
    list(
        feols(disp ~ cyl | gear, data = mtcars, cluster = ~hp),
        feols(disp ~ cyl | gear + carb, data = mtcars, cluster = ~hp))
)
tab <- modelsummary(panels, shape = "rcollapse", output = "dataframe")
expect_equivalent(sum(tab[[1]] == "FE: gear"), 2)

# Issue #593: models with identical FEs get collapsed
panels <- list(
    list(
        feols(mpg ~ cyl | gear, data = mtcars, cluster = ~hp),
        feols(mpg ~ cyl | gear + carb, data = subset(mtcars, mpg > 20), cluster = ~hp)),
    list(
        feols(disp ~ cyl | gear, data = mtcars, cluster = ~hp),
        feols(disp ~ cyl | gear + carb, data = mtcars, cluster = ~hp))
)
tab <- modelsummary(panels, shape = "rcollapse", output = "dataframe")
expect_equivalent(sum(tab[[1]] == "FE: gear"), 1)