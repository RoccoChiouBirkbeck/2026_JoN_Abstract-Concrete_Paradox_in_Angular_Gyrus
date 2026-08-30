# ==========================================================
# Linear mixed effects on Study 2 (Chiou et al., 2025) 
# ==========================================================

# 1. LOAD LIBRARIES
library(lme4)
library(lmerTest)

# 2. IMPORT DATA
df <- read.csv("Data_file.csv")

# 3. PREPARE VARIABLES
df$Participant <- as.factor(df$Subject)
df$Condition   <- as.factor(df$Condition)

# 4. MODEL 1: Condition only (Concrete vs. Abstract) without ReactionTime
Model1 <- lmer(BrainActivity ~ Condition + (1 | Participant), data = df)
summary(Model1)

# 5. MODEL 2: Condition (Concrete vs. Abstract) + ReactionTime + Interaction
Model2 <- lmer(BrainActivity ~ Condition * ReactionTime + (1 | Participant), data = df)
summary(Model2)
 
# 6. Derive Bayes factor for the concreteness effect under different models
library(BayesFactor)                    
bf_withoutRT <- ttest.tstat(-4.964, 25)  # Under Model1 (without ReactionTime), t=-4.964, N=25
print(exp(bf_withoutRT$bf))
bf_withRT    <- ttest.tstat(-0.914, 25)  # Under Model2 (with ReactionTime), t=-0.914, N=25
print(exp(bf_withRT$bf))
