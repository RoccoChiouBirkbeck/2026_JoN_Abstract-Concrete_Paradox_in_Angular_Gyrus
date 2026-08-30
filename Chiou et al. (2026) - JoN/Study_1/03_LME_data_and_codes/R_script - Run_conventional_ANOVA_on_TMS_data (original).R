# This script performs a repeated measures ANOVA on TMS data using the afex package in R.

# Run this only once if the packages are not installed
install.packages(c("readxl", "afex", "emmeans"))

# Load packages
library(readxl)
library(afex)
library(emmeans)

# Read the data
data <- read_excel("TMS_data_long_format_for_LME - 1 (original).xlsx", sheet = "Sheet1")

# Convert participant and experimental variables into factors
data$Subject      <- factor(data$Subject)
data$TMS          <- factor(data$TMS,
                            levels = c("Vertex", "AG"))
data$Concreteness <- factor(data$Concreteness,
                            levels = c("Abstract", "Concrete"))
data$Relatedness  <- factor(data$Relatedness,
                            levels = c("Unrelated", "Related"))
data$Presentation <- factor(data$Presentation,
                            levels = c("SimVis", "VisVis", "SpchVis"))

# Check the data structure
str(data)

anova_model <- aov_ez(
  id = "Subject",
  dv = "RT",
  data = data,
  within = c(
    "TMS",
    "Concreteness",
    "Relatedness",
    "Presentation"
  ),
  type = 3,
  factorize = FALSE,
  anova_table = list(
    correction = "none",
    es = "pes"
  )
)

# Create the ANOVA results table
anova_results <- nice(anova_model)

# Display the table
print(anova_results)

# Save it as a CSV file in your current working folder
write.csv(
  anova_results,
  file = "Repeated_measures_ANOVA_results.csv",
  row.names = FALSE
)
