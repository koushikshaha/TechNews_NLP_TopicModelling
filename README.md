# The Verge Tech News — Text Mining & Topic Modelling
### Group 01 | R Language | NLP & Web Scraping

---

## Project Overview

This project performs end-to-end **text mining and topic modelling** on technology news articles scraped live from [The Verge](https://www.theverge.com). The pipeline covers web scraping, text cleaning, tokenization, lemmatization, TF-IDF weighting, and **Latent Dirichlet Allocation (LDA)** to uncover hidden themes and trends in tech journalism.

---

## Repository Structure

```
TechNews_NLP_TopicModelling/
│
├── TechNews_NLP_TopicModelling.R          # Main R script (scraping + NLP)
├── TechNews_NLP_TopicModelling.Rmd        # R Markdown report
├── TechNews_NLP_TopicModelling.html       # Rendered HTML report
│
├── outputs/
│   ├── clean_news2.csv          # Cleaned scraped articles
│   ├── tfidf_verge.csv          # TF-IDF scores
│   ├── dtm_verge.csv            # Document-Term Matrix
│   ├── word_freq_bar.png        # Top 20 words bar chart
│   ├── wordcloud.png            # Word cloud
│   ├── lda_top_terms.png        # LDA top terms per topic
│   ├── lda_doc_topics.png       # Topic distribution
│   └── lda_wordcloud_topic_*.png
│
├── .gitignore
└── README.md
```

---

## Data Source

| Field | Details |
|---|---|
| Source | The Verge — theverge.com/tech/archives |
| Pages Scraped | 30 archive pages |
| Fields | Title, Link, Date, Author, ArticleText |
| Processing | Cleaned, tokenized, lemmatized |
| Output | clean_news2.csv, tfidf_verge.csv, dtm_verge.csv |

---

## Libraries Used

| Package | Purpose |
|---|---|
| `rvest` | Web scraping |
| `purrr` | Functional programming over article links |
| `dplyr` | Data manipulation |
| `stringr` / `stringi` | String cleaning and encoding |
| `tidytext` | Tokenization, stop words, TF-IDF |
| `textstem` | Lemmatization |
| `tm` / `SnowballC` | Text mining, DTM construction |
| `topicmodels` | LDA topic modelling |
| `ggplot2` | Visualisations |
| `wordcloud` | Word cloud generation |
| `RColorBrewer` | Color palettes |

---

## How to Run

### Prerequisites
- R version 4.0 or higher
- RStudio (recommended)
- Active internet connection

### Step 1 — Clone the Repository
```bash
git clone https://github.com/yourusername/TechNews_NLP_TopicModelling_G01.git
cd TechNews_NLP_TopicModelling_G01
```

### Step 2 — Install Packages
```r
install.packages(c("textstem", "rvest", "purrr", "dplyr", "stringr", "stringi",
                   "topicmodels", "tm", "SnowballC", "tidytext", "ggplot2",
                   "wordcloud", "RColorBrewer", "rmarkdown", "knitr"))
```

### Step 3 — Run
**Option A — Plain R script:**
```r
source('G01_final_project.R')
```

**Option B — Knit to HTML report:**
```
Open G01_final_project.Rmd in RStudio → Click Knit (Ctrl+Shift+K)
```

---

## Analysis Pipeline

| Step | Description |
|---|---|
| 1. Web Scraping | Scrapes 30 pages of The Verge tech archive |
| 2. Article Text | Fetches full body text from each article URL |
| 3. Text Cleaning | Encoding fix, lowercase, remove URLs & punctuation |
| 4. Date Cleaning | Parses ISO dates, removes invalid rows |
| 5. Tokenization | Splits text into individual words |
| 6. Stop Word Removal | Removes common + custom stop words |
| 7. Lemmatization | Reduces words to base form |
| 8. Word Frequency | Top words — bar chart and word cloud |
| 9. TF-IDF | Distinctive words per article |
| 10. DTM | Document-Term Matrix for LDA input |
| 11. LDA | 6-topic model — word clouds + bar charts |
| 12. Trend Analysis | Articles published per day over time |

---

## Output Files

| File | Description |
|---|---|
| `clean_news2.csv` | All scraped and cleaned articles |
| `tfidf_verge.csv` | TF-IDF scores per word per article |
| `dtm_verge.csv` | Full Document-Term Matrix |
| `word_freq_bar.png` | Top 20 words bar chart |
| `wordcloud.png` | Word cloud of top 80 words |
| `lda_top_terms.png` | Top terms per LDA topic |
| `lda_doc_topics.png` | Articles per topic distribution |
| `lda_wordcloud_topic_1-6.png` | Word cloud per LDA topic |
| `trend_over_time.png` | Publication trend over time |

---

## Notes

- **Live scraping** — results may vary based on The Verge website changes or network availability
- **Scraping time** — fetching 30 pages + all article texts takes approximately 10–20 minutes
- **Reproducibility** — LDA uses `set.seed(123)` for consistent results
- **Output paths** — CSVs save to working directory by default; update paths as needed

---

## .gitignore

```
.Rhistory
.RData
.Rproj.user/
*.Rproj
```

---



*Data sourced from The Verge (theverge.com) for academic purposes only.*
