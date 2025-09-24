#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Proxy On 8100
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🤖

networksetup -setwebproxy "Wi-Fi" 127.0.0.1 8100
networksetup -setsecurewebproxy "Wi-Fi" 127.0.0.1 8100

