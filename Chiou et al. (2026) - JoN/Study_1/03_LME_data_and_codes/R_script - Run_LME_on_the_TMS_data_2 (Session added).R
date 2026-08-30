# ==========================================================
# Linear Mixed-effects model for TMS study
# Including Session and random slope model comparison
# ==========================================================

# 1. LOAD LIBRARIES
library(lme4)
library(lmerTest)
library(readxl)
library(emmeans)
library(dplyr)

# 2. IMPORT DATA
my_data <- read_excel("TMS_data_long_format_for_LME - 2 (Session added).xlsx")

# 3. PREPARE VARIABLES
my_data <- my_data %>%
  mutate(
    Subject = factor(Subject),
    TMS = factor(TMS, levels = c("Vertex", "AG")),
    Concreteness = factor(Concreteness),
    Relatedness = factor(Relatedness),
    Presentation = factor(Presentation),
    Session = factor(Session, levels = c("First", "Second"))
  )

# Check coding
str(my_data)
table(my_data$Subject, my_data$TMS, my_data$Session)

# 4. SET OPTIMISER
ctrl <- lmerControl(
  optimizer = "bobyqa",
  optCtrl = list(maxfun = 100000)
)


# ==========================================================
# PART A: TEST SESSION AS A FIXED EFFECT
# ==========================================================

# This model does not contain Session as a fixed effect.
model_no_session <- lmer(
  RT ~ TMS * Concreteness * Relatedness * Presentation +
    (1 | Subject),
  data = my_data,
  REML = FALSE,
  control = ctrl
)

# This model includes Session and tests its main effect. 
model_session_main <- lmer(
  RT ~ TMS * Concreteness * Relatedness * Presentation +
    Session +
    (1 | Subject),
  data = my_data,
  REML = FALSE,
  control = ctrl
)

# (i) The Session main effect & (ii) Session x TMS interaction.
model_session_by_TMS <- lmer(
  RT ~ TMS * Concreteness * Relatedness * Presentation +
    Session * TMS +
    (1 | Subject),
  data = my_data,
  REML = FALSE,
  control = ctrl
)

# This model includes all possible interactions between Session and other factors.
model_session_all_interactions <- lmer(
  RT ~ TMS * Concreteness * Relatedness * Presentation +
    Session * (TMS + Concreteness + Relatedness + Presentation) +
    (1 | Subject),
  data = my_data,
  REML = FALSE,
  control = ctrl
)

# Compare whether Session improves the model
fixed_model_comparison <- anova(
  model_no_session,
  model_session_main,
  model_session_by_TMS,
  model_session_all_interactions
)

print(fixed_model_comparison)
print(AIC(model_no_session, model_session_main, model_session_by_TMS, model_session_all_interactions))
print(BIC(model_no_session, model_session_main, model_session_by_TMS, model_session_all_interactions)) 

# Save Part A results (Session fixed-effect models)

write.csv(
  as.data.frame(fixed_model_comparison),
  "Session_Fixed_Effects_Model_Comparison.csv"
)

write.csv(
  as.data.frame(
    AIC(
      model_no_session,
      model_session_main,
      model_session_by_TMS,
      model_session_all_interactions
    )
  ),
  "Session_Fixed_Effects_AIC.csv"
)

write.csv(
  as.data.frame(
    BIC(
      model_no_session,
      model_session_main,
      model_session_by_TMS,
      model_session_all_interactions
    )
  ),
  "Session_Fixed_Effects_BIC.csv"
)


# ==========================================================
# PART B: RANDOM SLOPE MODEL COMPARISON
# ==========================================================

# Following the reviewer's recommendation, we evaluated a series of increasingly complex 
# random-effect structures to account for inter-individual variability in task performance.
# We compared models with subject-specific random slopes for TMS, Concreteness, Session, Relatedness, & Presentation.
# Both correlated (|) and uncorrelated (||) structures of random effects were considered. The uncorrelated models were 
# included simply as alternative models in cases where more complex correlated random-effect structures might result in 
# singular fits or convergence difficulties. Correlated models allowed correlations among task-related random effects to be 
# estimated freely, whereas uncorrelated models included the same random effects but constrained their correlations to zero.

# Simplest model with only random intercepts for subjects
m0 <- lmer(
  RT ~ TMS * Concreteness * Relatedness * Presentation +
    Session +
    (1 | Subject),
  data = my_data,
  REML = FALSE,
  control = ctrl
)

# Slightly more complex model with random slopes for subjects and TMS.
m1_TMS <- lmer(
  RT ~ TMS * Concreteness * Relatedness * Presentation +
    Session +
    (1 + TMS | Subject),
  data = my_data,
  REML = FALSE,
  control = ctrl
)

