#!/usr/bin/env bash
#
# Copyright Docube System. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_BLUE='\033[0;34m'
C_YELLOW='\033[1;33m'

# Print the usage message
function printHelp() {
  USAGE="$1"
  if [ "$USAGE" == "up" ]; then
    println "Usage: "
    println "  network.sh up [Flags]"
    println
    println "    Flags:"
    println "    -verbose - Verbose mode"
    println
    println " Examples:"
    println "   network.sh up"
  elif [ "$USAGE" == "createChannel" ]; then
    println "Usage: "
    println "  network.sh createChannel [Flags]"
    println
    println "    Flags:"
    println "    -c <channel name> - Name of channel to create (defaults to \"docubechannel\")"
    println "    -verbose - Verbose mode"
    println
    println " Examples:"
    println "   network.sh createChannel"
    println "   network.sh createChannel -c docubechannel"
  elif [ "$USAGE" == "down" ]; then
    println "Usage: "
    println "  network.sh down"
    println
    println " Examples:"
    println "   network.sh down"
  else
    println "Usage: "
    println "  network.sh <Mode> [Flags]"
    println "    Modes:"
    println "      up - Bring up Docube network"
    println "      down - Bring down the network"
    println "      createChannel - Create and join a channel"
    println
    println "    Flags:"
    println "    -h - Print this message"
    println "    -c <channel name> - Name of channel (defaults to 'docubechannel')"
    println "    -verbose - Verbose mode"
    println
    println " Examples:"
    println "   network.sh up"
    println "   network.sh createChannel -c docubechannel"
    println "   network.sh down"
  fi
}

# println echos string
function println() {
  echo -e "$1"
}

# errorln echos i red color
function errorln() {
  println "${C_RED}${1}${C_RESET}"
}

# successln echos in green color
function successln() {
  println "${C_GREEN}${1}${C_RESET}"
}

# infoln echos in blue color
function infoln() {
  println "${C_BLUE}${1}${C_RESET}"
}

# warnln echos in yellow color
function warnln() {
  println "${C_YELLOW}${1}${C_RESET}"
}

# fatalln echos in red color and exits with fail status
function fatalln() {
  errorln "$1"
  exit 1
}

export -f errorln
export -f successln
export -f infoln
export -f warnln
export -f fatalln
