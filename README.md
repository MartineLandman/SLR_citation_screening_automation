These scripts were written for an MSc thesis on automated citation screening (= title and abstract screening) for an updated systematic literature review (SLR) for diabetes nutrition guidelines, due in 2025. We applied machine learning models (linear Support Vector Machines and complement Naive Bayes classifiers) to classify articles as relevant or irrelevant.To train the models, we had to recreate the dataset of the original SLR from 2020. We did this by using the original queries to recreate the entire dataset that was manually screened in 2020 and we used the articles from an EndNote library (that contained all articles that were included in the SLR) to label the relevant/included articles in the dataset. This was all done in R and the machine learning pipeline was written in Python. This includes the steps of natural language preprocessing, translating the articles to numerical vectors, feature selection, resampling and applying the models. 

Contents:

- Data cleaning performed in R version 4.2.0:
  (These scripts require an API key. This can be requested through an NCBI account at the bottom of the 'Account Settings' page, at 'API Key management')
   * Queries.R: Script used to obtain articles that are in query results and combine into one dataframe (result can be loaded into Recreation_dataset.R)
  * Recreation_dataset.R:  Contains the steps (1) load in dataset from Queries.R (2) retrieval of relevant articles from EndNote library and (3) combining these dataframes.
    The result is a dataframe with the PMID, title, abstract, publication type, MeSH terms and relevance (0 or 1) of each article from the query results.
    (To create EndNote Library file: Go to your EndNote library -> Ctrl + A to select all articles -> File -> Export -> save as .txt file with output style 'Show All Fields')
  * Add_articles_not_in_query_results.R:  Due to suboptimal reproduction of the queries, not all relevant articles from the EndNote library were in Query_results.R. This script is used to retrieve these remaining relevant articles and add it to the result of Recreation_dataset.R in order to increase the amount of training data for relevant articles.

- Machine learning pipeline applied in Python version 3.9:
  * NLP.py:  Applies natural language processing steps (tokenization, stopword removal, etc.) to the result of the data cleaning in R
  * BOW.py: Changes the result of NLP.py to a bag-of-words representation, where each word (from title, abstract, publication type and MeSH terms) is a column. For each word from the title and abstract, each article has a count of how many times the word appears. Publication type and MeSH terms are binary variables.
  * TFIDF.py: Changes the result of BOW.py to a term-frequency inverse-document-frequency representation. Here, the number of occurrences of a word from the title or abstract (=BOW) is set off against the number of articles this word appears in.
  * Word2Vec.py: Changes the result of NLP.py and BOW.py into a Word2Vec representation. Publication types and MeSH terms remain binary as in the BOW, but the words from the title and abstract are translated to an vector representation in an n-dimensional vector-space.
  * Feature_selection.py: N features are selected based on document frequency (number of documents containing word) and the chi-square test (dependence of outcome on feature)
  * Resampling.py: Class dictribution of dataset is changed through application of random undersampling (RUS) (randomly discarding instances from majority class), random oversampling (ROS) (random copying of instances from minority class), synthetic minority oversampling technique (SMOTE) (randomly creating synthetic, plausible instances of the minority class) and a combination of RUS and SMOTE
  * ML_Pipeline.py: Entire pipelines for both cNB and SVM models. First a dataframe is created for the cNB models with all combinations of different vectors, settings for the smoothing parameter, feature selection methods and numbers of features (in our case resulting in 250 possible models/rows). Another function will then execute each row of this dataframe and save the results in terms of recall, precision, F1-score and WSS@95. A similar type of dataframe is created for SVM where all combinations of different vectors, feature selection methods, numbers of features, resampling methods and resampling ratios are stored (in our case resulting in 1224 possible models/rows). These rows are then also executed in another function, where additionally a grid search is performed each time to find the optimal value for hyperparameter C. Again, the results of the models are stored in a dataframe. 
