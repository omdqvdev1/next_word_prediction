### This file contains code for the generation of n-grams for next word prediction

# Author:  Oleg Trofilov <olegtrof@gmail.com>
# Ver 2.5  19-Apr-2016  


### Load file with functions used for the construction of n-grams
source("all_functions_last.R")

flen = -1L                  # by default, full file
initialize_stopwords()      # generate list of stopwords numbered by HEX
get_sowpods()               # load list of english words 


profanity <- readFile("profanity_filter.txt")  # load profinity filter

# clean source text files (blogs, twitters, news) and store in new files
split_file_per_sentences_and_clean("./Data/final/en_US/en_US.blogs.txt", flen)
split_file_per_sentences_and_clean("./Data/final/en_US/en_US.news.txt", flen)
split_file_per_sentences_and_clean("./Data/final/en_US/en_US.twitter.txt",flen)

blog1 <- readFile("./Data/full/en_US.blogs.txt.clean.txt")
news1 <- readFile("./Data/full/en_US.news.txt.clean.txt")
twits1 <- readFile("./Data/full/en_US.twitter.txt.clean.txt")


# create single corpora from all cleaned texts files
mixed <- c(blog1, news1, twits1)
saveRDS(mixed, "./Data/full/en_US.mixed_full.rds")
rm(blog1, news1, twits1)
#mixed <- readRDS("./Data/full/en_US.mixed_full.rds")

# impute quotes in some words where necessary (e.g. wouldn t, weren t)
mixed <- impute_quote(mixed)
saveRDS(mixed, "./Data/full/en_US.mixed_full_quotes.rds")

# encode all stopwords occured in the text by corresponding HEX numbers
mixed <- encode_stopwords(mixed)
saveRDS(mixed, "./Data/full/en_US.mixed_full_quotes_stopwords.rds")

# compress encoded stopwords 
mixed <- compress_stopwords(mixed)
saveRDS(mixed, "./Data/full/en_US.mixed_full_quotes_stopwords_compressed.rds")

# extract all words from the prepared text file
mixed <- stri_extract_all_words(mixed, locale=stri_locale_get()) 
saveRDS(mixed, "./Data/full/en_US.mixed_full_quotes_stopwords_compressed_extracted.rds")


##############MAIN BLOCK - generate one-, two-, tree, four-grams from the text

#------------------------------ONEGRAMS PROCESSING-----------------------------------------------------
onegram <- as.data.frame(unlist(mixed), stringsAsFactors = FALSE)
names(onegram) <- c("token")

# calculate frequency of words - 1-grams
onegram <- onegram %>% group_by(token) %>% summarise(qty = n()) 
saveRDS(onegram, "./Data/full/onegram.rds")

onegram <- subset(onegram, !is.na(token))

# mark stopwords (those beginning with Q)
onegram <- onegram %>% mutate(stopwords_flag = stri_detect_fixed(token, "Q"))

# find non-english words occured less than 20 times, and all prfanity words
skip_words <- c(unlist(onegram$token[!(onegram$token %in% engwords | stri_detect_fixed(onegram$token, "Q")) & onegram$qty < 20]), profanity)
saveRDS(skip_words, "./Data/full/skip_words.rds")

# mark these words as "<unk>"
onegram$token[onegram$token %in% skip_words] <- '<unk>'  
onegram <- onegram %>% group_by(token) %>% summarise(qty = sum(qty)) 

# recalculate frequencies for 1-grams (all <unk> will be treated as one virtual word)

onegram_df <- onegram %>% arrange(desc(qty)) %>% mutate(runperc = cumsum(qty)/sum(qty)) 
onegram_df <- subset(onegram_df, runperc < 0.99, select=c("token","qty"))
saveRDS(onegram, "./Data/final/onegram_df_final5_red.rds")

#-------------------------------BIGRAMS PROCESSING-----------------------------------------------------
# generate matrix of word pairs (2-grams)
bigrams <- generate_texts_ngrams(mixed, 2)
bigrams   <-   as.data.frame(bigrams, stringsAsFactors = FALSE); 
names(bigrams) <- c("token");
bigrams_df <- as.data.frame(stri_split_fixed(bigrams$token, " ", simplify=TRUE), stringsAsFactors = FALSE) 
names(bigrams_df) <- c("token1","token2")

# mark words to be ignored as <unk>
bigrams_df$token1[bigrams_df$token1 %in% skip_words] <- "<unk>"
bigrams_df$token2[bigrams_df$token2 %in% skip_words] <- "<unk>"

# remove bigrams with <unk>
bigrams_df <- subset(bigrams_df, token1 !=  "<unk>" & token2 !=  "<unk>")


# stem token1 in bigrams 
bigrams_df$token1 <- wordStem(bigrams_df$token1,"english")

# recalculate frequency group by stemmed token1
bigrams_df <- bigrams_df %>% group_by(token1, token2) %>% summarise(qty=n()) %>% arrange(token1, desc(qty))
bigrams_df <- as.data.frame(bigrams_df, stringsAsFactors = FALSE)

# remove stopwords from bigrams
bigrams_df <- bigrams_df %>% filter(!token1 %in% stwd$stopword & !token2 %in% stwd$stopword)
saveRDS(bigrams_df, "./Data/full/bigrams_df.rds")
#bigrams_df <- readRDS("./Data/full/bigrams_df.rds")

# leave only first stopword in the long compressed stopword (if any) in token2
# remove bigrams occured just once, and keep only up to 5 top pairs per each token1
bigrams_df <- bigrams_df %>%
    mutate(token2 = ifelse((substr(token2,1,1) == "Q"), substr(token2,1,3), token2)) %>% 
    group_by(token1, token2) %>% 
    summarise(qty=sum(qty)) %>% 
    arrange(token1, desc(qty)) %>% 
    filter(qty > 1) %>%
    filter(row_number() <= 5)

