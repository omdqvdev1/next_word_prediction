#### GLOBAL VARIABLES AND FUNCTIONS FOR TEXT PROCESSING AND NEXT WORD PREDICTION

# Author:  Oleg Trofilov <olegtrof@gmail.com>
# Ver 1.1  20-Apr-2016  

library(stringi)
library(dplyr)
library(tm)
library(SnowballC)

stwd <- NULL            # stopwords
engwords <- NULL        # english words 

stwd_quote <- NULL      # stopwords with quotes, like <wasn't >
stwd_rem_quote <- NULL  # stopwords without quotes, like <wasnt>

# initialize data frames which will store resulting n-grams
onegram_df <- data.frame()
bigrams_df <- data.frame()
trigrams_df <- data.frame()
quadgrams_df <- data.frame()


initialize_stopwords <- function() {
    # create matrix of stopwords from standard tm library
    stwd <<- as.data.frame(tm::stopwords(), stringsAsFactors = FALSE)
    names(stwd) <- c("stopword")
    # enumerate stopwords with hexadecimal numbers
    stwd <<- stwd %>% mutate(stophex = format(as.hexmode(as.numeric(rownames(stwd))), 2))
    # extract stopwords with ' insidem, excluding some specific stopwords which would become usual words after removal of the quote
    stwd_quote <<- stwd$stopword[grepl("\\w\\'\\w", stwd)]
    stwd_quote <<- stwd_quote[ !stwd_quote %in% c("he'll", "she'll", "we'll", "it's", "we're") ]
    ####make another list of stopwords with ' inside removed
    stwd_rem_quote <<- stri_replace_all_regex(unlist(stwd_quote), "(\\w)(\\')(\\w)", "$1$3")
}

get_sowpods <- function() {
    # load public list of english words, to be used for construction of n-grams
    destfname <- "./sowpods.txt" # the file was download in beforehand; link is below
    #download.file(url="http://www.wordgamedictionary.com/sowpods/download/sowpods.txt", destfile = destfname, method="libcurl")   
    con <- file(destfname,"r")
    engwords <<- readLines(con)
    close(con)
    engwords <<- engwords[-c(1,2)]
}

readFile <- function(fpath, nl=-1L) {
    # function for reading a text file in ASCII format; nl - number of lines; -1L - all lines, by default
    con <- file(fpath) 
    txt <- readLines(con,encoding = "ASCII", n = nl)
    close(con)
    txt
}

split_file_per_sentences_and_clean <- function(fname, nl=-1L) {
    #reads the file with full path fname, and splits it per sentences and write back to the same directory with another name
    #returns name of the split file
    ff <- readFile(fname, nl) 
    ff <- stri_replace_all_regex(ff, c("mr\\.", "ms\\.", "mrs\\.", "sr\\.", "st\\."), c("mr", "ms", "mrs", "sr", "st"), vectorize_all = FALSE,  opts_regex=stri_opts_regex(case_insensitive=TRUE))
    ff <- stri_split_boundaries(ff, opts_brkiter = stri_opts_brkiter(type="sentence"))
    ff <- clean_text(ff)
    write(ff, file=paste0(fname, ".clean.txt"))      
}

Sample_text <- function(text, perc) {
    # randomly select <perc>% of lines from text file
    sample(text, length(text)*perc, replace=FALSE)    
}


