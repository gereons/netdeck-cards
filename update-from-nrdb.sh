#!/bin/bash

CARDS_URL=https://netrunnerdb.com/api/2.0/public/cards
CYCLES_URL=https://netrunnerdb.com/api/2.0/public/cycles
PACKS_URL=https://netrunnerdb.com/api/2.0/public/packs
MWL_URL=https://netrunnerdb.com/api/2.0/public/mwl
ROTATIONS_URL=https://raw.githubusercontent.com/NetrunnerDB/netrunner-cards-json/main/rotations.json
LOCALE=""
SUFFIX=""

mkdir -p api/2.0

curl -s $CARDS_URL -o api/2.0/cards_en.json
echo -n "."
curl -s $CYCLES_URL -o api/2.0/cycles_en.json
echo -n "."
curl -s $PACKS_URL -o api/2.0/packs_en.json
echo -n "."
curl -s $MWL_URL -o api/2.0/mwl.json
echo -n "."
curl -s $ROTATIONS_URL -o api/2.0/rotations-2.json
echo "."

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
    echo "don't forget to test and merge to main"
fi
