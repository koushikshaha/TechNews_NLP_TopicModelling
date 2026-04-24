# ---------------------------
# Install & Load Required Packages
# ---------------------------
packages <- c(
  "textstem", "rvest", "purrr", "dplyr", "stringr", "stringi","topicmodels",
  "tm", "SnowballC", "tidytext", "ggplot2", "wordcloud", "RColorBrewer"
)

installed <- packages %in% rownames(installed.packages())
if (any(!installed)) install.packages(packages[!installed])
lapply(packages, library, character.only = TRUE)
# ---------------------------
# Cleaning function
# ---------------------------
clean_text <- function(x) {
  x %>%
    iconv(from = "latin1", to = "UTF-8", sub = "") %>%
    stri_trans_general("latin-ascii") %>%
    str_to_lower() %>%
    str_replace_all("https?://\\S+", "") %>%
    str_replace_all("[[:punct:]]", " ") %>%
    str_replace_all("[\r\n]", " ") %>%
    str_replace_all("[^[:print:]]", " ") %>%
    str_squish()
}

# ---------------------------
# Function: Scrape one Verge archive page
# ---------------------------
get_verge_page <- function(page_num) {
  base_url <- "https://www.theverge.com"
  url <- paste0(base_url, "/tech/archives/", page_num)
  page <- tryCatch(read_html(url, encoding = "UTF-8"), error = function(e) NULL)
  if (is.null(page)) return(NULL)
  
  titles <- page %>%
    html_elements("div.hp1qhq3 :not(span) > a") %>%
    html_text2()
  links <- page %>%
    html_elements("div.hp1qhq3 :not(span) > a") %>%
    html_attr("href")
  dates <- page %>%
    html_elements("div.hp1qhq3 time") %>%
    html_attr("datetime")
  authors <- page %>%
    html_elements("div.hp1qhq3 span span span span") %>%
    html_text2()
  
  n <- min(length(titles), length(links), length(dates), length(authors))
  if (n == 0) return(NULL)
  
  tibble(
    Title = titles[1:n],
    Link = links[1:n],
    Date = dates[1:n],
    Author = authors[1:n]
  )
}

# ---------------------------
# Function: Scrape article text
# ---------------------------
get_article_text <- function(url) {
  tryCatch({
    page <- read_html(url, encoding = "UTF-8")
    paragraphs <- page %>%
      html_elements("div.duet--article--article-body-component p") %>%
      html_text2()
    clean_text(paste(paragraphs, collapse = " "))
  }, error = function(e) {
    return(NA)
  })
}

# ---------------------------
# Scrape archive pages (1–20)
# ---------------------------
page_range <- 1:30
results_list <- list()

for (i in page_range) {
  cat("Scraping page", i, "\n")
  tmp <- get_verge_page(i)
  if (!is.null(tmp)) results_list[[length(results_list) + 1]] <- tmp
}

result <- bind_rows(results_list)

# ---------------------------
# Clean and filter results
# ---------------------------
base_url <- "https://www.theverge.com"
results <- result %>%
  filter( 
    !is.na(Title), Title != "",
    !is.na(Link), Link != "",
    !is.na(Date), Date != "",
    !is.na(Author), Author != "",
    !str_detect(Link, "^#")
  ) %>%
  mutate(Link = if_else(str_detect(Link, "^https?://"), Link, str_c(base_url, Link))) %>%
  distinct(Link, .keep_all = TRUE) %>%
  filter(str_detect(Link, "^https?://([a-zA-Z0-9-]+\\.)?theverge\\.com"))

# Remove unwanted authors
results1 <- results %>%
  filter(Author != "and")

# Scrape article text
results1$ArticleText <- map_chr(results1$Link, possibly(get_article_text, NA_character_))

# Clean text fields
results1 <- results1 %>%
  mutate(
    Title = clean_text(Title),
    Author = clean_text(Author),
    ArticleText = clean_text(ArticleText)
  ) %>%
  filter(!is.na(ArticleText), ArticleText != "")

# ---------------------------
# Date cleaning
# ---------------------------
results1 <- results1 %>%
  mutate(Date_clean = suppressWarnings(as.Date(Date))) %>%
  filter(!is.na(Date_clean)) %>%
  mutate(Date = Date_clean) %>%
  select(-Date_clean)

# ---------------------------
# Tokenization
# ---------------------------

custom_stopwords <- c("ita", "verge", "tech", "said", "will","youa","ia", "thata","wea")

tokens <- results1 %>%
  select(Link, ArticleText) %>%
  unnest_tokens(word, ArticleText) %>%
  filter(!word %in% stop_words$word) %>%
  filter(!word %in% custom_stopwords) %>%
  filter(str_detect(word, "^[a-z]+$"))

# Lemmatization
tokens <- tokens %>%
  mutate(word = lemmatize_words(word))

# ---------------------------
# Word frequency analysis
# ---------------------------
word_freq <- tokens %>%
  count(word, sort = TRUE) %>%
  top_n(20, n)

# ---------------------------
# TF-IDF and Document-Term Matrix
# ---------------------------
dtm <- tokens %>%
  count(Link, word) %>%
  cast_dtm(document = Link, term = word, value = n)