clean_text <- function(texts) {
    ## cleans text files
    texts <- stri_replace_all_regex(stri_enc_toascii(unlist(texts)), "(\032){2,}", '')
    #remove retweets
    texts <- stri_replace_all_regex(texts, "RT\\s?|\\(via\\s?\\)"," ")
    #make all lowecase
    texts <- stri_trans_tolower(texts)
    #replace words with numbers inside
    texts <- stri_replace_all_regex(texts, "\\s?[\\w,-]*[0-9]\\w*"," ")
    #replace \032 inside word with '
    texts <- stri_replace_all_regex(texts, "\\b\032\\b","'")
    #exclude URL (replace with space)
    texts <- stri_replace_all_regex(texts, '(f|ht)tp(s?)://[^ "()<>]*'," ")
    #exclude @<somename>
    texts <- stri_replace_all_regex(texts, "(^|[^@\\w])@(\\w{1,15})\\b"," ")
    #exclude #hashtag
    texts <- stri_replace_all_regex(texts, "(^|[^#\\w])#(\\w{1,15})\\b", " ")
    #exclude extra symbols
    texts <- stri_replace_all_regex(texts, "[-:)=(/-;%^*&@#$<>{}\\_\\+]"," ")
    #remove sites URL
    texts <- stri_replace_all_regex(texts, "\\.\\w{2,}", " ")
    #remove references to the sites containing words below
    texts <- stri_replace_all_regex(texts, "www|amazon|yahoo|google|twitter|facebook|gmail|whatsapp|gmail"," ")
    #remove remaining \032
    texts <- stri_replace_all_regex(texts, "\032", " ")
    #remove repeated dots
    texts <- stri_replace_all_regex(texts, "^\\.{1,}$", " ")
    #exclude leading or trailing spaces
    texts <- stri_trim_both(texts)
    #exclude extra symbols
    texts <- stri_replace_all_regex(texts, "[\\.\\?\\!\\,\\~]"," ")
    #exclude extra spaces 
    texts <- stri_replace_all_regex(texts, "(\\s){2,}", " ")
    #remove all remaing double quotes
    texts <- stri_replace_all_regex(texts, '\\"', " ")
    #remove training and leading spaces
    texts <- stri_trim_both(texts)
    #remove empty strings
    texts <- Filter(stri_length, texts)
    texts <- texts[!is.na(texts)]
    #put ' in between word and a single letter t or d or s, like wouldn t be wouldn't
    texts <- stri_replace_all_regex(texts, "(\\b)\\s(t|d|s|m)(\\s|$)","\\'$2 ")
    texts
}


########
impute_quote <- function(texts) {
  ## impute symbol <'> into incorrect stopwords
  stri_replace_all_regex(texts,  "\\b" %s+% stwd_rem_quote %s+% "\\b", stwd_quote, vectorize_all = FALSE)
}

encode_stopwords <- function(txt) {
    ## encodes stopwords by Q followed by hex code
    if (length(txt) > 0) stri_replace_all_regex(txt,  "(^|\\s|[:punct:])" %s+% stwd$stopword[1:174] %s+% "(\\s|$|('$))", "$1Q" %s+% stwd$stophex[1:174] %s+% "$2", vectorize_all = FALSE)
    else txt
}

compress_stopwords <- function(txt) {
    ## compress encoded stopwords: two pass: pairs then all pairs and signle together
    if (length(txt) > 0) stri_replace_all_regex(stri_replace_all_regex(txt, "(Q[0-9,a-f][0-9,a-f]) (Q[0-9,a-f][0-9,a-f])", "$1$2"), "(Q[0-9,a-f][0-9,a-f]) (Q[0-9,a-f][0-9,a-f])", "$1$2")
    else txt
} 

decompress_stopwords <- function(txt) {
    ## decompresses compressed encoded stopwords
    if (length(txt) > 0) unlist(lapply(txt, FUN=function(t) stri_flatten(stri_split_fixed(t, "Q")[[1]][-1]," "))) 
    else txt
}

decompress_decode_stopwords <- function(x) {
    ## decodes encoded and compressed stopwords
  stri_trim_right(stri_replace_all_regex(x,  "Q" %s+% stwd$stophex[1:174] %s+% "", stwd$stopword[1:174] %s+% " ", vectorize_all = FALSE))    
}


