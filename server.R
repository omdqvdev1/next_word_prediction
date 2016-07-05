
# Server logic for a Next Word Predictiin shiny application.

# Author:  Oleg Trofilov <olegtrof@gmail.com>
# Ver 1.1  20-Apr-2016  

appdir <- "./Data/full/"
source(paste0(appdir, "all_functions_last.R"))
initialize_stopwords()

library(shiny)
library(shinyjs)
library(wordcloud)

renderMyText <- function(txt) {
    if (is.na(txt) ) {
        renderText("")  
    } else {
        renderText(txt)
    }
}
shinyServer(function(input, output, session) {
    # load necessary data files with n-grams and update progress bar
    values <- reactiveValues()
    withProgress({
        setProgress(value=0.2)    
        onegram_df <<- readRDS(paste0(appdir, "onegram_df_final5_red.rds"))
        setProgress(value = 0.4)
        bigrams_df <<- readRDS(paste0(appdir, "bigrams_df_final5_red.rds"))
        setProgress(value = 0.6)
        trigrams_df <<- readRDS(paste0(appdir, "trigrams_df_final5_red.rds"))
        setProgress(value = 0.8)
        quadgrams_df <<- readRDS(paste0(appdir, "quadgrams_df_final5_red.rds"))
        setProgress(value = 1)
        updateNavbarPage(session, "navbar_main", selected = "tab_predict")
    }, value = 0, message = "Loading data..."
    )

  observe({
      # make prediction only when button is pressed
      input$btn_predict
      # predict next word (up to 5 variants)
      output_text <- isolate(
          process_input_string_wc(input$input_text, input$chkCutLongStopwords)
      )
      # Make the wordcloud drawing predictable during a session
      wordcloud_rep <- repeatable(wordcloud)
      # draw wordcloud of the predicted variants
      if (output_text$word[1] != "<unk>") 
          output$wcplot <- renderPlot({
              wordcloud_rep(output_text$word, output_text$qty, min.freq=1, max.words=5, rot.per = 0, fixed.asp =FALSE, colors=brewer.pal(8,"Dark2"), use.r.layout=TRUE)
          }) else {
              output$wcplot <- renderPlot(NULL)
              output_text$word[1] <- ""
          }
      # output up to 5 predictions of the next word
      output$out_input_text <- renderText(input$input_text)
      output$predicted_text1 <- renderMyText(output_text$word[1])
      output$predicted_text2 <- renderMyText(output_text$word[2])
      output$predicted_text3 <- renderMyText(output_text$word[3])
      output$predicted_text4 <- renderMyText(output_text$word[4])
      output$predicted_text5 <- renderMyText(output_text$word[5])
  })
})