# Even more complex model with random slopes for subjects, TMS, and Session.
m2_TMS_Session <- lmer(
  RT ~ TMS * Concreteness * Relatedness * Presentation +
    Session +
    (1 + TMS + Session | Subject),
  data = my_data,
  REML = FALSE,
  control = ctrl
)

# Further complex model with random slopes for subjects, TMS, Session, and Relatedness.
m3_TMS_Session_Relatedness <- lmer(
  RT ~ TMS * Concreteness * Relatedness * Presentation +
    Session +
    (1 + TMS + Session + Relatedness | Subject),
  data = my_data,
  REML = FALSE,
  control = ctrl
)

# Most complex model with random slopes for subjects, Concreteness, TMS, Session, Relatedness, and Presentation.
m4_TMS_Concreteness_Session_Relatedness_Presentation <- lmer(
  RT ~ TMS * Concreteness * Relatedness * Presentation +
    Session +
    (1 + TMS + Concreteness + Session + Relatedness + Presentation | Subject),
  data = my_data,
  REML = FALSE,
  control = ctrl
)

# Below are uncorrelated versions of the random-effects models above.
m2_uncorrelated <- lmer(
  RT ~ TMS * Concreteness * Relatedness * Presentation +
    Session +
    (1 + TMS + Session || Subject),
  data = my_data,
  REML = FALSE,
  control = ctrl
)

m3_uncorrelated <- lmer(
  RT ~ TMS * Concreteness * Relatedness * Presentation +
    Session +
    (1 + TMS + Session + Relatedness || Subject),
  data = my_data,
  REML = FALSE,
  control = ctrl
)

m4_uncorrelated <- lmer(
  RT ~ TMS * Concreteness * Relatedness * Presentation +
    Session +
    (1 + TMS + Concreteness + Session + Relatedness + Presentation || Subject),
  data = my_data,
  REML = FALSE,
  control = ctrl
)

# Check convergence and singularity

model_names <- c(
  "m0",                                                      # m0:only random intercepts for subjects
  "m1_TMS",                                                  # m1: random slopes for subjects and TMS
  "m2_TMS_Session",                                          # m2: random slopes for subjects, TMS, and Session
  "m3_TMS_Session_Relatedness",                              # m3: random slopes for subjects, TMS, Session, and Relatedness
  "m4_TMS_Concreteness_Session_Relatedness_Presentation",    # m4: random slopes for subjects, Conc, TMS, Sess, Rel, and Pres
  "m2_uncorrelated",                                         # m2_uncorrelated: uncorrelated version of m2
  "m3_uncorrelated",                                         # m3_uncorrelated: uncorrelated version of m3
  "m4_uncorrelated"                                          # m4_uncorrelated: uncorrelated version of m4
)

models <- list(
  m0,
  m1_TMS,
  m2_TMS_Session,
  m3_TMS_Session_Relatedness,
  m4_TMS_Concreteness_Session_Relatedness_Presentation,
  m2_uncorrelated,
  m3_uncorrelated,
  m4_uncorrelated
)

singularity_check <- data.frame(
  Model = model_names,
  Singular = sapply(models, isSingular)
)

print(singularity_check)

# Model comparison using AIC & BIC

random_model_comparison_AIC <- AIC(
  m0,
  m1_TMS,
  m2_TMS_Session,
  m3_TMS_Session_Relatedness,
  m4_TMS_Concreteness_Session_Relatedness_Presentation,
  m2_uncorrelated,
  m3_uncorrelated,
  m4_uncorrelated
)

random_model_comparison_BIC <- BIC(
  m0,
  m1_TMS,
  m2_TMS_Session,
  m3_TMS_Session_Relatedness,
  m4_TMS_Concreteness_Session_Relatedness_Presentation,
  m2_uncorrelated,
  m3_uncorrelated,
  m4_uncorrelated
)

print(random_model_comparison_AIC)
print(random_model_comparison_BIC)

# Likelihood-ratio tests for nested models
anova(m0, m1_TMS, m2_TMS_Session, m3_TMS_Session_Relatedness, m4_TMS_Concreteness_Session_Relatedness_Presentation)
anova(m0, m2_uncorrelated, m3_uncorrelated, m4_uncorrelated)

# Select the final 'winner' model

# Rank models by AIC
random_model_comparison_AIC[order(random_model_comparison_AIC$AIC), ]

# Rank models by BIC
random_model_comparison_BIC[order(random_model_comparison_BIC$BIC), ]

# Save the outcome of model comparison as .csv files

write.csv(as.data.frame(random_model_comparison_AIC),
          "Random_Effects_Model_Comparison_AIC.csv")

write.csv(as.data.frame(random_model_comparison_BIC),
          "Random_Effects_Model_Comparison_BIC.csv") 
