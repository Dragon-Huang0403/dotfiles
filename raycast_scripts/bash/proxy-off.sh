#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Proxy Off
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🤖

networksetup -setwebproxystate "Wi-Fi" off
networksetup -setsecurewebproxystate "Wi-Fi" off

