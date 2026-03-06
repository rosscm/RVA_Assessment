# Question 2: AE Severity Visualization
# Develop a publication-quality bar chart visualizing the distribution of adverse events

# Load necessary libraries
library(dplyr)
library(ggplot2)
library(pharmaverseadam)

# Load data
message("Loading data...")
data("adae", package = "pharmaverseadam")

# Filter for Treatment-Emergent Adverse Events
message("Processing TEAE data for severity visualization...")
adae_teae <- adae %>% 
    filter(TRTEMFL == "Y") %>%
    select(USUBJID, AESOC, AESEV) %>%
    distinct(USUBJID, AESOC, AESEV) # Ensure unique subjects per severity level within each SOC

# Summarize counts of unique subjects per SOC and severity
ae_summary <- adae_teae %>%
    group_by(AESOC, AESEV) %>%
    summarise(SubjectCount = n_distinct(USUBJID), .groups = "drop") %>%
    group_by(AESOC) %>%
    mutate(TotalSubjects = sum(SubjectCount)) %>%
    ungroup() %>%
    arrange(TotalSubjects) # Order by increasing frequency of total subjects per SOC

# Ensure AESEV is a factor with the correct order (adjust levels as per actual data)
ae_summary$AESEV <- factor(ae_summary$AESEV, levels = c("MILD", "MODERATE", "SEVERE"))

# Create the bar chart
message("Plotting AE severity distribution...")
ae_plot <- ggplot(ae_summary, aes(x = SubjectCount, y = reorder(AESOC, TotalSubjects), fill = AESEV)) +
    geom_bar(stat = "identity", position = position_stack(reverse = TRUE)) +
    labs(title = "Unique Subjects per SOC and Severity Level",
         x = "Count of Unique Subjects",
         y = "System Organ Class (AESOC)",
         fill = "AE Severity") +
    theme_minimal() +
    scale_fill_brewer(palette = "Reds") +
    theme(axis.text.y = element_text(size = 10),
          text = element_text(family = "system-ui", size = 14))

# Save the plot as a PNG file
message("Saving the plot...")
out_file <- file.path("question_2", "AE_Severity_Distribution.png")
ggsave(out_file, plot = ae_plot, width = 14, height = 6, dpi = 300)
message("Plot saved to '", out_file, "'")
