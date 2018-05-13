#!/bin/sh
PID=$(ps -ef  | grep chromium | awk '{print $2}' | head -n 1)
kill -1 $PID
