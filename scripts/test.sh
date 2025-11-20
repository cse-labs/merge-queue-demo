#!/bin/bash

set -euo pipefail

MODE="${1:-pass}"

echo "Running POC Test in mode: $MODE"

case $MODE in
fail)
  echo "Simulating failure..."
  exit 1
  ;;
flaky)
  # Simple 50/50 chance
  if ((RANDOM % 2)); then
    echo "Simulating flaky failure..."
    exit 1
  else
    echo "Simulating flaky success..."
    exit 0
  fi
  ;;
sleep)
  DURATION="${2:-30}"
  echo "Sleeping for $DURATION seconds..."
  sleep "$DURATION"
  echo "Woke up!"
  exit 0
  ;;
*)
  echo "Test passed!"
  exit 0
  ;;
esac
