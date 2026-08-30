# =======================================================================================================================
# This script runs a Linear Mixed Effects (LME) model on the TMS data, testing the winning model from previous selection.
# =======================================================================================================================

# 1. LOAD LIBRARIES (already installed)
library(lme4)
library(lmerTest)
library(readxl)
library(emmeans) # Adding this for post-hoc tests

# 2. IMPORT DATA
# Ensure "experiment_data_long_format.xlsx" is in your working directory
my_data <- read_excel("TMS_data_long_format_for_LME - 2 (Session added).xlsx")

# 3. PREPARE FACTORS
# Converting text columns into "Factors" so R treats them as experimental groups
my_data$Subject      <- as.factor(my_data$Subject)
my_data$TMS          <- as.factor(my_data$TMS)
my_data$Session      <- as.factor(my_data$Session)
my_data$Concreteness <- as.factor(my_data$Concreteness)
my_data$Relatedness  <- as.factor(my_data$Relatedness)
my_data$Presentation <- as.factor(my_data$Presentation)

# Check coding
str(my_data)
table(my_data$Subject, my_data$TMS, my_data$Session)

# SET OPTIMISER
ctrl <- lmerControl(
  optimizer = "bobyqa",
  optCtrl = list(maxfun = 100000)
)

# 3. RUN THE LINEAR MIXED MODEL
m4_TMS_Concreteness_Session_Relatedness_Presentation <- lmer(
  RT ~ TMS * Concreteness * Relatedness * Presentation +
    Session +
    (1 + TMS + Concreteness + Session + Relatedness + Presentation | Subject),
  data = my_data,
  REML = FALSE,
  control = ctrl
)

# 4. VIEW MAIN RESULTS (ANOVA Table)
anova_results <- anova(m4_TMS_Concreteness_Session_Relatedness_Presentation)
print(anova_results)

# 5. POST-HOC TESTS
posthoc_concreteness <- emmeans(m4_TMS_Concreteness_Session_Relatedness_Presentation, pairwise ~ TMS | Concreteness)
posthoc_presentation <- emmeans(m4_TMS_Concreteness_Session_Relatedness_Presentation, pairwise ~ TMS | Presentation)
print(posthoc_concreteness)
print(posthoc_presentation)

# 6. SAVE RESULTS TO EXCEL-FRIENDLY FILE
write.csv(as.data.frame(anova_results), "Final_Results_of_the_Winner_VerifiedforCertainty.csv")
