#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
test_binary=$(mktemp /tmp/notlooking-motion.XXXXXX)
trap 'rm -f "$test_binary"' EXIT
swiftc NotLooking/Motion/*.swift NotLooking/Actions/*.swift NotLooking/Overlay/*.swift NotLooking/Exercise/NeckExercise.swift NotLooking/UI/L10n.swift Tests/Motion/main.swift -o "$test_binary"
"$test_binary"
