#!/bin/bash

SERVER=http://localhost:8000
CARDS_URL=$SERVER/api/2.0/public/cards
CYCLES_URL=$SERVER/api/2.0/public/cycles
PACKS_URL=$SERVER/api/2.0/public/packs
LOCALE=""
SUFFIX=""

mkdir -p api/2.0
rm -rf tmp
mkdir tmp

curl -s $CARDS_URL -o tmp/cards.raw
curl -s $CYCLES_URL -o tmp/cycles.raw
curl -s $PACKS_URL -o tmp/packs.raw

for raw in tmp/*.raw
do
    cat $raw |
    sed 's/},/},\
/g' |
    sed 's/\([^\\]\)",/\1",\
/g' |
    sed 's/http:\/\/localhost:8000/https:\/\/netrunnerdb.com/' >$raw.2
done

for language in en de fr es pl kr jp zh
do
    SUFFIX="_$language"

    cp tmp/cards.raw.2 api/2.0/cards$SUFFIX.json
    cp tmp/cycles.raw.2 api/2.0/cycles$SUFFIX.json
    cp tmp/packs.raw.2 api/2.0/packs$SUFFIX.json
done

rm -r tmp

if git diff --quiet --exit-code
then
    echo no updates found
else
    git checkout test
    echo updates found, committing
    git add api/2.0/*
    DATE=$(date +%Y-%m-%d)
    git commit -m "update $DATE"
    git push
    git status
    echo "don't forget to test and merge to master"
fi
