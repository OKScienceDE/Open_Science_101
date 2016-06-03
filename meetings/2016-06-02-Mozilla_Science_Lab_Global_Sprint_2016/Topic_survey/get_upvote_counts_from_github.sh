#!/bin/bash

# Requirements: curl, perl, jq, datamash

# GITHUB_API_AUTH should have the following format: "-u username:apikey"
# for example "-u myname:825s71e57a8aa011e1133c513c0546fb7ef22fc4"
# if you leave it blank you are rate limited to 60 requests per hour which might not be enough.
GITHUB_API_AUTH=""

# As the reactions api we have to specify the specific preview header
GITHUB_ACCEPT_HEADER="Accept: application/vnd.github.squirrel-girl-preview"

# get all the upvotes (and titles) for each issue
curl $GITHUB_API_AUTH "https://api.github.com/repos/OKScienceDE/Open_Science_101/issues?per_page=100" -H "$GITHUB_ACCEPT_HEADER" | jq '.[] | .url, .title, .reactions."+1"' | perl -pe 's/"\n/"\t/' >survey_github_issues.tsv

# get all the upvotes for comments of each issue
(for i in $(cat survey_github_issues.tsv | cut -f1 | rev | cut -f1 -d"/" | cut -c 2- | rev)
do
    curl $GITHUB_API_AUTH "https://api.github.com/repos/OKScienceDE/Open_Science_101/issues/$i/comments?per_page=100" -H "$GITHUB_ACCEPT_HEADER" | jq '.[] | .issue_url, .reactions."+1"'
done) | perl -pe 's/"\n/"\t/' >survey_github_comments.tsv

# sum up the upvotes for comments on the same issue
cat survey_github_comments.tsv | sort | datamash -g1 sum 2 >survey_github_comments.sum.tsv

# join the upvotes for issues and comments
# due to a bug in join -e might not work and you get an empty value instead of 0 if an issue has no comments at all
join <(sort survey_github_issues.tsv) <(sort survey_github_comments.sum.tsv) -a 1 -e 0 -t $'\t' | tee survey_github.tsv
