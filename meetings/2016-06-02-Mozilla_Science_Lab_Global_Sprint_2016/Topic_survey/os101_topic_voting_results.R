#!/usr/bin/Rscript --vanilla
### os101_topic_voting_results.R v0.1 08-06-2016
### Andreas Leimbach @aleimba

### R version 3.2.5
### ggplot2 v2.1.0

library(ggplot2)
data <- read.delim("OS101_topic_voting_2016-06-07.tsv", check.names = FALSE) # read into data.frame
data <- data[,c("Topic", "Votes")] # get only subset columns
data <- data[data$Topic != "Total voters",] # remove unwanted row
data <- data[data$Topic != "Other topic suggestions",] # remove unwanted rows

png("OS101_topic_voting_2016-06-07.png", width = 800, height = 628) # output PNG

ggplot(data, aes(x=reorder(Topic, -Votes), y=Votes)) + # keep order of input data.frame
  geom_bar(stat="identity", fill="lightgreen", colour="black") +
  geom_text(aes(label=Votes), hjust=1.5, colour="black", size = 6) + # include labels to bars
  theme(text = element_text(size=20)) + # increase text size
  ggtitle("Total voters = 52") +
  coord_flip() # flip chart

mute <- dev.off()