get_sentence_last_tokens <- function(tt, nn) {
    ## cleans input text and outputs the last <nn> tokens
    tt.clean <- clean_text(tt)
    if (length(tt.clean) == 0) {
        l <- list(orig = tt, tokens = NULL)
    } else if (stri_length(tt.clean) == 0) {
        l <- list(orig = tt, tokens = NULL)
    }    else {
        ttc <- last(stri_split_fixed(compress_stopwords(encode_stopwords(tt.clean)), " "))
        ttc <- wordStem(ttc, language = "english")
        ttc.len <- length(ttc)
        l <- list(orig = tt, tokens = ttc[(ttc.len-min(ttc.len, nn)+1):ttc.len])
    }
    l
}

generate_texts_ngrams <- function(txt, nl) {
    ## creates list of n-grams from input text file; nl - number corresponding to N (N-gram)
    unlist(lapply(1:length(txt), FUN=function(i) vapply(ngrams(txt[[i]], nl), paste, "", collapse = " ")))
}


find_next_tokens_wc <- function(tk) {
    ## provides top 5 predictions of the next word given the <tk> tokens as an argument, together with frequencies(used for wordcloud)
    tk.length = length(tk)
    
    if (tk.length == 3) {
        res <- quadgrams_df %>% 
            filter(token1 == tk[1] & token2 == tk[2] & token3 == tk[3]) %>% 
            arrange(desc(qty)) %>% 
            select(token4, qty) 
    } else if (tk.length == 2) {
        res <- trigrams_df %>% filter(token1 == tk[1] & token2 == tk[2]) %>% 
            arrange(desc(qty)) %>% 
            select(token3, qty) 
    } else if (tk.length == 1) {
        res <- bigrams_df %>% filter(token1 == tk[1]) %>% 
            arrange(desc(qty)) %>% 
            select(token2, qty) 
    } else {
        res <- data.frame()    
    }
    
    if (nrow(res) > 0) {
        # in the result, all stopwords should be decoded in the native form (english)
        res <- list(word=decompress_decode_stopwords(as.data.frame(res)[,1]), qty=res[,2])
    }  else if (tk.length == 0) {
        res <- list(word="<unk>", qty=0) 
    }  else if (tk.length >= 2) {
        return(find_next_tokens_wc(tk[-1]))
    } else if(substr(tk, 1, 1) == "Q") {
        res <- onegram_df %>% 
            filter(substr(token,1,3) == tk) %>% 
            arrange(desc(qty)) %>% 
            select(token, qty) %>% filter(row_number() <= 5)
        if (nrow(res) > 0) {
            res <- list(word=decompress_decode_stopwords(substr(as.data.frame(res), stri_length(tk)+1, stri_length(res$token))), qty=res$qty)
        } else {
            return(find_next_tokens_wc(substr(tk, stri_length(tk)-2, stri_length(tk))))
        }     
    } else {
        res <- list(word="<unk>", qty=0) 
    }
    res
}

process_input_string_wc <- function(tt, last_n_words=3) {
    ## gets input string, and provides prediction of the next word (up to 5 possible variants)
    print(tt)
    found_results <- 0
    if (length(tt) == 0) return(list(word="<unk>", qty=0))
    if (stri_length(tt) == 0) return(list(word="<unk>", qty=0))
    ff <- stri_replace_all_regex(tt, c("mr\\.", "ms\\.", "mrs\\.", "sr\\.", "st\\."), c("mr", "ms", "mrs", "sr", "st"), vectorize_all = FALSE,  opts_regex=stri_opts_regex(case_insensitive=TRUE))
    last_punct <- NA
    if (anyNA(last_punct) == TRUE) {
        if (stri_trim(tt) == "") {
            output <- list(word="<unk>", qty=0) 
        } else  {
            l <- get_sentence_last_tokens(ff, last_n_words)
            output <- find_next_tokens_wc(l$tokens)
        }    
    } else if (as.numeric(last_punct[,2]) == stri_length(stri_trim(ff))) {
        output <- list(word="<unk>", qty=0) 
    } else {
        l <- get_sentence_last_tokens(ff, last_n_words)
        output <- find_next_tokens_wc(l$tokens) # make prediction of the next word
    }
    output
}

