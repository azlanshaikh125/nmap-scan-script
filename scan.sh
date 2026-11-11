#!/bin/bash
# Simple Nmap scan automation
# Use only on your own machines or authorized labs (e.g. TryHackMe)

if [ -z "$1" ]; then
  echo "Usage: ./scan.sh <target-ip>"
  exit 1
fi

TARGET=$1
OUTFILE="scan_$(echo $TARGET | tr '.' '_')_$(date +%Y%m%d_%H%M%S).txt"

echo "Scanning $TARGET ..."
nmap -sV -sC -T4 "$TARGET" -oN "$OUTFILE"

echo "Done. Results saved to $OUTFILE"
