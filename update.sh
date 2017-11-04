#!/bin/bash

CARDS_URL=https://netrunnerdb.com/api/2.0/public/cards
CYCLES_URL=https://netrunnerdb.com/api/2.0/public/cycles
PACKS_URL=https://netrunnerdb.com/api/2.0/public/packs
LOCALE=""
SUFFIX=""

mkdir -p api/2.0

for language in en de fr es pl kr jp zh
do
    if [ $language != "en" ]
    then
        LOCALE="?_locale=$language" 
    fi
    SUFFIX="_$language"

    curl $CARDS_URL$LOCALE -o api/2.0/cards$SUFFIX.json
    curl $CYCLES_URL$LOCALE -o api/2.0/cycles$SUFFIX.json
    curl $PACKS_URL$LOCALE -o api/2.0/packs$SUFFIX.json
done

if git diff --quiet --exit-code
then
    echo no updates found
else
    echo updates found, committing
    git add api/2.0/*
    DATE=$(date +%Y-%m-%d)
    git commit -m "update $DATE"
    git push
fi
