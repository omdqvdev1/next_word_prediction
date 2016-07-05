---
title: "Building prediction model"

---

---

### Model construction process workflow

![Model construction workflow](../../figures/model_workflow_shp.png)

#### Cleaning the original text 

The original data set has been cleaned from numbers, hashatags, profanity words, and any reference to internet resources.
Punctuation symbols have been removed. Also, words like "dont", "cant", "werent", ect. have been corrected by imputing missing quote.
That improved quality of text model and, finally, prediction quality. All words were converted to lower case.
Also, text has been split on separate sentences.

#### Trainig data
For the training of the prediction data model whole data files have been used.


#### Construction of the model

In order to be able to predict next word, we need to know as much as possible information about the context, i.e. previous words and frequency of their appearance in the text before the predicted word. For this model, we collected words, word pairs, word triples, and word quads, or, 1-grams, 2-grams, 3-grams and 4-grams, ever appeared in a row in the sentences under consideration.
For each of n-grams, its frequency has been calculated. 

After that, stemming of all tokens in the 2-3-4-grams, except the last token, i.e. (token1 in 2-grams; token1, token2 in 3-grams, etc.), has been done, and the n-grams have been re-aggregated to summairise frequences for all tokens related to the same stemmed token.

#### Stop-words compression
In order to include as much as possible information in the n-grams and, at the same time, reduce the data model,
author implemented __encoding and compression__ of stopwords.
The __encoding and compression__ means that any combination of stopwords occured in the text, in a row one by one, is encoded and merged together in such a way that it would be considered as one artificial word in the data model. Such an approach allowed to always have at least one non-stopword in each of 2,3,4-grams.

For example, in the text, "You know, I've been there long time ago", stopword "you" and the combination of stopwords "I've been there" are compressed into tokens where each stopword is encoded in hex format preceded by the separator: So, for the split on n-grams, we will have the following text: "Q09 know Q41Q2cQ96 long time ago".

#### Reduction of n-grams
The list of words (1-grams) was filtered by removing non-english words or any words occured in the text files than 20 times. It means, that even non-english words can occur in our vocabulary but only in case they occur 20 times or more. All other n-grams contain the words from this vocabulary only. Also, all bigrams, tri-grams and quadgrams occured less than 5 times and and all trigrams occured less than 2 times were removed from the model, thus allowing to substantially reduce the size taken by the model in memory.


#### Treatment of encoded and compressed stopwords
After the prediction, all encoded predicted output is decoded back and is shown on the screen as natuarl text.

---

#### Characteristics of the model


|N-grams |    # of|  Volume|
|:-------|-------:|-------:|
|1-gram  |  190416| 12.3 Mb|
|2-gram  |  334932| 13.2 Mb|
|3-grams | 1489416| 50.8 Mb|
|4-grams |  220108| 10.3 Mb|
|Total   |        | 86.5 Mb|

----

Average prediction time is 0.14 sec, which is accepatble when typing the text on mobile device.

Total size of n-gram files deployed is 15.56 MB

Size of the model when deployed in operational memory is about 86.5 Mb, which is not too large for the contemporary devices.

---


