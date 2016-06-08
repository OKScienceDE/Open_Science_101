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

# Further to get a list of users that voted up you can do the following:
# clear files if they exist from previous runs
echo -n "">issue_upvotes_users
echo -n "">comments_with_upvotes
echo -n "">comment_upvotes_users
for i in $(grep Include survey_github_issues.tsv | cut -f1 | rev | cut -f1 -d"/" | cut -c 2- | rev | grep -vwP "1|41")
do
    # Get a list of users that voted for this issue
    curl $GITHUB_API_AUTH "https://api.github.com/repos/OKScienceDE/Open_Science_101/issues/$i/reactions?per_page=100&content=+1" -H "$GITHUB_ACCEPT_HEADER" | jq ".[] | .user.login " >>issue_upvotes_users
    # Now get a list of comments with upvotes for this issue
    curl $GITHUB_API_AUTH "https://api.github.com/repos/OKScienceDE/Open_Science_101/issues/$i/comments?per_page=100" -H "$GITHUB_ACCEPT_HEADER" | jq '.[] | if .reactions."+1" > 0 then .id else null end' | grep -v "^null$" >>comments_with_upvotes
done
for i in $(cat comments_with_upvotes)
do
    # Get a list of users that voted for each of the comments
    curl $GITHUB_API_AUTH "https://api.github.com/repos/OKScienceDE/Open_Science_101/issues/comments/$i/reactions?per_page=100&content=+1" -H "$GITHUB_ACCEPT_HEADER" | jq ".[] | .user.login " >>comment_upvotes_users
done
cat issue_upvotes_users comment_upvotes_users | sort | uniq -c | tee github_voters
