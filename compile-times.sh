#!/bin/bash

xcodebuild -workspace NetDeck.xcworkspace -scheme NetDeck clean build OTHER_SWIFT_FLAGS="-Xfrontend -debug-time-function-bodies" | grep .[0-9]ms | grep -v ^0.[0-9]ms | sort -nr > culprits.txt