tfidf <- tokens %>%
  count(Link, word) %>%
  bind_tf_idf(word, Link, n)

custom_word_freq <- tokens %>%
  count(word, sort = TRUE) %>%
  top_n(80, n)

# ---------------------------
# Save CSVs FIRST
# ---------------------------
write.csv(results1, "C:/Users/USER/Downloads/clean_news2.csv", row.names = FALSE)
write.csv(tfidf, "C:/Users/USER/Downloads/tfidf_verge.csv", row.names = FALSE)
write.csv(as.matrix(dtm), "C:/Users/USER/Downloads/dtm_verge.csv")

cat("Saved", nrow(results1), "records with article texts to clean_news2.csv\n")
cat("Saved TF-IDF data to tfidf_verge.csv\n")
cat("Saved DTM to dtm_verge.csv\n")

# ---------------------------
# Plots
# ---------------------------

# 1. Bar Chart of Top Words
bar_plot <- ggplot(word_freq, aes(x = reorder(word, n), y = n)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  coord_flip() +
  labs(title = "Top 20 Words in Verge Articles", x = "Word", y = "Frequency") +
  theme_minimal()
ggsave("word_freq_bar.png", bar_plot, width = 8, height = 6,bg = "white")

# 2. Word Cloud
png("wordcloud.png", width = 800, height = 600)
wordcloud(
  words = custom_word_freq$word,
  freq = custom_word_freq$n,
  min.freq = 2,
  max.words = 500,
  random.order = FALSE,
  colors = brewer.pal(8, "Dark2")
)
dev.off()

# 3. TF-IDF per Article
# ---------------------------
# TF-IDF per Article (Improved)
# ---------------------------

# Add short titles for readability
top_tfidf <- tfidf %>%
  group_by(Link) %>%
  slice_max(tf_idf, n = 5) %>%   # top 5 words per article
  ungroup() %>%
  left_join(results1 %>% select(Link, Title), by = "Link") %>%
  mutate(Title_short = str_trunc(Title, 40))   # shorten to 40 chars

# Option: reduce number of articles (optional, for readability)
# Here we show top ~12 articles (60 word entries total)
tfidf_sample <- top_tfidf %>%
  group_by(Title_short) %>%
  slice_max(tf_idf, n = 5) %>%
  ungroup() %>%
  slice_max(tf_idf, n = 60)


set.seed(123)  # for reproducibility
k <- 6  # number of topics
lda_model <- LDA(dtm, k = k, control = list(seed = 123))

lda_terms <- tidy(lda_model, matrix = "beta")      # word-topic probabilities
lda_docs  <- tidy(lda_model, matrix = "gamma")     # doc-topic probabilities


top_terms <- lda_terms %>%
  group_by(topic) %>%
  slice_max(beta, n = 10) %>%
  ungroup() %>%
  arrange(topic, -beta)

lda_terms_plot <- ggplot(top_terms,
                         aes(x = reorder_within(term, beta, topic),
                             y = beta, fill = factor(topic))) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~ topic, scales = "free") +
  scale_x_reordered() +
  coord_flip() +
  labs(title = "Top Terms per LDA Topic",
       x = "Term", y = "Beta (Probability)") +
  theme_minimal()

ggsave("lda_top_terms.png", lda_terms_plot,
       width = 12, height = 8, bg = "white")
cat("Saved lda_top_terms.png\n")


doc_topics <- lda_docs %>%
  group_by(document) %>%
  slice_max(gamma, n = 1) %>%  # main topic for each doc
  ungroup()

doc_topics_plot <- ggplot(doc_topics, aes(x = factor(topic))) +
  geom_bar(fill = "steelblue") +
  labs(title = "Most Common Topics Across Articles",
       x = "Topic", y = "Count of Articles") +
  theme_minimal()

ggsave("lda_doc_topics.png", doc_topics_plot,
       width = 8, height = 6, bg = "white")
cat("Saved lda_doc_topics.png\n")


for (i in 1:k)
{ terms_topic <- lda_terms %>%
    filter(topic == i) %>%
  arrange(desc(beta)) 
png(paste0("lda_wordcloud_topic_", i, ".png"), 800, 600)
wordcloud( words = terms_topic$term, 
           freq = terms_topic$beta, 
           max.words = 100, 
           colors = brewer.pal(8, "Dark2"), 
           random.order = FALSE ) 
          dev.off() 
          cat("Saved lda_wordcloud_topic_", i, ".png\n") 
          }



# 4. Trend of Articles Over Time
trend_data <- results1 %>%
  count(Date)

trend_plot <- ggplot(trend_data, aes(x = Date, y = n)) +
  geom_line(color = "blue") +
  geom_point() +
  labs(title = "Trend of Articles Over Time", x = "Date", y = "Number of Articles") +
  theme_minimal()
ggsave("trend_over_time.png", trend_plot, width = 8, height = 6,bg = "white")

cat("Saved all plots: word_freq_bar.png, wordcloud.png, tfidf_per_article.png, trend_over_time.png\n")