bigrams_df <- as.data.frame(bigrams_df, stringsAsFactors = FALSE)
saveRDS(bigrams_df, "./Data/full/bigrams_df_final5_red.rds")


#-----------------------------------TRIGRAMS PROCESSING----------------------------------------------------
# generate matrix of tri-grams
trigrams <- generate_texts_ngrams(mixed, 3)
trigrams  <-   as.data.frame(trigrams, stringsAsFactors = FALSE); 
names(trigrams) <- c("token")
trigrams_df <- as.data.frame(stri_split_fixed(trigrams$token, " ", simplify=TRUE), stringsAsFactors = FALSE) 
names(trigrams_df) <- c("token1","token2","token3")

# mark words to be skipped as <unk>
trigrams_df$token1[trigrams_df$token1 %in% skip_words] <- "<unk>"
trigrams_df$token2[trigrams_df$token2 %in% skip_words] <- "<unk>"
trigrams_df$token3[trigrams_df$token3 %in% skip_words] <- "<unk>"

# remove trigrams containing words to skip
trigrams_df <- subset(trigrams_df, token1 !=  "<unk>" & token2 !=  "<unk>" & token3 !=  "<unk>")

# step first two tokens in trigrams
trigrams_df$token1 <- wordStem(trigrams_df$token1,"english")
trigrams_df$token2 <- wordStem(trigrams_df$token2, "english")

# recalculate frequences after stemming and remove trigrams containing stopwords
trigrams_df <- trigrams_df %>% group_by(token1, token2, token3) %>% summarise(qty=n()) %>% arrange(token1, token2, desc(qty))
trigrams_df <- as.data.frame(trigrams_df, stringsAsFactors = FALSE)
trigrams_df <- subset(trigrams_df, !token1 %in% stwd$stopword & !token2 %in% stwd$stopword & !token3 %in% stwd$stopword)
saveRDS(trigrams_df, "./Data/full/trigrams_df.rds")
#trigrams_df <- readRDS("./Data/full/trigrams_df.rds")

# leave only first encoded stopword in the long encoded compressed stopword (if any) in token3 
# remove trigrams occured just once, and keep only up to 5 top combinations per each token1, token2

trigrams_df <- trigrams_df %>%
    mutate(token3 = ifelse((substr(token3,1,1) == "Q"), substr(token3,1,3), token3)) %>% 
    group_by(token1, token2, token3) %>% 
    summarise(qty=sum(qty)) %>% 
    filter(qty > 1) %>%
    arrange(token1, token2, desc(qty)) %>% 
    filter(row_number() <= 5)

trigrams_df  <-   as.data.frame(trigrams_df, stringsAsFactors = FALSE); 
saveRDS(trigrams_df, "./Data/full/trigrams_df_final5_red.rds")


#---------------------------------QUADGRAMS PROCESSING----------------------------------------------
# generate matrix of quad-grams
quadgrams <- generate_texts_ngrams(mixed, 4)
quadgrams  <-   as.data.frame(quadgrams, stringsAsFactors = FALSE); 
names(quadgrams) <- c("token")
quadgrams_df <- as.data.frame(stri_split_fixed(quadgrams$token, " ", simplify=TRUE), stringsAsFactors = FALSE) 
names(quadgrams_df) <- c("token1", "token2", "token3", "token4")

# mark tokens to be skipped and remove 4-grams with such tokens
quadgrams_df$token1[quadgrams_df$token1 %in% skip_words] <- "<unk>"
quadgrams_df$token2[quadgrams_df$token2 %in% skip_words] <- "<unk>"
quadgrams_df$token3[quadgrams_df$token3 %in% skip_words] <- "<unk>"
quadgrams_df <- subset(quadgrams_df, token1 !=  "<unk>" & token2 !=  "<unk>" & token3 !=  "<unk>")

# stem token1, token2, token3 of each 4-gram
quadgrams_df$token1 <- wordStem(quadgrams_df$token1, "english")
quadgrams_df$token2 <- wordStem(quadgrams_df$token2, "english")
quadgrams_df$token3 <- wordStem(quadgrams_df$token3, "english")

# re-calculate frequencies and remove 4-grams 
quadgrams_df <- quadgrams_df %>% group_by(token1, token2, token3, token4) %>% summarise(qty=n()) %>% arrange(token1, token2, token3, desc(qty))
quadgrams_df <- as.data.frame(quadgrams_df, stringsAsFactors = FALSE)
quadgrams_df <- subset(quadgrams_df, !token1 %in% stwd$stopword & !token2 %in% stwd$stopword & !token3 %in% stwd$stopword & !token4 %in% stwd$stopword)
saveRDS(quadgrams_df, "./Data/full/quadgrams_df.rds")
#quadgrams_df <- readRDS("./Data/full/quadgrams_df.rds")

# leave only first encoded stopword in the long encoded compressed stopword (if any) in token4 
# remove 4-grams occured just once, and keep only up to 5 top combinations per each token1, token2, token3

quadgrams_df <- quadgrams_df %>% 
    mutate(token4 = ifelse((substr(token4,1,1) == "Q"), substr(token4,1,3), token4)) %>% 
    group_by(token1, token2, token3, token4) %>% 
    summarise(qty=sum(qty)) %>% 
    filter(qty > 1) %>%
    arrange(token1, token2, token3, desc(qty))  %>% 
    filter(row_number() <= 5)

quadgrams_df <- as.data.frame(quadgrams_df, stringsAsFactors = TRUE)

saveRDS(quadgrams_df, "./Data/full/quadgrams_df_final5_red.rds")
rm(quadgrams)
