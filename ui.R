
# User-interface for Next Word prediction shiny application.

# Author:  Oleg Trofilov <olegtrof@gmail.com>
# Ver 1.1  20-Apr-2016  

appdir <- "./Data/full/"

shinyUI(
    navbarPage(
        shinyjs::useShinyjs(),
        title="Natural Language Prediction", id="navbar_main",
               # Sidebar with a slider input for number of bins
               tabPanel(title="Predict next word", value="tab_predict",
                        sidebarLayout(
                            sidebarPanel(
                                    helpText("This application predicts next word for the text you typed."),
                                    hr(),
                                    textInput("input_text", "Please, type your text", width= "100%"),
                                    actionButton("btn_predict",  "Predict"),
                                    br(),
                                    helpText("After you pushed the button, the input is passed to the model to make the prediction. The result is reflected on the next panel."),
                                    br(),
                                    helpText("Wordcloud word size reflects the probablity of the word"),
                                    hr(),
                                    helpText("The data source used to train the model is located here: "),
                                    a("Swiftkey Corpora", href="https://d396qusza40orc.cloudfront.net/dsscapstone/dataset/Coursera-SwiftKey.zip")
                            ), 
                            mainPanel(
                                 h3("Next word prediction"),
                                 hr(),
                                 h4("This is the sentence you typed: "),
                                 wellPanel(textOutput("out_input_text"), style = "color:blue;font-size:14pt;"),         
                                 h4("Top word prediction: "),
                                 wellPanel(textOutput("predicted_text1"), style = "color:red; font-size:14pt;"),
                                 hr(),
                                 h4("Alternative top predictions: "),
                                 wellPanel(style = "color:green; font-size:14pt;",
                                     textOutput("predicted_text2"), 
                                     textOutput("predicted_text3"), 
                                     textOutput("predicted_text4"), 
                                     textOutput("predicted_text5")
                                 ),     
                                 hr(),
                                 plotOutput("wcplot", width = "400px", height="200px") 
                                )

                        )
               ), 
               tabPanel(title="Model and Algorithm", value = "tab_model",
                        mainPanel(
                            tabsetPanel(
                                tabPanel(title = "Prediction model",
                                         mainPanel(
                                             includeHTML(paste0(appdir, "build_pred_model.html"))
                                             #,
                                             #hr(),
                                             #h4("Sample of 4-grams")
                                             #,
                                             #dataTableOutput("sample_ngram")
                                         )),
                                tabPanel(title = "Search workflow",
                                         mainPanel(
                                             includeMarkdown(paste0(appdir, "search_workflow.Rmd"))
                                        )
                                ),
                                tabPanel(title = "Benchmark test",
                                         mainPanel(
                                             includeHTML(paste0(appdir, "benchmark_test.html"))
                                         )
                                )
                        )
                    )
    ),
    tabPanel(title="Corpora info", value="tab_info",
             sidebarLayout(
                 sidebarPanel = NULL,    
                 mainPanel(
                     includeHTML(paste0(appdir,"final_report.html")
                 )
             )
    )
)
)
)