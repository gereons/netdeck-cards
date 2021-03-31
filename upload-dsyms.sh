#!/bin/bash

AUTH_TOKEN="09729dbda2ef47528360a1c9db427042c009dec170814bfe9e2d38cd28fee5f1"

sentry-cli --auth-token $AUTH_TOKEN upload-dif --org steffens --project netdeck $1 --

