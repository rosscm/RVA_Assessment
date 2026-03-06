# Question 3: Interactive R Shiny Application
# Integrate the visualization from Question 2 into an interactive dashboard

# Load necessary libraries
library(shiny)
library(ggplot2)
library(dplyr)
library(pharmaverseadam)

# Load data
message("Loading data...")
data("adae", package = "pharmaverseadam")
data("adsl", package = "pharmaverseadam")

# Prepare data for plotting (similar to Question 2, but with ACTARM included)
message("Processing TEAE data for interactive dashboard...")
adae_teae <- adae %>% 
    filter(TRTEMFL == "Y") %>%
    select(USUBJID, ACTARM, AESOC, AESEV) %>%
    distinct(USUBJID, ACTARM, AESOC, AESEV)

ae_summary <- adae_teae %>%
    group_by(ACTARM, AESOC, AESEV) %>%
    summarise(SubjectCount = n_distinct(USUBJID), .groups = "drop") %>%
    group_by(ACTARM, AESOC) %>%
    mutate(TotalSubjects = sum(SubjectCount)) %>%
    ungroup() %>%
    arrange(TotalSubjects)

active_arms <- adae_teae %>%
    distinct(ACTARM) %>%
    pull(ACTARM)

ae_summary <- ae_summary %>%
    filter(ACTARM %in% active_arms) # Keep only arms with TEAEs

# Define UI
message("Setting up Shiny UI...")
ui <- fluidPage(
    titlePanel("AE Summary Interactive Dashboard"),
    sidebarLayout(
        sidebarPanel(
            # check box selection for treatment arms (allowing multiple selections)
            checkboxGroupInput("arm_filter", "Select Treatment Arm(s):",
                               choices = unique(ae_summary$ACTARM),
                               selected = unique(ae_summary$ACTARM))
        ),
        mainPanel(
            plotOutput("ae_plot")
        )
    )
)

# Define Server
message("Setting up Shiny Server...")
server <- function(input, output) {
    filtered_data <- reactive({
        ae_summary %>% filter(ACTARM %in% input$arm_filter)
    })
    output$ae_plot <- renderPlot({
        ggplot(filtered_data(), aes(x = SubjectCount, y = reorder(AESOC, TotalSubjects), fill = AESEV)) +
            geom_bar(stat = "identity", position = position_stack(reverse = TRUE)) +
            labs(title = paste("Unique Subjects per SOC and Severity Level"),
                 x = "Count of Unique Subjects",
                 y = "System Organ Class (AESOC)",
                 fill = "AE Severity") +
            theme_minimal() +
            scale_fill_brewer(palette = "Reds") +
            theme(axis.text.y = element_text(size = 10),
                  text = element_text(family = "system-ui", size = 14))
    })
}

# Run the application
message("Launching Shiny app...")
shinyApp(ui = ui, server = server)
