# Question 1: TEAE Summary Table
# Create a regulatory-compliant summary table of Treatment-Emergent Adverse Events (TEAEs)

# Load necessary libraries
library(tidyverse)
library(gtsummary)
library(pharmaverseadam)
library(gt)

# Load data
data("adae", package = "pharmaverseadam")
data("adsl", package = "pharmaverseadam")

# Filter for Treatment-Emergent Adverse Events
adae_teae <- adae %>% 
    filter(TRTEMFL == "Y") %>%
    select(USUBJID, ACTARM, AESOC, AEDECOD)

# Create a dataset for 'Any TEAE' (overall summary row)
any_teae <- adae_teae %>%
    distinct(USUBJID, ACTARM) %>%
    mutate(
        AESOC = "Any TEAE",
        AEDECOD = "Any TEAE"
    )

# Create a dataset for System Organ Class (SOC) level
soc_teae <- adae_teae %>%
    distinct(USUBJID, ACTARM, AESOC) %>%
    mutate(AEDECOD = AESOC) # Roll up to SOC level

# Create a dataset for Preferred Term (PT) level
pt_teae <- adae_teae %>%
    distinct(USUBJID, ACTARM, AESOC, AEDECOD)

# Combine all levels for the table
combined_teae_raw <- bind_rows(any_teae, soc_teae, pt_teae) %>%
    filter(!is.na(AESOC)) %>%
    mutate(
        # Create an indentation standard for PTs (using Unicode non-breaking spaces so gtsummary retains them)
        Term = ifelse(AESOC == AEDECOD, AESOC, paste0("\U00A0\U00A0\U00A0\U00A0", AEDECOD))
    )

# Define the exact hierarchical structure order (Any TEAE -> SOC -> PT)
term_order <- combined_teae_raw %>%
    distinct(AESOC, AEDECOD, Term) %>%
    arrange(
        AESOC != "Any TEAE", # "Any TEAE" comes first
        AESOC,               # Sort alphabetically by SOC
        AESOC != AEDECOD,    # Ensure SOC term comes before its PTs
        AEDECOD              # Sort alphabetically by PT
    ) %>%
    pull(Term)

# Ensure unique subjects per term/arm
combined_teae <- combined_teae_raw %>%
    distinct(USUBJID, ACTARM, Term)

# Merge with ADSL to ensure correct denominators (all subjects in study)
# We structure as wide: columns for each Term, 1/0 for presence
wide_teae <- adsl %>%
    select(USUBJID, ACTARM) %>%
    left_join(
        combined_teae %>% mutate(Present = 1),
        by = c("USUBJID", "ACTARM"),
        relationship = "many-to-many"
    ) %>%
    pivot_wider(
        names_from = Term,
        values_from = Present,
        values_fill = 0,
        values_fn = max
    ) %>%
    select(-USUBJID)

# Identify ACTARM levels that have at least 1 TEAE
active_arms <- adae_teae %>%
    distinct(ACTARM) %>%
    pull(ACTARM)

# Select columns based on hierarchical sort order
wide_teae <- wide_teae %>%
    select(ACTARM, any_of(term_order)) %>%
    filter(ACTARM %in% active_arms) # Keep only arms with TEAEs

# Generate gtsummary table
teae_table <- wide_teae %>%
    tbl_summary(
        by = ACTARM,
        missing = "no"
    ) %>%
    modify_header(label = "**System Organ Class / Preferred Term**") %>%
    bold_labels()

# Save the table as HTML
dir.create("docs", showWarnings = FALSE)

gt_table <- teae_table %>% as_gt()

gtsave(gt_table, "question_1/TEAE_Summary.html")
gtsave(gt_table, "docs/TEAE_Summary.html")
