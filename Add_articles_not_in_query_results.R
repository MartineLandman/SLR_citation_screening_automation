## Written in R version 4.2.0
library(easyPubMed)
library(readr)
library(stringr)
library(genTS)
library(dplyr)
library(tidyr)
my_api_key = "..." # see README file
df_all_articles <- read.table("....csv") # end result from Queries.R
df_all_pmid <- read.table ("....csv") # intermediate result from Recreation_dataset.R
all_pub_types <- as.list(read_lines("all_pub_types.txt")) # provided in GitHub repository

## Retrieve all PMIDs that were in the EndNote Library but not in the query results
df_not_in_queries = data.frame()
for (row in 1:nrow(df_all_pmid)){
  if (df_all_pmid[row, 1] %in% df_all_articles[,1] == FALSE)
  {df_not_in_queries <- rbind(df_not_in_queries, (df_all_pmid[row, 1]))}}
colnames(df_not_in_queries) <- 'pmid'

## Retrieve title and abstract of these PMIDs
## Here we are retrieving PMIDs by filling in PMIDs as a query
## this seems strange, but is necessary because the fetch_pubmed_data function
## requires the result of a get_pubmed_ids call as an input, which is actually
## not just a list of PMIDs, but contains additional information

for (row in 1:nrow(df_not_in_queries)){
  # creating df with title and abstract of article
  pmid_info <- get_pubmed_ids(df_not_in_queries[row,1], api_key = my_api_key) 
  tiabs_xml <- fetch_pubmed_data(pmid_info, retstart = 0, retmax = 500, format = "xml",
                                 encoding = "UTF8") ## title and abstract
  next_article_tiabs <- article_to_df(tiabs_xml, autofill = FALSE,
                                      max_chars = -1, getKeywords = TRUE,
                                      getAuthors = FALSE)
  df_not_in_queries[row,2] <- next_article_tiabs[1,3] # Fill in title
  df_not_in_queries[row,3] <- next_article_tiabs[1,4] # Fill in abstract
  ## Filling in pubtypes and storing medline data
  df_not_in_queries[row,7] <- toString((fetch_pubmed_data(pmid_info, retstart = 0, retmax = 500, format = "medline",
                                   encoding = "UTF8"))) ## pubtype and mesh terms
  pt_one_article <- c()
  for (pt in all_pub_types){ #Find publication types
    if (grepl(pt, df_not_in_queries[row,7])){
      pt <- str_replace_all(pt, ',', ';')
      pt_one_article <- toString(append(pt_one_article, pt))#Make a string of all pubtypes of an article
      df_not_in_queries[row,5] <- pt_one_article}}}
  
df_not_in_queries2 <- df_not_in_queries %>% 
  mutate(mesh = str_extract_all(medline_info, "MH  - .*")) %>% ## Extract MeSH
  ## Work-around to replace "," INSIDE MesH terms (e.g. Diet, Mediterranean) with ";" 
  ## in order to distinguish from comma's IN BETWEEN MeSH terms:
  mutate(mesh = str_replace_all(mesh, ", MH", "###")) %>%
  mutate(mesh = str_replace_all(mesh, "," , ";" )) %>%
  mutate(mesh = str_replace_all(mesh, "###", ", MH" )) %>%
  mutate(mesh = str_remove(mesh, "; EDAT.*")) %>% #Remove everything after MeSH terms
  mutate(mesh = str_remove_all(mesh, "MH  - " ))  %>% #Remove "MH - "
  mutate(mesh = str_remove_all(mesh, "[*\n\"]")) #Remove *, \n and "

## In the file, MeSH terms are formatted like Hypertension/etiology/mortality
## which needs to be Hypertension:etiology and Hypertension:mortality
for (row in 1:nrow(df_not_in_queries2)){
  mesh_right_format = ""
  mesh_terms = str_split_1(df_not_in_queries2[row,4], ",")
  for (mesh_term in mesh_terms){
    if (str_count((mesh_term), "/") > 1){
      sep_word <- str_split_1(mesh_term, "/")
      for (word in 2:length(sep_word)){
        new_combi = paste(sep_word[1], sep_word[word], sep='/')
        mesh_right_format <- paste(mesh_right_format, new_combi, sep =',')}}
    else {mesh_right_format <- paste(mesh_right_format, mesh_term, sep =',')}
  } 
  df_not_in_queries2[row,4] <- str_sub(mesh_right_format,2,-1)}
df_not_in_queries2 <- df_not_in_queries2[,1:6]


## Adding these articles to the df with query results
df_query_results <- read.table("....csv", header = TRUE)
final_dataset_extended <- rbind(df_query_results, df_not_in_queries2)
final_dataset_extended <- final_dataset_extended %>%
  drop_na(abstract) # drop articles without available abstract
write.csv(final_dataset_extended,".all_queries_extended.csv", row.names = FALSE)

